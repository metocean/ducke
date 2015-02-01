series = require '../src/series'

module.exports = (ducke, images) ->
  tasks = []
  results = []
  
  for id in images
    do (id) ->
      tasks.push (cb) ->
        ducke
          .image id
          .inspect (err, inspect) ->
            if err?
              console.error err
              process.exit 1
            results.push inspect
            cb()
  
  series tasks, -> console.log JSON.stringify results, null, 2