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
      .get '/containers/json'
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

  inspect: (id, callback) =>
    @_modem
      .get "/containers/#{id}/json"
      .result callback
  
  logs: (id, callback) =>
    @_modem
      .get "/containers/#{id}/logs?stderr=1&stdout=1&follow=1&tail=10"
      .stream callback
  
  resize: (id, rows, columns, callback) =>
    @_modem
      .get "/containers/#{id}/resize?h=#{rows}&w=#{columns}"
      .result (err, result) =>
        return callback err if err?
        callback null, result is 'OK'
  
  exec: (id, cmd, callback) =>
    params =
      AttachStdin: yes
      AttachStdout: yes
      AttachStderr: yes
      Tty: yes
      Cmd: cmd.split ' '
      Container: id
    @_modem
      .post "/containers/#{id}/exec", params
      .result callback
  
  startExec: (id, callback) =>
    params =
      Detach: no
      Tty: yes
    @_modem
      .post "/exec/#{id}/start", params
      .connect callback
  
  startContainer: (id, callback) =>
    @_modem
      .post "/containers/#{id}/start", {}
      .result callback
  
  waitContainer: (id, callback) =>
    @_modem
      .post "/containers/#{id}/wait", {}
      .result callback
  
  deleteContainer: (id, callback) =>
    @_modem
      .delete "/containers/#{id}"
      .result callback
  
  attachContainer: (id, callback) =>
    @_modem
    .post "/containers/#{id}/attach?stream=true&stdin=true&stdout=true&stderr=true", {}
    .connect callback
  
  createContainer: (params, callback) =>
    @_modem
      .post '/containers/create', params
      .result callback
  
  run: (image, stdin, stdout, stderr, callback)  =>
    params =
      AttachStdin: yes
      AttachStdout: yes
      AttachStderr: yes
      Tty: yes
      OpenStdin: yes
      StdinOnce: no
      Cmd: ['bash']
      Image: image
    
    @createContainer params, (err, container) =>
      return callback err if err?
      @attachContainer container.Id, (err, stream) =>
        return callback err if err?
        stream.pipe stdout
        
        wasRaw = process.isRaw
        stdin.resume()
        stdin.setEncoding 'utf8'
        stdin.setRawMode yes
        stdin.pipe stream
        
        @startContainer container.Id, (err) =>
          return callback err if err?
          @waitContainer container.Id, (err, result) =>
            return callback err if err?
            stdin.removeAllListeners()
            stdin.setRawMode wasRaw
            stdin.resume()
            stream.end()
            @deleteContainer container.Id, (err) ->
              return callback err if err?
              callback null, result.StatusCode
      