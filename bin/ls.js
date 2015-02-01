// Generated by CoffeeScript 1.8.0
module.exports = function(ducke) {
  var nest;
  nest = function(nodes, indent) {
    var node, output, space, tag, _i, _j, _len, _len1, _ref, _results;
    _results = [];
    for (_i = 0, _len = nodes.length; _i < _len; _i++) {
      node = nodes[_i];
      if (node.image.RepoTags[0] === '<none>:<none>' && (node.children != null) && node.children.length > 0) {
        nest(node.children, indent);
        continue;
      }
      space = '';
      while (space.length < 2 * indent) {
        space += '  ';
      }
      output = "  " + space + (node.image.Id.substr(0, 12));
      if (node.image.RepoTags.length === 1 && node.image.RepoTags[0] === '<none>:<none>') {
        if (node.children.length === 0) {
          output += ' orphan'.magenta;
        }
      } else {
        _ref = node.image.RepoTags;
        for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
          tag = _ref[_j];
          output += (" " + tag).cyan;
        }
      }
      console.log(output);
      if (node.children != null) {
        _results.push(nest(node.children, indent + 1));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };
  return ducke.ls(function(err, result) {
    if (err != null) {
      console.error(err);
      console.error(JSON.stringify(err));
      process.exit(1);
    }
    console.log();
    nest(result.graph, 0);
    return console.log();
  });
};