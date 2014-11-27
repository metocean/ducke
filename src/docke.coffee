Modem = require './modem'
demux = require './demuxstream'

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

module.exports = class Docke
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
  
  createContainer: (params, callback) =>
    @_modem
      .post '/containers/create', params
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
    
    delete: (callback) =>
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
    
    exec: (stdin, stdout, stderr, callback) =>
      params =
        AttachStdin: yes
        AttachStdout: yes
        AttachStderr: yes
        Tty: yes
        Cmd: ['bash']
      
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
  
  image: (id) =>
    run: (stdin, stdout, stderr, callback)  =>
      params =
        AttachStdin: yes
        AttachStdout: yes
        AttachStderr: yes
        Tty: yes
        OpenStdin: yes
        StdinOnce: no
        Cmd: ['bash']
        Image: id
      
      @createContainer params, (err, container) =>
        return callback err if err?
        container = @container container.Id
        
        container.attach (err, stream) =>
          return callback err if err?
          
          stream.pipe stdout
          wasRaw = process.isRaw
          stdin.resume()
          stdin.setEncoding 'utf8'
          stdin.setRawMode yes
          stdin.pipe stream
          
          container.start (err) =>
            return callback err if err?
            
            log = (message) ->
              fs.appendFileSync '/Users/tcoats/Desktop/log.txt',
                "#{Date.now().toString()} #{message}\n"
            
            kill = (signal) =>
              fs = require 'fs'
              log signal
              container.kill (err) =>
                log 'killed'
                return callback err if err?
                container.stop (err) =>
                  log 'stopped'
                  return callback err if err?
                  container.delete (err) =>
                    log 'deleted'
                    callback err, 0
            
            process.on 'SIGTERM', -> kill 'SIGTERM'
            process.on 'SIGINT', -> kill 'SIGINT'
            process.on 'SIGHUP', -> kill 'SIGHUP'
            process.on 'exit', -> log 'exit'
            
            container.wait (err, result) =>
              #process.removeListener 'SIGINT', teardown
              return callback err if err?
              
              stdin.removeAllListeners()
              stdin.setRawMode wasRaw
              stdin.resume()
              stream.end()
              container.delete (err) ->
                return callback err if err?
                callback null, result.StatusCode
      