require 'colors'
usage = """

Usage: #{'docke'.cyan} command

Commands:
  
  ping      Test the connection to docker
  ps        List the running dockers and their ip addresses

"""

url_parse = require('url').parse
fs = require 'fs'
Modem = require './modem'

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

commands =
  ping: ->
    modem.get '/_ping', (err, result) ->
      return console.error err if err?
      if result is 'OK'
        console.log 'Docker is up'.green
      else
        console.error 'Docker is down'.red
        process.exit 1
  
  ps: ->
    modem.get '/containers/json', (err, containers) ->
      return console.error err if err?
      results = []
      tasks = []
      for container in containers
        do (container) ->
          tasks.push (cb) ->
            modem.get "/containers/#{container.Id}/json", (err, inspect) ->
              console.error err if err?
              results.push
                container: container
                inspect: inspect
              cb()
      parallel tasks, ->
        results.sort (a, b) ->
          a = a.container.Names[0]
          b = b.container.Names[0]
          return 1 if a > b
          return -1 if a < b
          0
        for result in results
          ip = result.inspect.NetworkSettings.IPAddress.toString()
          ip += ' ' while ip.length < 16
          console.log "#{ip.blue} #{result.container.Names[0][1..]}"

  test: ->
    modem.get '/containers/json', (err, result) ->
      return console.error err if err?
      console.log result


minimist = require 'minimist'
args = minimist process.argv[2..],
  default: 'http-addr': '127.0.0.1:8500'
if args._.length is 0
  console.error usage
  process.exit 1

command = args._[0]
if !commands[command]?
  console.error "Unknown command #{command.cyan}"
  console.error usage
  process.exit 1

options = buildOptions args
modem = new Modem options

commands[command]()