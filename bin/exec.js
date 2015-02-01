// Generated by CoffeeScript 1.8.0
module.exports = function(ducke, container, cmd) {
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
};