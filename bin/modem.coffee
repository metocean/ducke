querystring = require 'querystring'
http = require 'follow-redirects'
fs = require 'fs'
resolve_path = require('path').resolve
url = require 'url'
stream = require 'readable-stream'
HttpDuplex = require './httpduplex'
util = require 'util'
debug = require('debug') 'modem'


module.exports = class Modem
  constructor: (options) ->
    @_options =
      https: options.https
    
    host = options.host
    host = url.parse host if typeof host is 'string'
    
    if options.host.protocol is 'unix:'
      @socketPath = config.host.path
    else
      @host = host
      if @host.protocol is 'tcp:'
        @host.protocol = if @_options.https then 'https:' else 'http:'
      if !@host.port?
        @host.port = options.port or 2376
    @version = options.version
    @timeout = options.timeout
  
  get: (options, callback) =>
    options = path: options if typeof options is 'string'
    options.method = 'GET'
    @dial options, callback
  
  post: (options, callback) =>
    options.method = 'POST'
    @dial options, callback

  dial: (options, callback) =>
    headers = {}
    if options.authconfig
      buffer = new Buffer JSON.stringify options.authconfig
      headers['X-Registry-Auth'] = buffer.toString 'base64'
    
    data = undefined
    if options.file
      if typeof options.file is 'string'
        data = fs.readFileSync resolve_path options.file
      else
        data = options.file
      headers['Content-Type'] = 'application/tar'
    
    else if options.body and options.method is 'POST'
      data = JSON.stringify options.body
      headers['Content-Type'] = 'application/json'
    
    if typeof data is 'string'
      headers['Content-Length'] = Buffer.byteLength data
    else if Buffer.isBuffer data
      headers['Content-Length'] = data.length
    
    params =
      headers: headers
    
    path = options.path
    path = "/#{@version}#{options.path}" if @version?
    if @socketPath
      params.socketPath = @socketPath
      params.path = path
      params.method = options.method
    else
      address = url.format
        protocol: @host.protocol
        hostname: @host.hostname
        port: @host.port
      address = url.resolve address, path
      address = url.parse address
      
      params.protocol = address.protocol
      params.hostname = address.hostname
      params.port = address.port
      params.path = address.path
      params.method = options.method
    
    if @_options.https?
      params.key = @_options.https.key
      params.cert = @_options.https.cert
      params.ca = @_options.https.ca
    
    req = @buildRequest params, options, data, callback
    
    if typeof data is 'string' or Buffer.isBuffer data
      req.write data
    else data.pipe req if data
    req.end() if not options.openStdin and (typeof data is 'string' or data is `undefined` or Buffer.isBuffer(data))

  buildRequest: (params, options, data, callback) =>
    req = http[params.protocol[...-1]].request params, ->
    debug 'Sending: %s', util.inspect params,
      showHidden: yes
      depth: null
    
    if @timeout
      req.on 'socket', (socket) =>
        socket.setTimeout @timeout
        socket.on 'timeout', -> req.abort()

    req.on 'response', (res) =>
      if res.statusCode < 200 or res.statusCode >= 300
        msg = new Error "#{res.statusCode} - #{json}"
        msg.statusCode = res.statusCode
        msg.json = json
        return callback msg, null
      
      if options.openStdin is yes
        return callback null, new HttpDuplex req, res
      
      if options.isStream is yes
        return callback null, res
      
      content = ''
      res.on 'data', (data) -> content += data

      res.on 'end', =>
        debug 'Received: %s', content
        json = undefined
        try
          json = JSON.parse content
        catch e
          json = content
        callback null, json

    req.on 'error', (error) => callback error, null

    req

  demuxStream: (stream, stdout, stderr) =>
    header = null
    stream.on 'readable', ->
      header = header or stream.read 8
      while header isnt null
        type = header.readUInt8 0
        payload = stream.read header.readUInt32BE 4
        break  if payload is null
        if type is 2
          stderr.write payload
        else
          stdout.write payload
        header = stream.read 8