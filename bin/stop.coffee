series = require '../src/series'

module.exports = (ducke, containers) ->
  tasks = []
  
  console.log()
  for id in containers
    do (id) ->
      tasks.push (cb) ->
        ducke
          .container id
          .stop (err) ->
            if err?
              if err.statusCode is 404
                console.error "  #{id.red} is an unknown container"
                return cb()
              
              if err.statusCode is 304
                console.error "  #{id.red} has already been stopped"
                return cb()
              
              if err.statusCode is 500
                console.error "  could not stop #{id.red}"
                return cb()
              
              console.error err
              console.error JSON.stringify err
              process.exit 1
            
            console.log "  #{'stopped'.green} #{id}"
            cb()
  
  series tasks, -> console.log()