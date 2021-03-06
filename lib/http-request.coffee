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
    @filterResponse res, @operateResponse.bind(this)

  operateResponse: (res, resError) ->
    unless resError?
      @parseBody res
    else if resError instanceof RetryError
      res.on 'data', ->
      res.on 'end', =>
        process.nextTick =>
          @sendRequest()
    else
      @callback? resError

  parseBody: (res) ->
    chunks = []
    res.on 'data', (chunk) ->
      chunks.push chunk
    res.on 'end', =>
      responseBody = Buffer.concat chunks
      @callback? null, {res, body: responseBody.toString('utf8')}

  getUrl: -> @url

  _getUrlParams: (options) ->
    if @url
      params = url.parse @url
    else
      params =
        protocol: options.protocol ? 'http'
        hostname: options.host ? 'localhost'
        port: options.port, pathname: options.path ? '/'
      @url = url.format params
    params

  _parseUrlOptions: (options) ->
    @url = options.url
    @_parseUrlByParams @_getUrlParams(options)

  parseUrl: (@url) ->
    @_parseUrlByParams url.parse(@url)

  _parseUrlByParams: (params) ->
    if @proxy?
      [port, host, path] = [@proxy.port, @proxy.host, @url]
      @requestOpts.headers['HOST'] = params.hostname
      @isHttps = true if @proxy.protocol is 'https'
    else
      @isHttps = params.protocol is 'https:'
      [host, path] = [params.hostname, params.path]
      port = params.port ? if @isHttps then 443 else 80
    _.extend @requestOpts, {port, host, path}

  processOpts: (options) ->
    @proxy = options.proxy

    pickOptionList = [
      'agent', 'method', 'auth'
      'pfx', 'key', 'passphrase', 'cert', 'ca', 'ciphers'
      'rejectUnauthorized', 'secureProtocol'
    ]

    @requestOpts = requestOpts = _.pick options, pickOptionList
    headers = requestOpts.headers = {}

    @_parseUrlOptions options

    # requestOpts._defaultAgent = https.globalAgent if @isHttps

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

    if (rawBody = options.body)?
      if Buffer.isBuffer(rawBody)
        @body = rawBody
      else
        @body = new Buffer rawBody, options.encoding ? 'utf8'
      contentType = null

    headers['Content-Type'] = contentType if contentType?
    headers['Cookie'] = options.cookies.join "; " if options.cookies?
    _.extend headers, options.headers

    do =>
      filterManager = options.filter ? globalFilterManager
      @filterWorker = filterManager.getFilterWorker(this)
      @filterWorker.applyOptionFilter options, requestOpts

    @simplifyRequestOptions()

  simplifyRequestOptions: ->
    # remove headers with undefined keys and values
    headers = @requestOpts.headers
    for headerName, headerValue of headers
      delete headers[headerName] unless headerValue?

  getRequestOptions: -> @requestOpts

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

    request.on 'error', (err) =>
      err = new Error('request timeout') if requestTimeout
      @callback? err

class HttpRequest
  HttpParser.includeInto this

  constructor: (options, callback) ->
    HttpParser.apply this, arguments
    @processOpts options
    @sendRequest()

  sendRequest: ->
    @filterWorker.applyRequestOptionFilter @requestOpts
    if @isHttps
      @request = https.request @requestOpts, @requestResponse
    else
      @request = http.request @requestOpts, @requestResponse
    @initRequest @request

  initRequest: (request) ->
    request.getClient = => this
    @listenRequestEvent request

    @filterRequest request, (req, err) =>
      throw err if err?
      request.write @body if @body?
      request.end()

['get', 'post', 'delete', 'put'].forEach (method) ->
  exports[method] = (url, options = {}, callback) ->
    if typeof url isnt 'string'
      callback = options
      options = url
      url = null
    if typeof options is 'function'
      callback = options
      options = {}
    options.url = url
    options.method = method.toUpperCase()

    new HttpRequest options, callback

exports.HttpRequest = HttpRequest
