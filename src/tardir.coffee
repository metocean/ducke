tar = require 'tar-fs'
zlib = require 'zlib'

module.exports = (path) ->
  tar
    .pack path
    .pipe zlib.createGzip()