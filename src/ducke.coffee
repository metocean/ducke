Modem = require './modem'
demux = require './demuxstream'
tardir = require './tardir'
groupimages = require './groupimages'
stream = require 'stream'

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
    @_modem = new Modem options
  
  ping: (callback) =>
    @_modem
      .get '/_ping'
      .result (err, result) ->
        return callback err if err?
        callback null, result is 'OK'
  
  ps: (callback)  =>
    @_modem
      .get '/containers/json?all=1'
      .result (err, containers) =>
        return callback err if err?
        results = []
        errors = []
        tasks = []
        for container in containers
          do (container) =>
            tasks.push (cb) =>
              @_modem
                .get "/containers/#{container.Id}/json"
                .result (err, inspect) =>
                  if err?
                    errors.push err
                    return cb()
                  results.push
                    container: container
                    inspect: inspect
                  cb()
        parallel tasks, =>
          
          results.sort (a, b) ->
            a = a.container.Names[0]
            b = b.container.Names[0]
            return 1 if a > b
            return -1 if a < b
            0
          
          return callback errors, results if errors.length > 0
          callback null, results
  
  ls: (callback)  =>
    @_modem
      .get '/images/json?all=1'
      .result (err, images) =>
        return callback err if err?
        callback null, groupimages images
  
  createContainer: (name, params, callback) =>
    url = '/containers/create'
    url += "?name=#{name}" if name?
    @_modem
      .post url, params
      .result callback
  
  container: (id) =>
    inspect: (callback) =>
      @_modem
        .get "/containers/#{id}/json"
        .result callback
    
    logs: (callback) =>
      @_modem
        .get "/containers/#{id}/logs?stderr=1&stdout=1&follow=1&tail=10"
        .stream callback
    
    resize: (rows, columns, callback) =>
      @_modem
        .get "/containers/#{id}/resize?h=#{rows}&w=#{columns}"
        .result (err, result) =>
          return callback err if err?
          callback null, result is 'OK'
    
    start: (callback) =>
      @_modem
        .post "/containers/#{id}/start", {}
        .result callback
    
    stop: (callback) =>
      @_modem
        .post "/containers/#{id}/stop?t=5", {}
        .result callback
    
    wait: (callback) =>
      @_modem
        .post "/containers/#{id}/wait", {}
        .result callback
    
    rm: (callback) =>
      @_modem
        .delete "/containers/#{id}"
        .result callback
    
    attach: (callback) =>
      @_modem
        .post "/containers/#{id}/attach?stream=true&stdin=true&stdout=true&stderr=true", {}
        .connect callback
    
    kill: (callback) =>
      @_modem
        .post "/containers/#{id}/kill?signal=SIGTERM", {}
        .result callback
    
    exec: (cmd, stdin, stdout, stderr, callback) =>
      params =
        AttachStdin: yes
        AttachStdout: yes
        AttachStderr: yes
        Tty: yes
        Cmd: cmd
      
      @_modem
        .post "/containers/#{id}/exec", params
        .result (err, exec) =>
          return callback err if err?
          
          @_modem
            .post "/exec/#{exec.Id}/start", { Detach: no, Tty: yes }
            .connect  (err, stream) =>
              return callback err if err?
              
              stream.pipe stdout
              wasRaw = process.isRaw
              stdin.resume()
              stdin.setEncoding 'utf8'
              stdin.setRawMode yes
              stdin.pipe stream
              
              stream.on 'end', ->
                stdin.removeAllListeners()
                stdin.setRawMode wasRaw
                stdin.resume()
                callback null, 0
  
  build_image: (id, path, usecache, run, callback) =>
    tardir path, (err, archive) =>
      return callback err if err?
      archive.on 'error', callback
      cache = ''
      cache = '&nocache=true' if !usecache
      
      @_modem
        .postFile "/build?t=#{id}#{cache}", archive
        .stream (err, output) ->
          return callback err if err?
          
          output.on 'data', (data) ->
            data = JSON.parse data
            return callback data.error if data.error?
            lines = data.stream
              .split '\n'
              .filter (d) -> d isnt ''
            for line in lines
              run line
          
          output.on 'end', callback
  
  image: (id) =>
    rebuild: (path, run, callback) =>
      @build_image id, path, no, run, callback
    
    build: (path, run, callback) =>
      @build_image id, path, yes, run, callback
    
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
    
    rm: (callback) =>
      @_modem
        .delete "/images/#{id}"
        .result callback
    
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
          stdin.setRawMode yes
          stdin.pipe stream
          
          container.start (err) =>
            return callback err if err?
            
            kill = (signal) =>
              stream.unpipe stdout
              stdin.unpipe stream
              stream.end()
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
      