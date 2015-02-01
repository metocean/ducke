series = require '../src/series'

module.exports = (ducke, images) ->
  tasks = []
  
  console.log()
  for id in images
    do (id) ->
      tasks.push (cb) ->
        ducke
          .image id
          .rm (err) ->
            if err?
              if err.statusCode is 404
                console.error "  #{id.red} is an unknown image"
                return cb()
              
              if err.statusCode is 500
                console.error "  could not delete #{id.red}"
                return cb()
              
              console.error err
              console.error JSON.stringify err
              process.exit 1
            
            console.log "  #{'deleted'.green} #{id}"
            cb()
  
  series tasks, -> console.log()