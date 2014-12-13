require 'colors'

Docke = require '../src/docke'
commands = require './commands'
parameters = require '../src/parameters'

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

args = process.argv[2..]
docke = new Docke parameters args

if args.length is 0
  console.error usage
  return commands.status docke

cmds =
  ps: ->
    return commands.ps docke if args.length is 0
    usage_error 'docke ps requires no arguments'
    
  inspect: ->
    return commands.inspect docke, args if args.length isnt 0
    usage_error 'docke inspect requires container names'
    
  logs: ->
    return commands.logs docke, args if args.length isnt 0
    usage_error 'docke logs requires container names'
    
  run: ->
    return commands.run docke, args[0] if args.length is 1
    usage_error 'docke run requires an image name'
    
  exec: ->
    return commands.exec docke, args[0] if args.length is 1
    usage_error 'docke exec requires a container name'
    
  stop: ->
    return commands.stop docke, args if args.length isnt 0
    usage_error 'docke stop requires container names'
    
  rm: ->
    return commands.rm docke, args if args.length isnt 0
    usage_error 'docke rm requires container names'
    
  kill: ->
    return commands.kill docke, args if args.length isnt 0
    usage_error 'docke kill requires container names'

command = args[0]
args.shift()
return cmds[command]() if cmds[command]?
usage_error "#{command} is not a known docke command"