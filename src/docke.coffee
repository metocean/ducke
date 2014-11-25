Modem = require './modem'

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

  test: (callback)  =>
    @_modem
      .get '/containers/json'
      .result (err, result) =>
        return callback err if err?
        callback null, result