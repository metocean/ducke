fs = require 'fs'
tar = require 'tar-fs'
zlib = require 'zlib'

module.exports = (path, cb) ->
  if !fs.existsSync path
    return cb new Error "#{path} not found"
  
  if !fs.lstatSync(path).isDirectory()
    return cb new Error "#{path} is not a directory"
  
  output = tar
    .pack path
    .pipe zlib.createGzip()
  cb null, output