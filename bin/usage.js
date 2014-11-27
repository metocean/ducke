// Generated by CoffeeScript 1.8.0
var Docke, args, cmds, command, commands, docke, parameters, usage, usage_error;

require('colors');

Docke = require('../src/docke');

commands = require('./commands');

parameters = require('../src/parameters');

usage = "👾\n\n  Usage: " + 'docke'.cyan + " command parameters\n\n  Commands:\n  \n    ps        List all running containers\n    logs      Attach to container logs\n    run       Start a shell inside a new container\n    exec      Start a shell inside an existing container\n  \n  Docker management:\n  \n    inspect   Show details about containers\n    kill      Send SIGTERM to running containers\n    stop      Stop containers\n    rm        Delete containers\n";

usage_error = (function(_this) {
  return function(message) {
    console.error();
    console.error(("  " + message).magenta);
    console.error();
    console.error(usage);
    return process.exit(1);
  };
})(this);

args = process.argv.slice(2);

docke = new Docke(parameters(args));

if (args.length === 0) {
  console.error(usage);
  return commands.status(docke);
}

cmds = {
  ps: function() {
    if (args.length === 0) {
      return commands.ps(docke);
    }
    return usage_error('docke ps requires no arguments');
  },
  inspect: function() {
    if (args.length !== 0) {
      return commands.inspect(docke, args);
    }
    return usage_error('docke inspect requires container names');
  },
  logs: function() {
    if (args.length !== 0) {
      return commands.logs(docke, args);
    }
    return usage_error('docke logs requires container names');
  },
  run: function() {
    if (args.length === 1) {
      return commands.run(docke, args[0]);
    }
    return usage_error('docke run requires an image name');
  },
  exec: function() {
    if (args.length === 1) {
      return commands.exec(docke, args[0]);
    }
    return usage_error('docke exec requires a container name');
  },
  stop: function() {
    if (args.length !== 0) {
      return commands.stop(docke, args);
    }
    return usage_error('docke stop requires container names');
  },
  rm: function() {
    if (args.length !== 0) {
      return commands.rm(docke, args);
    }
    return usage_error('docke rm requires container names');
  },
  kill: function() {
    if (args.length !== 0) {
      return commands.kill(docke, args);
    }
    return usage_error('docke kill requires container names');
  }
};

command = args[0];

args.shift();

if (cmds[command] != null) {
  return cmds[command]();
}

usage_error("" + command + " is not a known docker command");
