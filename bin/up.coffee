module.exports = (ducke, image, cmd) ->
  ducke
    .image image
    .up null, cmd, (err, id) ->
      if err?
        console.error err
        process.exit 1
      ducke
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