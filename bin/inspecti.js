// Generated by CoffeeScript 1.8.0
var series;

series = require('../src/series');

module.exports = function(ducke, images) {
  var id, results, tasks, _fn, _i, _len;
  tasks = [];
  results = [];
  _fn = function(id) {
    return tasks.push(function(cb) {
      return ducke.image(id).inspect(function(err, inspect) {
        if (err != null) {
          console.error(err);
          process.exit(1);
        }
        results.push(inspect);
        return cb();
      });
    });
  };
  for (_i = 0, _len = images.length; _i < _len; _i++) {
    id = images[_i];
    _fn(id);
  }
  return series(tasks, function() {
    return console.log(JSON.stringify(results, null, 2));
  });
};
