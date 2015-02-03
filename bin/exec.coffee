module.exports = (ducke, container, cmd) ->
  ducke
    .container container
    .inspect (err, inspect) ->
      if err?
        if err.statusCode? and err.statusCode is 404
          console.error()
          console.error "  Container #{container.red} not found"
          console.error()
        else
          console.error()
          console.error err
          console.error()
        process.exit 1
      
      name = inspect.Name[1..]
      image = inspect.Config.Image
      
      console.log()
      console.log "  #{'exec'.green} #{name} (#{image})"
      console.log()
      
      cmd = ['bash'] if !cmd? or cmd.length is 0
      ducke
        .container container
        .exec cmd, process.stdin, process.stdout, process.stderr, (err, code) ->
          return process.exit 1 if err?
          process.exit code