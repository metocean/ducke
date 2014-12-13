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
    return commands.run ducke, args[0] if args.length is 1
    usage_error 'ducke run requires an image name'
    
  exec: ->
    return commands.exec ducke, args[0] if args.length is 1
    usage_error 'ducke exec requires a container name'
    
  stop: ->
    return commands.stop ducke, args if args.length isnt 0
    usage_error 'ducke stop requires container names'
    
  rm: ->
    return commands.rm ducke, args if args.length isnt 0
    usage_error 'ducke rm requires container names'
    
  kill: ->
    return commands.kill ducke, args if args.length isnt 0
    usage_error 'ducke kill requires container names'

command = args[0]
args.shift()
return cmds[command]() if cmds[command]?
usage_error "#{command} is not a known ducke command"