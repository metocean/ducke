require 'colors'

Ducke = require '../src/ducke'
parameters = require('ducke-modem').Parameters

usage = """
👾

  Usage: #{'ducke'.cyan} command parameters
         #{'ducke'.cyan} option

  Common:
  
    ps        List all running containers
    logs      Attach to container logs
    run       Start a new container interactively
    up        Start a new container
    exec      Run a command inside an existing container
  
  Containers:
  
    inspect   Show details about containers
    kill      Send SIGTERM to running containers
    stop      Stop containers
    purge     Remove week old stopped containers
    cull      Stop and delete containers
    rm        Delete containers
  
  Images:
  
    ls        List available images
    orphans   List all orphaned images
    rmi       Delete images
    inspecti  Show details about images
  
  Building:
  
    build     Build an image from a Dockerfile
    rebuild   Build an image from a Dockerfile from scratch

  Options:

    -h          Display this usage information
    -v          Display the version number

"""

usage_error = (message) =>
  console.error()
  console.error "  #{message}".magenta
  console.error()
  console.error usage
  process.exit 1

args = process.argv[2..]
ducke = new Ducke parameters args


commands =
  status: require './status'
  
  ps: require './ps'
  logs: require './logs'
  run: require './run'
  up: require './up'
  exec: require './exec'
  
  inspect: require './inspect'
  kill: require './kill'
  stop: require './stop'
  purge: require './purge'
  cull: require './cull'
  rm: require './rm'
  
  ls: require './ls'
  orphans: require './orphans'
  rmi: require './rmi'
  inspecti: require './inspecti'
  
  build: require './build'
  rebuild: require './rebuild'

if args.length is 0
  console.error usage
  return commands.status ducke

cmds =
  ps: ->
    return commands.ps ducke if args.length is 0
    usage_error 'ducke ps requires no arguments'
  
  inspect: ->
    return commands.inspect ducke, args if args.length isnt 0
    usage_error 'ducke inspect requires container names'
  
  logs: ->
    return commands.logs ducke, args if args.length isnt 0
    usage_error 'ducke logs requires container names'
  
  run: ->
    return commands.run ducke, args[0], args[1..] if args.length > 0
    usage_error 'ducke run requires an image name'
  
  start: -> cmds.up()
  up: ->
    return commands.up ducke, args[0], args[1..] if args.length > 0
    usage_error 'ducke up requires an image name and command'
  
  exec: ->
    return commands.exec ducke, args[0], args[1..] if args.length > 0
    usage_error 'ducke exec requires a container name'
  
  build: ->
    return commands.build ducke, args[0] if args.length is 1
    usage_error 'ducke build requires an image name'
  
  rebuild: ->
    return commands.rebuild ducke, args[0] if args.length is 1
    usage_error 'ducke build requires an image name'
  
  down: -> cmds.stop()
  stop: ->
    return commands.stop ducke, args if args.length isnt 0
    usage_error 'ducke stop requires container names'
  
  delete: -> cmds.rm()
  rm: ->
    return commands.rm ducke, args if args.length isnt 0
    usage_error 'ducke rm requires container names'
  
  cull: ->
    return commands.cull ducke, args if args.length isnt 0
    usage_error 'ducke cull requires container names'
  
  die: -> cmds.kill()
  kill: ->
    return commands.kill ducke, args if args.length isnt 0
    usage_error 'ducke kill requires container names'
  
  images: -> cmds.ls()
  ls: ->
    return commands.ls ducke if args.length is 0
    usage_error 'ducke ls requires no arguments'
  
  orphan: -> cmds.orphans()
  orphans: ->
    return commands.orphans ducke if args.length is 0
    usage_error 'ducke orphans requires no arguments'
  
  rmi: ->
    return commands.rmi ducke, args if args.length isnt 0
    usage_error 'ducke rmi requires image names'
  
  purge: ->
    return commands.purge ducke if args.length is 0
    usage_error 'ducke purge requires no arguments'
  
  inspecti: ->
    return commands.inspecti ducke, args if args.length isnt 0
    usage_error 'ducke inspecti requires image names'


  '-h': ->
    console.log usage

  '-v': ->
    pjson = require '../package.json'
    console.log pjson.version

command = args[0]
args.shift()
return cmds[command]() if cmds[command]?
usage_error "#{command} is not a known ducke command"