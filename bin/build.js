// Generated by CoffeeScript 1.8.0
module.exports = function(ducke, id) {
  return ducke.image(id).build(process.cwd(), console.log, function(err) {
    if (err != null) {
      console.error(err);
      return process.exit(1);
    }
  });
};