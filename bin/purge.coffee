series = require '../src/series'

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
    statuses = statuses.filter (status) ->
      return no if status.inspect.State.Running
      finishedAt = new Date status.inspect.State.FinishedAt
      now = new Date()
      oneweek = 7 * 24 * 60 * 60 * 1000
      return no if now - finishedAt < oneweek
      yes
    
    if statuses.length is 0
      console.log '  No containers older than one week'.magenta
      console.log()
      return
    
    tasks = []
    for status in statuses
      do (status) ->
        tasks.push (cb) ->
          name = status.container.Names[0][1..]
          image = status.inspect.Config.Image
          output = "  #{name} (#{image})"
          output += ' ' while output.length < 26
          ducke
            .container status.container.Id
            .rm (err) ->
              if err?
                console.error err
                return cb()
              
              console.log "  #{output} #{'deleted'.red}"
              cb()
      
    series tasks, ->
      console.log()