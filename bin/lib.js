// Generated by CoffeeScript 1.8.0
var Docker, args, buildOptions, command, commands, config, docker, minimist, options, parallel, parseConfig, usage;

require('colors');

usage = "\nUsage: " + 'docke'.cyan + " command\n\nCommands:\n  \n  ping      Test the connection to docker\n  ps        List the running dockers and their ip addresses\n";

parallel = function(tasks, callback) {
  var count, result;
  count = tasks.length;
  result = function(cb) {
    var task, _i, _len, _results;
    if (count === 0) {
      return cb();
    }
    _results = [];
    for (_i = 0, _len = tasks.length; _i < _len; _i++) {
      task = tasks[_i];
      _results.push(task(function() {
        count--;
        if (count === 0) {
          return cb();
        }
      }));
    }
    return _results;
  };
  if (callback != null) {
    result(callback);
  }
  return result;
};

parseConfig = function(args) {
  var result, url_parse;
  result = {
    host: process.env.DOCKER_HOST || 'unix:///var/run/docker.sock',
    port: process.env.DOCKER_PORT || 2376,
    https: process.env.DOCKER_TLS_VERIFY !== '' || false,
    cert_path: process.env.DOCKER_CERT_PATH
  };
  url_parse = require('url').parse;
  result.host = url_parse(result.host);
  return result;
};

buildOptions = function(config) {
  var fs, result;
  result = {};
  if (config.host.protocol === 'unix:') {
    result.socketPath = config.host.path;
  } else {
    result.host = config.host;
    result.port = config.port || config.host.port;
  }
  if (config.cert_path != null) {
    fs = require('fs');
    result.ca = fs.readFileSync("" + config.cert_path + "/ca.pem");
    result.cert = fs.readFileSync("" + config.cert_path + "/cert.pem");
    result.key = fs.readFileSync("" + config.cert_path + "/key.pem");
    result.https = {
      cert: result.cert,
      key: result.key,
      ca: result.ca
    };
  }
  return result;
};

commands = {
  ping: function() {
    return docker.ping(function(err, result) {
      if (err != null) {
        return console.error(err);
      }
      if (result === 'OK') {
        return console.log('Docker is up'.green);
      } else {
        console.error('Docker is down'.red);
        return process.exit(1);
      }
    });
  },
  ps: function() {
    return docker.listContainers(function(err, containers) {
      var container, results, tasks, _fn, _i, _len;
      if (err != null) {
        return console.error(err);
      }
      results = [];
      tasks = [];
      _fn = function(container) {
        return tasks.push(function(cb) {
          return docker.getContainer(container.Id).inspect(function(err, inspect) {
            if (err != null) {
              console.error(err);
            }
            results.push({
              container: container,
              inspect: inspect
            });
            return cb();
          });
        });
      };
      for (_i = 0, _len = containers.length; _i < _len; _i++) {
        container = containers[_i];
        _fn(container);
      }
      return parallel(tasks, function() {
        var ip, result, _j, _len1, _results;
        results.sort(function(a, b) {
          a = a.container.Names[0];
          b = b.container.Names[0];
          if (a > b) {
            return 1;
          }
          if (a < b) {
            return -1;
          }
          return 0;
        });
        _results = [];
        for (_j = 0, _len1 = results.length; _j < _len1; _j++) {
          result = results[_j];
          ip = result.inspect.NetworkSettings.IPAddress.toString();
          while (ip.length < 16) {
            ip += ' ';
          }
          _results.push(console.log("" + ip.blue + " " + result.container.Names[0].slice(1)));
        }
        return _results;
      });
    });
  },
  exec: function() {
    var a, name, options;
    a = process.argv.slice(3);
    if (a.length === 0) {
      console.error("Command exec requires a container name");
      process.exit(1);
    }
    name = a[0];
    a = a.slice(1);
    if (a.length === 0) {
      a = ['/bin/bash'];
    }
    options = {
      AttachStdin: true,
      AttachStdout: true,
      AttachStderr: true,
      OpenStdin: true,
      StdinOnce: true,
      Tty: false,
      Cmd: a
    };
    return docker.getContainer(name).exec(options, function(err, exec) {
      if (err != null) {
        return console.error(err);
      }
      return exec.start(function(err, stream) {
        if (err != null) {
          return console.error(err);
        }
        stream.setEncoding('utf8');
        stream.pipe(process.stdout);
        return process.stdin.pipe(stream);
      });
    });
  },
  test: function() {
    var Modem, m;
    Modem = require('./modem');
    m = new Modem(options);
    return m.get('/containers/json', function(err, containers) {
      if (err != null) {
        return console.error(err);
      }
      return console.log(containers);
    });
  }
};

minimist = require('minimist');

args = minimist(process.argv.slice(2), {
  "default": {
    'http-addr': '127.0.0.1:8500'
  }
});

if (args._.length === 0) {
  console.error(usage);
  process.exit(1);
}

command = args._[0];

if (commands[command] == null) {
  console.error("Unknown command " + command.cyan);
  console.error(usage);
  process.exit(1);
}

config = parseConfig(args);

options = buildOptions(config);

Docker = require('dockerode');

docker = new Docker(options);

commands[command]();
