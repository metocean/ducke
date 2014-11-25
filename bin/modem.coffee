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
    @_dial options, callback
  
  post: (options, content, callback) =>
    options.body = JSON.stringify content
    options.method = 'POST'
    options.contentType = 'application/json'
    @_dial options, callback
  
  postFile: (options, file, callback) =>
    options.method = 'POST'
    if typeof file is 'string'
      file = fs.readFileSync resolve_path file
    options.body = file
    options.contentType = 'application/tar'
    @_dail options, callback
  
  _buildHeaders: (options) =>
    headers = {}
    if options.authconfig?
      buffer = new Buffer JSON.stringify options.authconfig
      headers['X-Registry-Auth'] = buffer.toString 'base64'
    if options.contentType?
      headers['Content-Type'] = options.contentType
    if typeof options.body is 'string'
      headers['Content-Length'] = Buffer.byteLength options.body
    else if Buffer.isBuffer options.body
      headers['Content-Length'] = options.body.length
    headers
  
  _buildParams: (headers, path, method) =>
    path = "/#{@version}#{options.path}" if @version?
    
    params =
      headers: headers
      path: path
      method: method
    
    if @socketPath
      params.socketPath = @socketPath
    else
      params.protocol = @host.protocol
      params.hostname = @host.hostname
      params.port = @host.port
    
    if @_options.https?
      params.key = @_options.https.key
      params.cert = @_options.https.cert
      params.ca = @_options.https.ca
    
    params

  _dial: (options, callback) =>
    headers = @_buildHeaders options
    params = @_buildParams headers, options.path, options.method
    
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
    
    return if options.openStdin
    return req.end() if !options.body?
    
    if typeof options.body is 'string' or Buffer.isBuffer options.body
      req.write options.body
      req.end()
    
    options.body.pipe req

  demuxStream: (stream, stdout, stderr) =>
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