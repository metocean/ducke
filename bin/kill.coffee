series = require '../src/series'

module.exports = (ducke, containers) ->
  tasks = []
  
  console.log()
  for id in containers
    do (id) ->
      tasks.push (cb) ->
        ducke
          .container id
          .kill (err) ->
            if err?
              if err.statusCode is 404
                console.error "  #{id.red} is an unknown container"
                return cb()
              
              if err.statusCode is 500
                console.error "  could not send SIGTERM to #{id.red}"
                return cb()
              
              console.error err
              console.error JSON.stringify err
              process.exit 1
            
            console.log "  #{'killed'.green} #{id}"
            cb()
  
  series tasks, -> console.log()