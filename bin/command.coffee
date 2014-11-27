require 'colors'
url_parse = require('url').parse
fs = require 'fs'
Docke = require '../src/docke'

usage = """
👾

  Usage: #{'docke'.cyan} command parameters

  Commands:
  
    ps        List all running containers
    logs      Attach to container logs
    run       Start a shell inside a new container
    exec      Start a shell inside an existing container
  
  Docker management:
  
    inspect   Show details about containers
    kill      Send SIGTERM to running containers
    stop      Stop containers
    rm        Delete containers

"""
usage_error = (message) =>
  console.error()
  console.error "  #{message}".magenta
  console.error()
  console.error usage
  process.exit 1

series = (tasks, callback) ->
  tasks = tasks.slice 0
  next = (cb) ->
    return cb() if tasks.length is 0
    task = tasks.shift()
    task -> next cb
  result = (cb) -> next cb
  result(callback) if callback?
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

args = process.argv[2..]
options = buildOptions args
docke = new Docke options

commands =
  ps: ->
    if args.length isnt 0
      usage_error 'docke ps requires no arguments'
      
    docke.ps (err, results) ->
      if err?
        console.error err
        process.exit 1
      
      if results.length is 0
        console.error()
        console.error '  There are no docker containers on this system'.magenta
        console.error()
        return
      
      console.log()
      for result in results
        status = if result.inspect.State.Running
          result.inspect.NetworkSettings.IPAddress.toString().blue
        else
          'stopped'.red
        status += ' ' while status.length < 26
        
        name = result.container.Names[0][1..]
        image = result.inspect.Config.Image
        
        console.log "  #{status} #{name} (#{image})"
      console.log()
  
  inspect: ->
    if args.length is 0
      usage_error 'docke inspect requires container names'
    
    tasks = []
    results = []
    
    for arg in args
      do (arg) ->
        tasks.push (cb) ->
          docke
            .container arg
            .inspect (err, inspect) ->
              if err?
                console.error err
                process.exit 1
              results.push inspect
              cb()
    
    series tasks, -> console.log JSON.stringify results, null, 2
  
  logs: ->
    if args.length is 0
      usage_error 'docke logs requires container names'
    
    for arg in args
      docke
        .container arg
        .logs (err, stream) ->
          if err?
            console.error err
            process.exit 1
          stream.pipe process.stdout
  
  run: ->
    if args.length isnt 1
      usage_error 'docke run requires an image name'
    
    image = args[0]
    
    run = (err, id) ->
      if err?
        console.error err
        process.exit 1
      
      docke
        .container id
        .inspect (err, inspect) ->
          if err?
            console.error err
            process.exit 1
          
          name = inspect.Name[1..]
          image = inspect.Config.Image
          
          console.log()
          console.log "  #{'running'.green} #{name} (#{image})"
          console.log()
      
    
    fin = (err, code) ->
      if err?
        console.error err
        process.exit 1
      process.exit code
    
    docke
      .image image
      .run process.stdin, process.stdout, process.stderr, run, fin
  
  exec: ->
    if args.length isnt 1
      usage_error 'docke exec requires a container name'
    
    container = args[0]
    
    docke
      .container container
      .inspect (err, inspect) ->
        if err?
          console.error err
          process.exit 1
        
        name = inspect.Name[1..]
        image = inspect.Config.Image
        
        console.log()
        console.log "  #{'exec'.green} #{name} (#{image})"
        console.log()
        
        docke
          .container container
          .exec process.stdin, process.stdout, process.stderr, (err, code) ->
            if err?
              console.error err
              process.exit 1
            process.exit code
  
  stop: ->
    if args.length is 0
      usage_error 'docke stop requires container names'
    
    tasks = []
    
    console.log()
    for arg in args
      do (arg) ->
        tasks.push (cb) ->
          docke
            .container arg
            .stop (err) ->
              if err?
                if err.statusCode is 404
                  console.error "  #{arg.red} is an unknown container"
                  return cb()
                
                if err.statusCode is 304
                  console.error "  #{arg.red} has already been stopped"
                  return cb()
                
                if err.statusCode is 500
                  console.error "  could not stop #{arg.red}"
                  return cb()
                
                console.error err
                console.error JSON.stringify err
                process.exit 1
              
              console.log "  #{'stopped'.green} #{arg}"
              cb()
    
    series tasks, ->
      console.log()
  
  rm: ->
    if args.length is 0
      usage_error 'docke rm requires container names'
    
    tasks = []
    
    console.log()
    for arg in args
      do (arg) ->
        tasks.push (cb) ->
          docke
            .container arg
            .rm (err) ->
              if err?
                if err.statusCode is 404
                  console.error "  #{arg.red} is an unknown container"
                  return cb()
                
                if err.statusCode is 500
                  console.error "  could not delete #{arg.red}"
                  return cb()
                
                console.error err
                console.error JSON.stringify err
                process.exit 1
              
              console.log "  #{'deleted'.green} #{arg}"
              cb()
    
    series tasks, ->
      console.log()
  
  kill: ->
    if args.length is 0
      usage_error 'docke kill requires container names'
    
    tasks = []
    
    console.log()
    for arg in args
      do (arg) ->
        tasks.push (cb) ->
          docke
            .container arg
            .kill (err) ->
              if err?
                if err.statusCode is 404
                  console.error "  #{arg.red} is an unknown container"
                  return cb()
                
                if err.statusCode is 500
                  console.error "  could not send SIGTERM to #{arg.red}"
                  return cb()
                
                console.error err
                console.error JSON.stringify err
                process.exit 1
              
              console.log "  #{'killed'.green} #{arg}"
              cb()
    
    series tasks, ->
      console.log()

if args.length is 0
  console.error usage
  
  docke.ping (err, isUp) ->
    if err? or !isUp
      console.error()
      console.error '  docker is down'.red
      console.error()
      process.exit 1
    else
      console.error()
      console.error '  docker is up with'.green
      docke.ps (err, results) ->
        if err? or results.length is 0
          console.error()
          console.error '  There are no docker containers on this system'.magenta
          console.error()
        else
          ess = (num) -> if num is 1 then '' else 's'
          running = results
            .filter (d) -> d.inspect.State.Running
            .length
          stopped = running - results.length
          console.error()
          console.error "    #{running.toString().green} running container#{ess running}"
          console.error "    #{stopped.toString().red} stopped container#{ess stopped}"
          console.error()
        process.exit 1

else
  command = args[0]
  args.shift()

  if !commands[command]?
    usage_error "#{command} is not a known docker command"

  commands[command]()