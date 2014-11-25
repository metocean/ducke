require 'colors'
usage = """

Usage: #{'docke'.cyan} command

Commands:
  
  ping      Test the connection to docker
  ps        List the running dockers and their ip addresses

"""

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

parseConfig = (args) ->
  result =
    host: process.env.DOCKER_HOST or 'unix:///var/run/docker.sock'
    port: process.env.DOCKER_PORT or 2376
    https: process.env.DOCKER_TLS_VERIFY isnt '' or no
    cert_path: process.env.DOCKER_CERT_PATH
  url_parse = require('url').parse
  result.host = url_parse result.host
  result

buildOptions = (config) ->
  result = {}
  if config.host.protocol is 'unix:'
    result.socketPath = config.host.path
  else
    result.host = config.host
    result.port = config.port or config.host.port
  
  if config.cert_path?
    fs = require 'fs'
    result.ca = fs.readFileSync "#{config.cert_path}/ca.pem"
    result.cert = fs.readFileSync "#{config.cert_path}/cert.pem"
    result.key = fs.readFileSync "#{config.cert_path}/key.pem"
    result.https =
      cert: result.cert
      key: result.key
      ca: result.ca
  
  result

commands =
  ping: ->
    docker.ping (err, result) ->
      return console.error err if err?
      if result is 'OK'
        console.log 'Docker is up'.green
      else
        console.error 'Docker is down'.red
        process.exit 1
  
  ps: ->
    docker.listContainers (err, containers) ->
      return console.error err if err?
      results = []
      tasks = []
      for container in containers
        do (container) ->
          tasks.push (cb) ->
            docker
              .getContainer container.Id
              .inspect (err, inspect) ->
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
  
  exec: ->
    a = process.argv[3..]
    
    if a.length is 0
      console.error "Command exec requires a container name"
      process.exit 1
    
    name = a[0]
    
    a = a[1..]
    a = ['/bin/bash'] if a.length is 0
    
    options =
      AttachStdin: yes
      AttachStdout: yes
      AttachStderr: yes
      OpenStdin: yes
      StdinOnce: yes
      Tty: no
      Cmd: a
    
    docker
      .getContainer name
      .exec options, (err, exec) ->
        return console.error err if err?
        exec.start (err, stream) ->
          return console.error err if err?
          stream.setEncoding 'utf8'
          stream.pipe process.stdout
          process.stdin.pipe stream

  test: ->
    Modem = require './modem'
    m = new Modem options
    m.get '/containers/json', (err, containers) ->
      return console.error err if err?
      console.log containers


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

config = parseConfig args
options = buildOptions config
Docker = require 'dockerode'
docker = new Docker options

commands[command]()