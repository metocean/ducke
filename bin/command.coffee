require 'colors'
url_parse = require('url').parse
fs = require 'fs'
minimist = require 'minimist'
Docke = require '../src/docke'

usage = """

Usage: #{'docke'.cyan} command

Commands:
  
  ping      Test the connection to docker
  ps        List the running dockers and their ip addresses
  inspect   Show details about a container
  logs      Attach to the logs of a container
  run       Start a shell inside a new container
  exec      Start a shell inside an existing container
  kill      Delete a container

"""

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

args = minimist process.argv[2..],
  default: 'http-addr': '127.0.0.1:8500'
if args._.length is 0
  console.error usage
  process.exit 1

options = buildOptions args
docke = new Docke options

commands =
  ping: ->
    docke.ping (err, isUp) ->
      if err?
        console.error err
        process.exit 1
      if isUp
        console.log 'docker is up'.green
      else
        console.error 'docker is down'.red
  
  ps: ->
    docke.ps (err, results) ->
      if err?
        console.error err
        process.exit 1
      
      if results.length is 0
        console.log "No docker containers"
      
      for result in results
        status = if result.inspect.State.Running
          result.inspect.NetworkSettings.IPAddress.toString().blue
        else
          'stopped'.red
        status += ' ' while status.length < 26
        
        name = result.container.Names[0][1..]
        image = result.inspect.Config.Image
        
        console.log "#{status} #{name} (#{image})"
  
  inspect: ->
    if args._.length isnt 2
      console.error "docke inspect requires container name"
      console.error usage
      process.exit 1
    
    container = args._[1]
    
    docke
      .container container
      .inspect (err, inspect) ->
        if err?
          console.error err
          process.exit 1
        console.log inspect
  
  logs: ->
    if args._.length isnt 2
      console.error "docke logs requires container name"
      console.error usage
      process.exit 1
    
    container = args._[1]
    
    resize = ->
      docke
        .container container
        .resize process.stdout.rows, process.stdout.columns, ->
    process.stdout.on 'resize', resize
    resize()
    
    docke
      .container container
      .logs (err, stream) ->
        if err?
          console.error err
          process.exit 1
        stream.pipe process.stdout
  
  run: ->
    if args._.length isnt 2
      console.error "docke run requires image name"
      console.error usage
      process.exit 1
    
    image = args._[1]
    
    docke
      .image image
      .run process.stdin, process.stdout, process.stderr, (err, code) ->
        if err?
          console.error err
          process.exit 1
        process.exit code
  
  exec: ->
    if args._.length isnt 2
      console.error "docke exec requires container name"
      console.error usage
      process.exit 1
    
    container = args._[1]
    
    docke
      .container container
      .exec process.stdin, process.stdout, process.stderr, (err, code) ->
        if err?
          console.error err
          process.exit 1
        process.exit code
  
  kill: ->
    if args._.length isnt 2
      console.error "docke kill requires container name"
      console.error usage
      process.exit 1
    
    container = args._[1]
    
    docke
      .container container
      .kill (err) ->
        if err?
          console.error err
          process.exit 1
        process.exit 0

command = args._[0]
if !commands[command]?
  console.error "Unknown command #{command.cyan}"
  console.error usage
  process.exit 1

commands[command]()