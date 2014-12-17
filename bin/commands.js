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
    return ducke.ps(function(err, statuses) {
      var image, name, output, status, _i, _len;
      if (err != null) {
        console.error(err);
        process.exit(1);
      }
      if (statuses.length === 0) {
        console.error();
        console.error('  There are no docker containers on this system'.magenta);
        console.error();
        return;
      }
      console.log();
      for (_i = 0, _len = statuses.length; _i < _len; _i++) {
        status = statuses[_i];
        output = status.inspect.State.Running ? status.inspect.NetworkSettings.IPAddress.toString().blue : 'stopped'.red;
        while (output.length < 26) {
          output += ' ';
        }
        name = status.container.Names[0].slice(1);
        image = status.inspect.Config.Image;
        console.log("  " + output + " " + name + " (" + image + ")");
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
  },
  ls: function(ducke) {
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
  },
  orphans: function(ducke) {
    return ducke.ls(function(err, result) {
      var node, orphans, _i, _j, _len, _len1, _ref;
      if (err != null) {
        console.error(err);
        console.error(JSON.stringify(err));
        process.exit(1);
      }
      orphans = [];
      console.log();
      _ref = result.images;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        node = _ref[_i];
        if (node.image.RepoTags.length === 1 && node.image.RepoTags[0] === '<none>:<none>' && node.children.length === 0) {
          orphans.push(node);
        }
      }
      if (orphans.length === 0) {
        console.log('  There are no orphaned images on this system.'.magenta);
      } else {
        for (_j = 0, _len1 = orphans.length; _j < _len1; _j++) {
          node = orphans[_j];
          console.log("" + (node.image.Id.substr(0, 12)));
        }
      }
      return console.log();
    });
  },
  rmi: function(ducke, images) {
    var id, tasks, _fn, _i, _len;
    tasks = [];
    console.log();
    _fn = function(id) {
      return tasks.push(function(cb) {
        return ducke.image(id).rm(function(err) {
          if (err != null) {
            if (err.statusCode === 404) {
              console.error("  " + id.red + " is an unknown image");
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
    for (_i = 0, _len = images.length; _i < _len; _i++) {
      id = images[_i];
      _fn(id);
    }
    return series(tasks, function() {
      return console.log();
    });
  }
};
