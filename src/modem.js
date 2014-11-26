// Generated by CoffeeScript 1.8.0
var HttpDuplex, Modem, UnixSocket, WebRequest, debug, fs, http, https, resolve_path, url, util,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

http = require('http');

https = require('https');

fs = require('fs');

resolve_path = require('path').resolve;

url = require('url');

HttpDuplex = require('./httpduplex');

debug = require('debug')('modem');

util = require('util');

UnixSocket = (function() {
  function UnixSocket(host, options) {
    this.request = __bind(this.request, this);
    this.apply = __bind(this.apply, this);
    this._socketPath = host.path;
  }

  UnixSocket.prototype.apply = function(params) {
    return params.socketPath = this._socketPath;
  };

  UnixSocket.prototype.request = function(params) {
    return http.request(params, function() {});
  };

  return UnixSocket;

})();

WebRequest = (function() {
  function WebRequest(host, options) {
    this.request = __bind(this.request, this);
    this.apply = __bind(this.apply, this);
    this._https = options.https;
    this._host = host;
    if (this._host.protocol === 'tcp:') {
      this._host.protocol = this._https != null ? 'https:' : 'http:';
    }
    if (this._host.port == null) {
      this._host.port = options.port || 2376;
    }
  }

  WebRequest.prototype.apply = function(params) {
    params.protocol = this._host.protocol;
    params.hostname = this._host.hostname;
    params.port = this._host.port;
    if (this._https != null) {
      params.key = this._https.key;
      params.cert = this._https.cert;
      return params.ca = this._https.ca;
    }
  };

  WebRequest.prototype.request = function(params) {
    if (this._https != null) {
      return https.request(params, function() {});
    }
    return http.request(params, function() {});
  };

  return WebRequest;

})();

module.exports = Modem = (function() {
  function Modem(options) {
    this._connect = __bind(this._connect, this);
    this._write = __bind(this._write, this);
    this._read = __bind(this._read, this);
    this._dial = __bind(this._dial, this);
    this._buildHeaders = __bind(this._buildHeaders, this);
    this._parsePath = __bind(this._parsePath, this);
    this.postFile = __bind(this.postFile, this);
    this["delete"] = __bind(this["delete"], this);
    this.post = __bind(this.post, this);
    this.get = __bind(this.get, this);
    var host;
    this._options = {
      https: options.https,
      version: options.version,
      timeout: options.timeout
    };
    host = options.host;
    if (typeof host === 'string') {
      host = url.parse(host);
    }
    if (host.protocol === 'unix:') {
      this._conn = new UnixSocket(host, options);
    } else {
      this._conn = new WebRequest(host, options);
    }
  }

  Modem.prototype.get = function(options) {
    if (typeof options === 'string') {
      options = {
        path: options
      };
    }
    options.method = 'GET';
    return this._connect(options);
  };

  Modem.prototype.post = function(options, content) {
    if (typeof options === 'string') {
      options = {
        path: options
      };
    }
    if (content != null) {
      options.body = JSON.stringify(content);
    }
    options.method = 'POST';
    options.contentType = 'application/json';
    return this._connect(options);
  };

  Modem.prototype["delete"] = function(options) {
    if (typeof options === 'string') {
      options = {
        path: options
      };
    }
    options.method = 'DELETE';
    return this._connect(options);
  };

  Modem.prototype.postFile = function(options, file) {
    if (typeof options === 'string') {
      options = {
        path: options
      };
    }
    options.method = 'POST';
    if (typeof file === 'string') {
      file = fs.readFileSync(resolve_path(file));
    }
    options.body = file;
    options.contentType = 'application/tar';
    return this._connect(options);
  };

  Modem.prototype._parsePath = function(options) {
    if (this.version == null) {
      return options.path;
    }
    return "/" + this.version + options.path;
  };

  Modem.prototype._buildHeaders = function(options) {
    var buffer, headers;
    headers = {};
    if (options.authconfig != null) {
      buffer = new Buffer(JSON.stringify(options.authconfig));
      headers['X-Registry-Auth'] = buffer.toString('base64');
    }
    if (options.contentType != null) {
      headers['Content-Type'] = options.contentType;
    }
    if (typeof options.body === 'string') {
      headers['Content-Length'] = Buffer.byteLength(options.body);
    } else if (Buffer.isBuffer(options.body)) {
      headers['Content-Length'] = options.body.length;
    }
    return headers;
  };

  Modem.prototype._dial = function(options, callback) {
    var params, req;
    params = {
      headers: this._buildHeaders(options),
      path: this._parsePath(options),
      method: options.method
    };
    this._conn.apply(params);
    req = this._conn.request(params);
    debug('Sending: %s', util.inspect(params, {
      showHidden: true,
      depth: null
    }));
    if (this.timeout) {
      req.on('socket', (function(_this) {
        return function(socket) {
          socket.setTimeout(_this.timeout);
          return socket.on('timeout', function() {
            return req.abort();
          });
        };
      })(this));
    }
    req.on('response', (function(_this) {
      return function(res) {
        if (res.statusCode < 200 || res.statusCode >= 300) {
          return _this._read(res, function(err, content) {
            return callback(new Error("" + res.statusCode + " " + content), null);
          });
        }
        return callback(null, res);
      };
    })(this));
    req.on('error', (function(_this) {
      return function(err) {
        return callback(err, null);
      };
    })(this));
    return req;
  };

  Modem.prototype._read = function(res, callback) {
    var content;
    content = '';
    res.on('data', function(data) {
      return content += data;
    });
    return res.on('end', (function(_this) {
      return function() {
        var e;
        debug('Received: %s', content);
        try {
          return callback(null, JSON.parse(content));
        } catch (_error) {
          e = _error;
          return callback(null, content);
        }
      };
    })(this));
  };

  Modem.prototype._write = function(req, data) {
    if (typeof data === 'string' || Buffer.isBuffer(data)) {
      req.write(data);
      req.end();
      return;
    }
    return data.pipe(req);
  };

  Modem.prototype._connect = function(options) {
    return {
      stream: (function(_this) {
        return function(callback) {
          var req;
          req = _this._dial(options, function(err, res) {
            if (err != null) {
              return callback(err);
            }
            res.setEncoding('utf8');
            return callback(null, res);
          });
          if (options.body == null) {
            return req.end();
          }
          return _this._write(req, options.body);
        };
      })(this),
      connect: (function(_this) {
        return function(callback) {
          var req;
          req = _this._dial(options, function(err, res) {
            if (err != null) {
              return callback(err);
            }
            return callback(null, new HttpDuplex(req, res));
          });
          return req.end();
        };
      })(this),
      result: (function(_this) {
        return function(callback) {
          var req;
          req = _this._dial(options, function(err, res) {
            if (err != null) {
              return callback(err);
            }
            return _this._read(res, function(err, content) {
              if (err != null) {
                return callback(err);
              }
              return callback(null, content);
            });
          });
          if (options.body == null) {
            return req.end();
          }
          return _this._write(req, options.body);
        };
      })(this)
    };
  };

  return Modem;

})();
