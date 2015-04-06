###
 node-http-request
 https://github.com/liuxiong332/node-http-request

 Copyright (c) 2015 liuxiong
 Licensed under the MIT license.
###

http = require 'http'
https = require 'https'
url = require 'url'
_ = require 'underscore'
query = require 'querystring'
Mixin = require 'mixto'
exports.FilterManager = require 'filter-manager'

class HttpParser extends Mixin
  constructor: (options, callback) ->
    @callback = callback

  requestResponse: (res) =>
    return @callback? res if @responseMode is 'stream'
    chunks = []
    isEnd = false

    res.on 'data', (chunk) ->
      chunks.push chunk

    res.on 'end', (err) =>
      isEnd = true
      if res.headers.location and @allowRedirects
        if @redirectCount++ < @maxRedirects
          @processUrl url.resolve(@url, res.headers.location)
          @sendRequest()
        else
          @callback? new Error("Too many redirects (>#{@maxRedirects})")
      else
        responseBody = Buffer.concat chunks

        @callback? null, {res, body: responseBody.toString('utf8')}

    res.on 'close', =>
      @callback? new Error('Request aborted!') unless isEnd

  processUrl: (requestUrl) ->
    @url = requestUrl
    if @proxy?
      [port, host, path] = [@proxy.port, @proxy.host, requestUrl]
      @isHttps = true if @proxy.protocol is 'https'
    else
      reqUrl = url.parse requestUrl
      @isHttps = reqUrl.protocol is 'https:'
      [host, path] = [reqUrl.hostname, reqUrl.path]
      port = reqUrl.port ? if @isHttps then 443 else 80
    _.extend @requestOpts, {port, host, path}

  processOpts: (options) ->
    @responseMode = options.responseMode ? 'normal'
    @allowRedirects = options.allowRedirects isnt false
    if @allowRedirects
      @maxRedirects = options.maxRedirects ? 10
      @redirectCount = 0

    @proxy = options.proxy

    @requestOpts = requestOpts = {method: options.method}
    @processUrl options.url
    requestOpts._defaultAgent = https.globalAgent if @isHttps

    if options.parameters
      params = query.stringify options.parameters
      if options.method is 'GET'
        @requestOpts.path += "?#{params}"
      else
        @body = new Buffer params, 'utf8'
        contentType = 'application/x-www-form-urlencoded; charset=UTF-8'

    if options.json
      @body = new Buffer JSON.stringify(options.json), 'utf8'
      contentType = 'application/json'

    if options.body
      @body = new Buffer options.body, 'utf8'
      contentType = null

    requestOpts.headers = headers = {}
    headers['Content-Length'] = @body.length if @body?
    headers['Content-Type'] = contentType if contentType?
    headers['Cookie'] = options.cookies.join "; " if options.cookies?
    _.extend headers, options.headers

    if @isHttps and options.rejectUnauthorized?
      requestOpts.rejectUnauthorized = options.rejectUnauthorized
    requestOpts.agent = options.agent if options.agent?

    # remove headers with undefined keys and values
    for headerName, headerValue of headers
      delete headers[headerName] unless headerValue?

  listenRequestEvent: (request) ->
    requestTimeout = false
    if @requestOpts.timeout?
      request.setTimeout @requestOpts.timeout, ->
        requestTimeout = true
        request.abort()

    request.on 'error', (err) ->
      err = new Error('request timeout') if requestTimeout
      @callback? err

class HttpRequest
  HttpParser.includeInto this

  constructor: (options, callback) ->
    HttpParser.apply this, arguments
    @processOpts options
    @sendRequest()

  sendRequest: ->
    request = new http.ClientRequest @requestOpts, @requestResponse
    @listenRequestEvent request
    request.write @body if @body?
    request.end()

class HttpStreamRequest extends http.ClientRequest
  HttpParser.includeInto this

  constructor: (options, callback) ->
    HttpParser.apply this, arguments
    @processOpts options
    super @requestOpts, @requestResponse
    @listenRequestEvent this

['get', 'post', 'delete', 'put'].forEach (method) ->
  exports[method] = (url, options = {}, callback) ->
    if typeof options is 'function'
      callback = options
      options = {}
    options.url = url
    options.method = method.toUpperCase()
    if options.requestMode is 'stream'
      new HttpStreamRequest options, callback
    else
      new HttpRequest options, callback
