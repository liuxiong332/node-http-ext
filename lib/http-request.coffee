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
{PassThrough} = require 'stream'
{RetryError} = require './http-error'
RedirectFilter = require './redirect-filter'

exports.FilterManager = require './filter-manager'
exports.RetryError = RetryError

exports.globalFilterManager = globalFilterManager =
  new exports.FilterManager RedirectFilter

class HttpParser extends Mixin
  constructor: (options, callback) ->
    @callback = callback

  requestResponse: (res) =>
    isEnd = false
    res.on 'end', (err) -> isEnd = true
    res.on 'close', => @callback? new Error('Request aborted!') unless isEnd
    res.on 'error', (err) => @callback? err

    res.getClient = => this
    res.stream = new PassThrough
    res.getOutStream = -> this.stream
    res.pipe res.stream

    @filterResponse res, @operateResponse.bind(this)

  operateResponse: (res, resError) ->
    if resError instanceof RetryError
      if @requestMode is 'stream'
        @sendRequest()
        @callback? resError, @getInputStream()
      else
        @sendRequest()
    else if resError?
      @callback? resError
    else if @responseMode is 'stream'
      @callback? null, res
    else
      @parseBody res

  parseBody: (res) ->
    chunks = []
    res.stream.on 'data', (chunk) ->
      chunks.push chunk
    res.stream.on 'end', (err) =>
      responseBody = Buffer.concat chunks
      @callback? null, {res, body: responseBody.toString('utf8')}

  parseUrl: (requestUrl) ->
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
    @responseMode = options.responseMode
    @requestMode = options.requestMode

    @proxy = options.proxy

    pickOptionList = [
      'agent', 'method', 'auth'
      'pfx', 'key', 'passphrase', 'cert', 'ca', 'ciphers'
      'rejectUnauthorized', 'secureProtocol'
    ]

    @requestOpts = requestOpts = _.pick options, pickOptionList
    @parseUrl options.url
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

    do =>
      filterManager = options.filter ? globalFilterManager
      @filterWorker = filterManager.getFilterWorker()
      @filterWorker.applyOptionFilter options, requestOpts

    # remove headers with undefined keys and values
    for headerName, headerValue of headers
      delete headers[headerName] unless headerValue?

  filterRequest: (request, callback) ->
    @filterWorker.applyRequestFilter request, callback

  filterResponse: (response, callback) ->
    @filterWorker.applyResponseFilter response, callback

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
    @request = request = new http.ClientRequest @requestOpts, @requestResponse
    @initRequest request

  getInputStream: -> @request.stream

  initRequest: (request) ->
    request.getClient = => this
    request.stream = new PassThrough

    # request Mode is normal, write body into stream
    unless @requestMode is 'stream'
      if @bodyStream?
        @bodyStream.pipe request.stream
      else
        request.stream.write @body if @body?
        request.stream.end()

    @listenRequestEvent request
    @filterRequest request, ->
      request.stream.pipe request

['get', 'post', 'delete', 'put'].forEach (method) ->
  exports[method] = (url, options = {}, callback) ->
    if typeof options is 'function'
      callback = options
      options = {}
    options.url = url
    options.method = method.toUpperCase()

    client = new HttpRequest options, callback
    if options.requestMode is 'stream'
      client.getInputStream()
