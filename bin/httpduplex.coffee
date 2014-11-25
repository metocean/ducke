util = require 'util'
stream = require 'readable-stream'

module.exports = class HttpDuplex extends stream.Duplex
  constructor: (req, res, options) ->
    self = this
    super options
    @_output = null
    @connect req, res
  
  connect: (req, res) =>
    self = this
    @req = req
    @_output = res
    @emit 'response', res
    res.on 'data', (c) =>
      @_output.pause() unless @push(c)

    res.on 'end', =>
      @push null
  
  _read: (n) =>
    @_output.resume() if @_output
  
  _write: (chunk, encoding, cb) =>
    @req.write chunk, encoding
    cb()
  
  end: (chunk, encoding, cb) =>
    @req.end chunk, encoding, cb