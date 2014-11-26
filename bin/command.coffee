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
        console.log 'Docker is up'.green
      else
        console.error 'Docker is down'.red
  
  ps: ->
    docke.ps (err, results) ->
      if err?
        console.error err
        process.exit 1
      for result in results
        ip = result.inspect.NetworkSettings.IPAddress.toString()
        ip += ' ' while ip.length < 16
        console.log "#{ip.blue} #{result.container.Names[0][1..]}"
  
  inspect: ->
    if args._.length isnt 2
      console.error "Inspect requires container name or id"
      console.error usage
      process.exit 1
    
    name = args._[1]
    
    docke.inspect name, (err, inspect) ->
      if err?
        console.error err
        process.exit 1
      console.log inspect
  
  logs: ->
    if args._.length isnt 2
      console.error "Logs requires container name or id"
      console.error usage
      process.exit 1
    
    name = args._[1]
    
    resize = ->
      docke.resize name, process.stdout.rows, process.stdout.columns, ->
    process.stdout.on 'resize', resize
    resize()
    
    docke.logs name, (err, stream) ->
      if err?
        console.error err
        process.exit 1
      stream.pipe process.stdout
  
  bash: ->
    if args._.length isnt 2
      console.error "Bash requires container name or id"
      console.error usage
      process.exit 1
    
    name = args._[1]
    
    docke.exec name, '/bin/bash', (err, result) =>
      console.log result
  
  test: ->
    return docke.test (err, stream) ->
      if err?
        console.error err
        process.exit 1
    
    isRaw = process.isRaw
    previousKey = null
    CTRL_P = '\u0010'
    CTRL_Q = '\u0011'
    
    docke.startExec 'f388afb4856eafc217ff4883c0de3ed580fa4420547daea2ef88f848dbaa4891', (err, stream) ->
      console.log '1'
      
      if err?
        console.error err
        process.exit 1
      
      stream.pipe process.stdout
      
      process.stdin.resume()
      process.stdin.setEncoding 'utf8'
      process.stdin.setRawMode yes
      process.stdin.pipe stream
      
      process.stdin.on 'data', (key) ->
        if previousKey is CTRL_P and key is CTRL_Q
          process.stdin.removeAllListeners()
          process.stdin.setRawMode isRaw
          process.stdin.resume()
          stream.end()
          process.exit()
        previousKey = key

command = args._[0]
if !commands[command]?
  console.error "Unknown command #{command.cyan}"
  console.error usage
  process.exit 1

commands[command]()