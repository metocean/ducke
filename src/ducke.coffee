Modem = require('ducke-modem').API
tardir = require './tardir'
groupimages = require './groupimages'
stream = require 'stream'
fs = require 'fs'

parallel = (tasks, callback) ->
  count = tasks.length
  result = (cb) ->
    return cb() if count is 0
    for task in tasks
      task ->
        count--
        cb() if count is 0
  result(callback) if callback?
  result

module.exports = class Ducke
  constructor: (options) ->
    @modem = new Modem options
  
  ping: (callback) =>
    @modem
      .get '/_ping'
      .result (err, result) ->
        return callback err if err?
        callback null, result is 'OK'
  
  ps: (callback)  =>
    @modem
      .get '/containers/json?all=1'
      .result (err, containers) =>
        return callback err if err?
        statuses = []
        errors = []
        tasks = []
        for container in containers
          do (container) =>
            tasks.push (cb) =>
              @modem
                .get "/containers/#{container.Id}/json"
                .result (err, inspect) =>
                  if err?
                    errors.push err
                    return cb()
                  statuses.push
                    container: container
                    inspect: inspect
                  cb()
        parallel tasks, =>
          statuses.sort (a, b) ->
            a = a.container.Names[0]
            b = b.container.Names[0]
            return 1 if a > b
            return -1 if a < b
            0
          
          return callback errors, statuses if errors.length > 0
          callback null, statuses
  
  ls: (callback)  =>
    @modem
      .get '/images/json?all=1'
      .result (err, images) =>
        return callback err if err?
        callback null, groupimages images
  
  lls: (images, callback)  =>
    errors = []
    results = {}
    tasks = []
    for id in images
      do (id) =>
        tasks.push (cb) =>
          @image id
            .inspect (err, result) ->
              if err?
                errors.push err
                return cb()
              results[result.Id] = result
              cb()
    parallel tasks, ->
      if errors.length > 0
        return callback errors, results
      callback null, results
  
  createContainer: (name, params, callback) =>
    url = '/containers/create'
    url += "?name=#{name}" if name?
    @modem
      .post url, params
      .result callback
  
  container: (id) =>
    inspect: (callback) =>
      @modem
        .get "/containers/#{id}/json"
        .result callback
      @container id
    
    logs: (callback) =>
      @modem
        .get "/containers/#{id}/logs?stderr=1&stdout=1&follow=1&tail=10"
        .stream callback
      @container id
    
    resize: (rows, columns, callback) =>
      @modem
        .post "/containers/#{id}/resize?h=#{rows}&w=#{columns}"
        .result (err, result) =>
          return callback err if err?
          callback null, result is 'OK'
      @container id
    
    start: (callback) =>
      @modem
        .post "/containers/#{id}/start", {}
        .result callback
      @container id
    
    stop: (callback) =>
      @modem
        .post "/containers/#{id}/stop?t=5", {}
        .result callback
      @container id
    
    wait: (callback) =>
      @modem
        .post "/containers/#{id}/wait", {}
        .result callback
      @container id
    
    rm: (callback) =>
      @modem
        .delete "/containers/#{id}"
        .result callback
      @container id
    
    attach: (callback) =>
      @modem
        .post "/containers/#{id}/attach?stream=true&stdin=true&stdout=true&stderr=true", {}
        .connect callback
      @container id
    
    kill: (callback) =>
      @modem
        .post "/containers/#{id}/kill?signal=SIGTERM", {}
        .result callback
      @container id
    
    exec: (cmd, stdin, stdout, stderr, callback) =>
      params =
        AttachStdin: yes
        AttachStdout: yes
        AttachStderr: yes
        Tty: yes
        Cmd: cmd
      
      @modem
        .post "/containers/#{id}/exec", params
        .result (err, exec) =>
          return callback err if err?
          
          @modem
            .post "/exec/#{exec.Id}/start", { Detach: no, Tty: yes }
            .connect  (err, stream) =>
              return callback err if err?
              
              stream.setEncoding 'utf8'
              stream.pipe stdout
              stdin.resume()
              stdin.setEncoding 'utf8'
              if stdin.setRawMode?
                stdin.setRawMode yes
              stdin.pipe stream
              
              updatesize = =>
                @modem
                  .post "/exec/#{exec.Id}/resize?h=#{stdout.rows}&w=#{stdout.columns}", {}
                  .result (err, r) ->
                    console.error err if err?
              stdout.on 'resize', updatesize
              updatesize() if stdout.rows?
              
              stream.on 'end', ->
                stdin.removeAllListeners()
                if stdin.setRawMode?
                  stdin.setRawMode wasRaw
                stdin.resume()
                stdout.removeListener 'resize', updatesize
                callback null, 0
      @container id
  
  build_image: (id, path, usecache, run, callback) =>
    if !fs.existsSync "#{path}/Dockerfile"
      return callback new Error 'No Dockerfile found'
    tardir path, (err, archive) =>
      return callback err if err?
      archive.on 'error', callback
      cache = ''
      cache = '&nocache=true' if !usecache
      
      @modem
        .postFile "/build?t=#{id}#{cache}", archive
        .stream (err, output) ->
          return callback err if err?
          
          output.on 'data', (data) ->
            data = JSON.parse data
            return callback data.error if data.error?
            return if !data.stream?
            lines = data.stream
              .split '\n'
              .filter (d) -> d isnt ''
            for line in lines
              run line
          
          output.on 'end', callback
  
  image: (id) =>
    rebuild: (path, run, callback) =>
      @build_image id, path, no, run, callback
      @image id
    
    build: (path, run, callback) =>
      @build_image id, path, yes, run, callback
      @image id
    
    up: (name, cmd, callback) =>
      params =
        Image: id
      
      if cmd.length > 0
        params.Cmd = cmd
      
      @createContainer name, params, (err, container) =>
        return callback err if err?
        id = container.Id
        container = @container id
        container.start (err) =>
          return callback err if err?
          callback null, id
      @image id
    
    inspect: (callback) =>
      @modem
        .get "/images/#{id}/json"
        .result callback
      @image id
    
    rm: (callback) =>
      @modem
        .delete "/images/#{id}"
        .result callback
      @image id
    
    run: (cmd, stdin, stdout, stderr, run, callback)  =>
      params =
        AttachStdin: yes
        AttachStdout: yes
        AttachStderr: yes
        Tty: yes
        OpenStdin: yes
        StdinOnce: no
        Cmd: cmd
        Image: id
      
      @createContainer null, params, (err, container) =>
        return run err if err?
        id = container.Id
        container = @container container.Id
        
        container.attach (err, stream) =>
          return run err if err?
          
          run null, id
          
          stream.pipe stdout
          wasRaw = process.isRaw
          stdin.resume()
          stdin.setEncoding 'utf8'
          if stdin.setRawMode?
            stdin.setRawMode yes
          stdin.pipe stream
          
          updatesize = ->
            container.resize stdout.rows, stdout.columns, ->
          stdout.on 'resize', updatesize
          updatesize() if stdout.rows?
          
          container.start (err) =>
            return callback err if err?
            
            kill = (signal) =>
              stream.unpipe stdout
              stdin.unpipe stream
              stream.end()
              stdout.removeListener 'resize', updatesize
              # This will kick off the wait (eventually)
              container.kill ->
            
            process.on 'SIGTERM', -> kill 'SIGTERM'
            process.on 'SIGINT', -> kill 'SIGINT'
            process.on 'SIGHUP', -> kill 'SIGHUP'
            
            process.on 'uncaughtException', (err) ->
              log err.stack
              process.exit 1
            
            container.wait (err, result) =>
              return callback err if err?
              container.rm (err) ->
                return callback err if err?
                callback null, result.StatusCode
      @image id
      