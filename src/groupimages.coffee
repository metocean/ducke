example =
  Created: 1371157430
  Id: '511136ea3c5a64f264b78b5433614aec563103b4d4702f3ba7d4d2698e22c158'
  ParentId: ''
  RepoTags: [
    '<none>:<none>'
  ]
  Size: 0
  VirtualSize: 0

module.exports = (images) ->
  root = {}
  byid = {}
  bytag = {}
  
  for image in images
    node =
      image: image
      children: []
    
    byid[image.Id] = node
    root[image.Id] = node if image.ParentId is ''
    for tag in image.RepoTags
      continue if tag is '<none>:<none>'
      bytag[tag] = node
  
  for _, node of byid
    if node.image.ParentId isnt ''
      byid[node.image.ParentId].children.push node
  
  result =
    images: []
    graph: []
    tags: bytag
    ids: byid
  
  for _, value of byid
    result.images.push value
  for _, value of root
    result.graph.push value
  
  result