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
  var byid, image, node, result, root, value, _, _i, _len;
  root = {};
  byid = {};
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
  }
  for (_ in byid) {
    node = byid[_];
    if (node.image.ParentId !== '') {
      byid[node.image.ParentId].children.push(node);
    }
  }
  result = [];
  for (_ in root) {
    value = root[_];
    result.push(value);
  }
  return result;
};