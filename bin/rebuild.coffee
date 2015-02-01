module.exports = (ducke, id) ->
  ducke
    .image id
    .rebuild process.cwd(), console.log, (err) ->
      if err?
        console.error err
        process.exit 1