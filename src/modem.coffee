http = require 'http'
https = require 'https'
fs = require 'fs'
resolve_path = require('path').resolve
url = require 'url'
HttpDuplex = require './httpduplex'

debug = require('debug') 'modem'
util = require 'util'

class UnixSocket
  constructor: (host, options) ->
    @_socketPath = host.path
  
  apply: (params) =>
    params.socketPath = @_socketPath
  
  request: (params) =>
    http.request params, ->

class WebRequest
  constructor: (host, options) ->
    @_https = options.https
    @_host = host
    if @_host.protocol is 'tcp:'
      @_host.protocol = if @_https? then 'https:' else 'http:'
    if !@_host.port?
      @_host.port = options.port or 2376
  
  apply: (params) =>
    params.protocol = @_host.protocol
    params.hostname = @_host.hostname
    params.port = @_host.port
    
    if @_https?
      params.key = @_https.key
      params.cert = @_https.cert
      params.ca = @_https.ca
  
  request: (params) =>
    if @_https?
      return https.request params, ->
    http.request params, ->

module.exports = class Modem
  constructor: (options) ->
    @_options =
      https: options.https
      version: options.version
      timeout: options.timeout
    
    host = options.host
    host = url.parse host if typeof host is 'string'
    
    if host.protocol is 'unix:'
      @_conn = new UnixSocket host, options
    else
      @_conn = new WebRequest host, options
  
  get: (options) =>
    if typeof options is 'string'
      options = path: options
    options.method = 'GET'
    @_connect options
  
  post: (options, content) =>
    if typeof options is 'string'
      options = path: options
    if content?
      options.body = JSON.stringify content
    options.method = 'POST'
    options.contentType = 'application/json'
    @_connect options
  
  postFile: (options, file) =>
    if typeof options is 'string'
      options = path: options
    options.method = 'POST'
    if typeof file is 'string'
      file = fs.readFileSync resolve_path file
    options.body = file
    options.contentType = 'application/tar'
    @_connect options
  
  _parsePath: (options) =>
    return options.path if !@version?
    "/#{@version}#{options.path}"
  
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
  
  _dial: (options, callback) =>
    params =
      headers: @_buildHeaders options
      path: @_parsePath options
      method: options.method
    @_conn.apply params
    
    console.log params
    req = @_conn.request params
    debug 'Sending: %s', util.inspect params,
      showHidden: yes
      depth: null
    
    if @timeout
      req.on 'socket', (socket) =>
        socket.setTimeout @timeout
        socket.on 'timeout', -> req.abort()
    
    req.on 'response', (res) =>
      if res.statusCode < 200 or res.statusCode >= 300
        return @_read res, (err, content) =>
          callback new Error("#{res.statusCode} #{content}"), null
      callback null, res
    
    req.on 'error', (err) => callback err, null
    req
  
  _read: (res, callback) =>
    content = ''
    res.on 'data', (data) -> content += data
    res.on 'end', =>
      debug 'Received: %s', content
      try
        callback null, JSON.parse content
      catch e
        callback null, content
  
  _write: (req, data) =>
    if typeof data is 'string' or Buffer.isBuffer data
      console.log data
      req.write data
      req.end()
      return
    data.pipe req
  
  _connect: (options) =>
    console.log options
    stream: (callback) =>
      req = @_dial options, (err, res) =>
        return callback err if err?
        res.setEncoding 'utf8'
        callback null, res
      return req.end() if !options.body?
      @_write req, options.body
    
    connect: (callback) =>
      req = @_dial options, (err, res) =>
        return callback err if err?
        callback null, new HttpDuplex req, res
      req.end()
    
    result: (callback) =>
      req = @_dial options, (err, res) =>
        return callback err if err?
        @_read res, (err, content) =>
          return callback err if err?
          callback null, content
      return req.end() if !options.body?
      @_write req, options.body