module.exports = (ducke) ->
  ducke.ps (err, statuses) ->
    if err?
      console.error err
      process.exit 1
    
    if statuses.length is 0
      console.error()
      console.error '  There are no docker containers on this system'.magenta
      console.error()
      return
    
    console.log()
    for status in statuses
      output = if status.inspect.State.Running
        status.inspect.NetworkSettings.IPAddress.toString().blue
      else
        'stopped'.red
      output += ' ' while output.length < 26
      
      name = status.container.Names[0][1..]
      image = status.inspect.Config.Image
      
      console.log "  #{output} #{name} (#{image})"
    console.log()