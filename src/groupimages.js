// Generated by CoffeeScript 1.8.0
var example;

example = {
  Created: 1371157430,
  Id: '511136ea3c5a64f264b78b5433614aec563103b4d4702f3ba7d4d2698e22c158',
  ParentId: '',
  RepoTags: ['<none>:<none>'],
  Size: 0,
  VirtualSize: 0
};

module.exports = function(images) {
  var byid, bytag, image, node, result, root, tag, value, _, _i, _j, _len, _len1, _ref;
  root = {};
  byid = {};
  bytag = {};
  for (_i = 0, _len = images.length; _i < _len; _i++) {
    image = images[_i];
    node = {
      image: image,
      children: []
    };
    byid[image.Id] = node;
    if (image.ParentId === '') {
      root[image.Id] = node;
    }
    _ref = image.RepoTags;
    for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
      tag = _ref[_j];
      if (tag === '<none>:<none>') {
        continue;
      }
      bytag[tag] = node;
    }
  }
  for (_ in byid) {
    node = byid[_];
    if (node.image.ParentId !== '') {
      byid[node.image.ParentId].children.push(node);
    }
  }
  result = {
    images: [],
    graph: [],
    tags: bytag,
    ids: byid
  };
  for (_ in byid) {
    value = byid[_];
    result.images.push(value);
  }
  for (_ in root) {
    value = root[_];
    result.graph.push(value);
  }
  return result;
};
