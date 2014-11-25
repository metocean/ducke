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
  
  test: ->
    docke.test (err, result) ->
      if err?
        console.error err
        process.exit 1
      console.log result

command = args._[0]
if !commands[command]?
  console.error "Unknown command #{command.cyan}"
  console.error usage
  process.exit 1

commands[command]()