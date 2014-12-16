// Generated by CoffeeScript 1.8.0
var series;

require('colors');

series = function(tasks, callback) {
  var next, result;
  tasks = tasks.slice(0);
  next = function(cb) {
    var task;
    if (tasks.length === 0) {
      return cb();
    }
    task = tasks.shift();
    return task(function() {
      return next(cb);
    });
  };
  result = function(cb) {
    return next(cb);
  };
  if (callback != null) {
    result(callback);
  }
  return result;
};

module.exports = {
  status: function(ducke) {
    return ducke.ping(function(err, isUp) {
      if ((err != null) || !isUp) {
        console.error();
        console.error('  docker is down'.red);
        console.error();
        return process.exit(1);
      } else {
        return ducke.ps(function(err, results) {
          var ess, running, stopped;
          if ((err != null) || results.length === 0) {
            console.error();
            console.error('  There are no docker containers on this system'.magenta);
            console.error();
          } else {
            ess = function(num, s, p) {
              if (num === 1) {
                return s;
              } else {
                return p;
              }
            };
            running = results.filter(function(d) {
              return d.inspect.State.Running;
            }).length;
            stopped = results.length - running;
            console.error();
            console.error("  There " + (ess(running, 'is', 'are')) + " " + (running.toString().green) + " running container" + (ess(running, '', 's')) + " and " + (stopped.toString().red) + " stopped container" + (ess(stopped, '', 's')));
            console.error();
          }
          return process.exit(1);
        });
      }
    });
  },
  ps: function(ducke) {
    return ducke.ps(function(err, results) {
      var image, name, result, status, _i, _len;
      if (err != null) {
        console.error(err);
        process.exit(1);
      }
      if (results.length === 0) {
        console.error();
        console.error('  There are no docker containers on this system'.magenta);
        console.error();
        return;
      }
      console.log();
      for (_i = 0, _len = results.length; _i < _len; _i++) {
        result = results[_i];
        status = result.inspect.State.Running ? result.inspect.NetworkSettings.IPAddress.toString().blue : 'stopped'.red;
        while (status.length < 26) {
          status += ' ';
        }
        name = result.container.Names[0].slice(1);
        image = result.inspect.Config.Image;
        console.log("  " + status + " " + name + " (" + image + ")");
      }
      return console.log();
    });
  },
  inspect: function(ducke, containers) {
    var id, results, tasks, _fn, _i, _len;
    tasks = [];
    results = [];
    _fn = function(id) {
      return tasks.push(function(cb) {
        return ducke.container(id).inspect(function(err, inspect) {
          if (err != null) {
            console.error(err);
            process.exit(1);
          }
          results.push(inspect);
          return cb();
        });
      });
    };
    for (_i = 0, _len = containers.length; _i < _len; _i++) {
      id = containers[_i];
      _fn(id);
    }
    return series(tasks, function() {
      return console.log(JSON.stringify(results, null, 2));
    });
  },
  logs: function(ducke, containers) {
    var id, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = containers.length; _i < _len; _i++) {
      id = containers[_i];
      _results.push(ducke.container(id).logs(function(err, stream) {
        if (err != null) {
          console.error(err);
          process.exit(1);
        }
        return stream.pipe(process.stdout);
      }));
    }
    return _results;
  },
  run: function(ducke, image, cmd) {
    var fin, run;
    run = function(err, id) {
      if (err != null) {
        console.error(err);
        process.exit(1);
      }
      return ducke.container(id).inspect(function(err, inspect) {
        var name;
        if (err != null) {
          console.error(err);
          process.exit(1);
        }
        name = inspect.Name.slice(1);
        image = inspect.Config.Image;
        console.log();
        console.log("  " + 'running'.green + " " + name + " (" + image + ")");
        return console.log();
      });
    };
    fin = function(err, code) {
      if (err != null) {
        console.error(err);
        process.exit(1);
      }
      return process.exit(code);
    };
    if ((cmd == null) || cmd.length === 0) {
      cmd = ['bash'];
    }
    return ducke.image(image).run(cmd, process.stdin, process.stdout, process.stderr, run, fin);
  },
  up: function(ducke, image, cmd) {
    return ducke.image(image).up(null, cmd, function(err, id) {
      if (err != null) {
        console.error(err);
        process.exit(1);
      }
      return ducke.container(id).inspect(function(err, inspect) {
        var name;
        if (err != null) {
          console.error(err);
          process.exit(1);
        }
        name = inspect.Name.slice(1);
        image = inspect.Config.Image;
        console.log();
        console.log("  " + 'running'.green + " " + name + " (" + image + ")");
        return console.log();
      });
    });
  },
  exec: function(ducke, container, cmd) {
    return ducke.container(container).inspect(function(err, inspect) {
      var image, name;
      if (err != null) {
        console.error(err);
        process.exit(1);
      }
      name = inspect.Name.slice(1);
      image = inspect.Config.Image;
      console.log();
      console.log("  " + 'exec'.green + " " + name + " (" + image + ")");
      console.log();
      if ((cmd == null) || cmd.length === 0) {
        cmd = ['bash'];
      }
      return ducke.container(container).exec(cmd, process.stdin, process.stdout, process.stderr, function(err, code) {
        if (err != null) {
          console.error(err);
          process.exit(1);
        }
        return process.exit(code);
      });
    });
  },
  build: function(ducke, id) {
    return ducke.image(id).build(process.cwd(), console.log, function(err) {
      if (err != null) {
        console.error(err);
        return process.exit(1);
      }
    });
  },
  rebuild: function(ducke, id) {
    return ducke.image(id).rebuild(process.cwd(), console.log, function(err) {
      if (err != null) {
        console.error(err);
        return process.exit(1);
      }
    });
  },
  stop: function(ducke, containers) {
    var id, tasks, _fn, _i, _len;
    tasks = [];
    console.log();
    _fn = function(id) {
      return tasks.push(function(cb) {
        return ducke.container(id).stop(function(err) {
          if (err != null) {
            if (err.statusCode === 404) {
              console.error("  " + id.red + " is an unknown container");
              return cb();
            }
            if (err.statusCode === 304) {
              console.error("  " + id.red + " has already been stopped");
              return cb();
            }
            if (err.statusCode === 500) {
              console.error("  could not stop " + id.red);
              return cb();
            }
            console.error(err);
            console.error(JSON.stringify(err));
            process.exit(1);
          }
          console.log("  " + 'stopped'.green + " " + id);
          return cb();
        });
      });
    };
    for (_i = 0, _len = containers.length; _i < _len; _i++) {
      id = containers[_i];
      _fn(id);
    }
    return series(tasks, function() {
      return console.log();
    });
  },
  rm: function(ducke, containers) {
    var id, tasks, _fn, _i, _len;
    tasks = [];
    console.log();
    _fn = function(id) {
      return tasks.push(function(cb) {
        return ducke.container(id).rm(function(err) {
          if (err != null) {
            if (err.statusCode === 404) {
              console.error("  " + id.red + " is an unknown container");
              return cb();
            }
            if (err.statusCode === 500) {
              console.error("  could not delete " + id.red);
              return cb();
            }
            console.error(err);
            console.error(JSON.stringify(err));
            process.exit(1);
          }
          console.log("  " + 'deleted'.green + " " + id);
          return cb();
        });
      });
    };
    for (_i = 0, _len = containers.length; _i < _len; _i++) {
      id = containers[_i];
      _fn(id);
    }
    return series(tasks, function() {
      return console.log();
    });
  },
  kill: function(ducke, containers) {
    var id, tasks, _fn, _i, _len;
    tasks = [];
    console.log();
    _fn = function(id) {
      return tasks.push(function(cb) {
        return ducke.container(id).kill(function(err) {
          if (err != null) {
            if (err.statusCode === 404) {
              console.error("  " + id.red + " is an unknown container");
              return cb();
            }
            if (err.statusCode === 500) {
              console.error("  could not send SIGTERM to " + id.red);
              return cb();
            }
            console.error(err);
            console.error(JSON.stringify(err));
            process.exit(1);
          }
          console.log("  " + 'killed'.green + " " + id);
          return cb();
        });
      });
    };
    for (_i = 0, _len = containers.length; _i < _len; _i++) {
      id = containers[_i];
      _fn(id);
    }
    return series(tasks, function() {
      return console.log();
    });
  }
};
