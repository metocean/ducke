module.exports = (ducke) ->
  ducke.ls (err, result) ->
    if err?
      console.error err
      console.error JSON.stringify err
      process.exit 1
    
    orphans = []
    
    console.log()
    for node in result.images
      if node.image.RepoTags.length is 1 and node.image.RepoTags[0] is '<none>:<none>' and node.children.length is 0
          orphans.push node
    
    if orphans.length is 0
      console.log '  There are no orphaned images on this system.'.magenta
    else
      for node in orphans
        console.log "#{node.image.Id.substr 0, 12}"
    console.log()