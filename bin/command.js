// Generated by CoffeeScript 1.8.0
var Docke, args, buildOptions, command, commands, docke, fs, minimist, options, url_parse, usage;

require('colors');

url_parse = require('url').parse;

fs = require('fs');

minimist = require('minimist');

Docke = require('../src/docke');

usage = "\nUsage: " + 'docke'.cyan + " command\n\nCommands:\n  \n  ping      Test the connection to docker\n  ps        List the running dockers and their ip addresses\n";

buildOptions = function(args) {
  var path, result;
  result = {
    host: url_parse(process.env.DOCKER_HOST || 'unix:///var/run/docker.sock'),
    port: process.env.DOCKER_PORT
  };
  if (process.env.DOCKER_TLS_VERIFY !== '' || false && (process.env.DOCKER_CERT_PATH != null)) {
    path = process.env.DOCKER_CERT_PATH;
    result.ca = fs.readFileSync("" + path + "/ca.pem");
    result.cert = fs.readFileSync("" + path + "/cert.pem");
    result.key = fs.readFileSync("" + path + "/key.pem");
    result.https = {
      cert: result.cert,
      key: result.key,
      ca: result.ca
    };
  }
  return result;
};

args = minimist(process.argv.slice(2), {
  "default": {
    'http-addr': '127.0.0.1:8500'
  }
});

if (args._.length === 0) {
  console.error(usage);
  process.exit(1);
}

options = buildOptions(args);

docke = new Docke(options);

commands = {
  ping: function() {
    return docke.ping(function(err, isUp) {
      if (err != null) {
        console.error(err);
        process.exit(1);
      }
      if (isUp) {
        return console.log('Docker is up'.green);
      } else {
        return console.error('Docker is down'.red);
      }
    });
  },
  ps: function() {
    return docke.ps(function(err, results) {
      var ip, result, _i, _len, _results;
      if (err != null) {
        console.error(err);
        process.exit(1);
      }
      _results = [];
      for (_i = 0, _len = results.length; _i < _len; _i++) {
        result = results[_i];
        ip = result.inspect.NetworkSettings.IPAddress.toString();
        while (ip.length < 16) {
          ip += ' ';
        }
        _results.push(console.log("" + ip.blue + " " + result.container.Names[0].slice(1)));
      }
      return _results;
    });
  },
  test: function() {
    return docke.test(function(err, result) {
      if (err != null) {
        console.error(err);
        process.exit(1);
      }
      return console.log(result);
    });
  }
};

command = args._[0];

if (commands[command] == null) {
  console.error("Unknown command " + command.cyan);
  console.error(usage);
  process.exit(1);
}

commands[command]();
