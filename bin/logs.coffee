modem = require 'ducke-modem'

module.exports = (ducke, containers) ->
  for id in containers
    ducke
      .container id
      .logs (err, stream) ->
        if err?
          console.error err
          process.exit 1
        stream.pipe process.stdout
        #modem.DemuxStream stream, process.stdout, process.stderr