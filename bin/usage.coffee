require 'colors'

Ducke = require '../src/ducke'
commands = require './commands'
parameters = require '../src/parameters'

usage = """
👾

  Usage: #{'ducke'.cyan} command parameters

  Commands:
  
    ps        List all running containers
    logs      Attach to container logs
    run       Start a new container interactively
    up        Start a new container
    exec      Run a command inside an existing container
  
  Docker management:
  
    build     Build an image from a Dockerfile
    rebuild   Build an image from a Dockerfile from scratch
    inspect   Show details about containers
    kill      Send SIGTERM to running containers
    stop      Stop containers
    rm        Delete containers
    ls        List available images
    orphans   List all orphaned images

"""

usage_error = (message) =>
  console.error()
  console.error "  #{message}".magenta
  console.error()
  console.error usage
  process.exit 1

args = process.argv[2..]
ducke = new Ducke parameters args

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
  
  stop: ->
    return commands.stop ducke, args if args.length isnt 0
    usage_error 'ducke stop requires container names'
  
  rm: ->
    return commands.rm ducke, args if args.length isnt 0
    usage_error 'ducke rm requires container names'
  
  kill: ->
    return commands.kill ducke, args if args.length isnt 0
    usage_error 'ducke kill requires container names'
  
  ls: ->
    return commands.ls ducke if args.length is 0
    usage_error 'ducke ls requires no arguments'
  
  orphans: ->
    return commands.orphans ducke if args.length is 0
    usage_error 'ducke orphans requires no arguments'

command = args[0]
args.shift()
return cmds[command]() if cmds[command]?
usage_error "#{command} is not a known ducke command"