series = require '../src/series'

module.exports = (ducke, containers) ->
  tasks = []
  results = []
  
  for id in containers
    do (id) ->
      tasks.push (cb) ->
        ducke
          .container id
          .inspect (err, inspect) ->
            if err?
              console.error err
              process.exit 1
            results.push inspect
            cb()
  
  series tasks, -> console.log JSON.stringify results, null, 2