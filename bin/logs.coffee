modem = require 'ducke-modem'

module.exports = (ducke, containers) ->
  for id in containers
    ducke
      .container id
      .logs (err, stream) ->
        if err?
          if err.statusCode? and err.statusCode is 404
            console.error()
            console.error "  Container #{container.red} not found"
            console.error()
          else
            console.error()
            console.error err
            console.error()
          process.exit 1
        modem.DemuxStream stream, process.stdout, process.stderr