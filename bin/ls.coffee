module.exports = (ducke) ->
  nest = (nodes, indent) ->
    for node in nodes
      # should we skip?
      if node.image.RepoTags[0] is '<none>:<none>' and node.children? and node.children.length > 0
        nest node.children, indent
        continue
      
      space = ''
      space += '  ' while space.length < 2 *indent
      
      output = "  #{space}#{node.image.Id.substr 0, 12}"
      if node.image.RepoTags.length is 1 and node.image.RepoTags[0] is '<none>:<none>'
        if node.children.length is 0
          output += ' orphan'.magenta
        
      else
        for tag in node.image.RepoTags
          output += " #{tag}".cyan
      
      console.log output
      if node.children?
        nest node.children, indent + 1
  
  ducke.ls (err, result) ->
    if err?
      console.error err
      console.error JSON.stringify err
      process.exit 1
    
    console.log()
    nest result.graph, 0
    console.log()