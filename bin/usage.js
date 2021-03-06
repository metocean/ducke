// Generated by CoffeeScript 1.9.1
var Ducke, args, cmds, command, commands, ducke, parameters, usage, usage_error;

require('colors');

Ducke = require('../src/ducke');

parameters = require('ducke-modem').Parameters;

usage = "👾\n\n  Usage: " + 'ducke'.cyan + " command parameters\n         " + 'ducke'.cyan + " option\n\n  Common:\n  \n    ps        List all running containers\n    logs      Attach to container logs\n    run       Start a new container interactively\n    up        Start a new container\n    exec      Run a command inside an existing container\n  \n  Containers:\n  \n    inspect   Show details about containers\n    kill      Send SIGTERM to running containers\n    stop      Stop containers\n    purge     Remove week old stopped containers\n    cull      Stop and delete containers\n    rm        Delete containers\n  \n  Images:\n  \n    ls        List available images\n    orphans   List all orphaned images\n    rmi       Delete images\n    inspecti  Show details about images\n  \n  Building:\n  \n    build     Build an image from a Dockerfile\n    rebuild   Build an image from a Dockerfile from scratch\n\n  Options:\n\n    -h          Display this usage information\n    -v          Display the version number\n";

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

ducke = new Ducke(parameters(args));

commands = {
  status: require('./status'),
  ps: require('./ps'),
  logs: require('./logs'),
  run: require('./run'),
  up: require('./up'),
  exec: require('./exec'),
  inspect: require('./inspect'),
  kill: require('./kill'),
  stop: require('./stop'),
  purge: require('./purge'),
  cull: require('./cull'),
  rm: require('./rm'),
  ls: require('./ls'),
  orphans: require('./orphans'),
  rmi: require('./rmi'),
  inspecti: require('./inspecti'),
  build: require('./build'),
  rebuild: require('./rebuild')
};

if (args.length === 0) {
  console.error(usage);
  return commands.status(ducke);
}

cmds = {
  ps: function() {
    if (args.length === 0) {
      return commands.ps(ducke);
    }
    return usage_error('ducke ps requires no arguments');
  },
  inspect: function() {
    if (args.length !== 0) {
      return commands.inspect(ducke, args);
    }
    return usage_error('ducke inspect requires container names');
  },
  logs: function() {
    if (args.length !== 0) {
      return commands.logs(ducke, args);
    }
    return usage_error('ducke logs requires container names');
  },
  run: function() {
    if (args.length > 0) {
      return commands.run(ducke, args[0], args.slice(1));
    }
    return usage_error('ducke run requires an image name');
  },
  start: function() {
    return cmds.up();
  },
  up: function() {
    if (args.length > 0) {
      return commands.up(ducke, args[0], args.slice(1));
    }
    return usage_error('ducke up requires an image name and command');
  },
  exec: function() {
    if (args.length > 0) {
      return commands.exec(ducke, args[0], args.slice(1));
    }
    return usage_error('ducke exec requires a container name');
  },
  build: function() {
    if (args.length === 1) {
      return commands.build(ducke, args[0]);
    }
    return usage_error('ducke build requires an image name');
  },
  rebuild: function() {
    if (args.length === 1) {
      return commands.rebuild(ducke, args[0]);
    }
    return usage_error('ducke build requires an image name');
  },
  down: function() {
    return cmds.stop();
  },
  stop: function() {
    if (args.length !== 0) {
      return commands.stop(ducke, args);
    }
    return usage_error('ducke stop requires container names');
  },
  "delete": function() {
    return cmds.rm();
  },
  rm: function() {
    if (args.length !== 0) {
      return commands.rm(ducke, args);
    }
    return usage_error('ducke rm requires container names');
  },
  cull: function() {
    if (args.length !== 0) {
      return commands.cull(ducke, args);
    }
    return usage_error('ducke cull requires container names');
  },
  die: function() {
    return cmds.kill();
  },
  kill: function() {
    if (args.length !== 0) {
      return commands.kill(ducke, args);
    }
    return usage_error('ducke kill requires container names');
  },
  images: function() {
    return cmds.ls();
  },
  ls: function() {
    if (args.length === 0) {
      return commands.ls(ducke);
    }
    return usage_error('ducke ls requires no arguments');
  },
  orphan: function() {
    return cmds.orphans();
  },
  orphans: function() {
    if (args.length === 0) {
      return commands.orphans(ducke);
    }
    return usage_error('ducke orphans requires no arguments');
  },
  rmi: function() {
    if (args.length !== 0) {
      return commands.rmi(ducke, args);
    }
    return usage_error('ducke rmi requires image names');
  },
  purge: function() {
    if (args.length === 0) {
      return commands.purge(ducke);
    }
    return usage_error('ducke purge requires no arguments');
  },
  inspecti: function() {
    if (args.length !== 0) {
      return commands.inspecti(ducke, args);
    }
    return usage_error('ducke inspecti requires image names');
  },
  '-h': function() {
    return console.log(usage);
  },
  '-v': function() {
    var pjson;
    pjson = require('../package.json');
    return console.log(pjson.version);
  }
};

command = args[0];

args.shift();

if (cmds[command] != null) {
  return cmds[command]();
}

usage_error(command + " is not a known ducke command");
