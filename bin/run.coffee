module.exports = (ducke, image, cmd) ->
  run = (err, id) ->
    if err?
      if err.statusCode? and err.statusCode is 404
        console.error()
        console.error "  Image #{image.red} not found"
        console.error()
      else
        console.error()
        console.error err
        console.error()
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
    
  fin = (err, code) ->
    if err?
      console.error err
      process.exit 1
    process.exit code
  
  cmd = ['bash'] if !cmd? or cmd.length is 0
  ducke
    .image image
    .run cmd, process.stdin, process.stdout, process.stderr, run, fin