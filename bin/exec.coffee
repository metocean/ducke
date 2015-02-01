module.exports = (ducke, container, cmd) ->
  ducke
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
      
      cmd = ['bash'] if !cmd? or cmd.length is 0
      ducke
        .container container
        .exec cmd, process.stdin, process.stdout, process.stderr, (err, code) ->
          if err?
            console.error err
            process.exit 1
          process.exit code