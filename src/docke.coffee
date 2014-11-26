Modem = require './modem'
demux = require './demuxstream'

buildOptions = (args) ->
  result =
    host: url_parse process.env.DOCKER_HOST or 'unix:///var/run/docker.sock'
    port: process.env.DOCKER_PORT
  
  if process.env.DOCKER_TLS_VERIFY isnt '' or no and process.env.DOCKER_CERT_PATH?
    path = process.env.DOCKER_CERT_PATH
    result.ca = fs.readFileSync "#{path}/ca.pem"
    result.cert = fs.readFileSync "#{path}/cert.pem"
    result.key = fs.readFileSync "#{path}/key.pem"
    result.https =
      cert: result.cert
      key: result.key
      ca: result.ca
  
  result

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
  
  ping: (callback)  =>
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
  
  #docke.execResize /exec/(id)/resize
  
  run: (image, callback)  =>
    params =
      AttachStdin: yes
      AttachStdout: yes
      AttachStderr: yes
      Tty: yes
      OpenStdin: yes
      StdinOnce: no
      Cmd: ['bash']
      Image: image
    
    @_modem
      .post '/containers/create', params
      .result (err, container) =>
        return callback err if err?
        
        @_modem
          .post "/containers/#{container.Id}/attach?stream=true&stdin=true&stdout=true&stderr=true", {}
          .connect (err, stream) =>
            return callback err if err?
            stream.pipe process.stdout
            #demux stream, process.stdout, process.stderr
            
            process.stdin.resume()
            process.stdin.setEncoding 'utf8'
            process.stdin.setRawMode yes
            process.stdin.pipe stream
            
            @_modem
              .post "/containers/#{container.Id}/start", {}
              .result (err) =>
                return callback err if err?
                @_modem
                  .post "/containers/#{container.Id}/wait", {}
                  .result (err, result) =>
                    return callback err if err?
                    process.stdin.removeAllListeners()
                    process.stdin.resume()
                    stream.end()
                    @_modem
                      .delete "/containers/#{container.Id}"
                      .result (err) ->
                        return callback err if err?
                        callback null, result.StatusCode
            