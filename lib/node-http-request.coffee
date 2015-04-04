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

class HttpRequest
  constructor: (options, callback) ->
    @callback = callback
    @processOpts options
    @sendRequest()

  sendRequest: ->
    requestResponse = (res) ->
      chunks = [], isEnd = false
      res.on 'data', (chunk) ->
        chunks.push chunk

      res.on 'end', (err) =>
        isEnd = true
        if res.headers.location and @allowRedirects
          if @redirectCount++ < @maxRedirects
            @processUrl(res.headers.location) and @sendRequest()
          else
            return @callback? new Error("Too many redirects (>#{@maxRedirects})")
        else
          responseBody = Buffer.concat chunks
          @callback? null, {headers: res.headers, statusCode: res.statusCode,
            body: responseBody.toString('utf8')}

      res.on 'close', ->
        @callback? new Error('Request aborted!') unless isEnd

    if @isHttps
      request = https.request @requestOpts, requestResponse
    else
      request = http.request @requestOpts, requestResponse

    if @requestOpts.timeout?
      request.setTimeout options.timeout, ->
        requestTimeout = true
        request.abort()

    request.on 'error', (err) ->
      err = new Error('request timeout') if requestTimeout
      @callback? err

    request.write body if body?
    request.end()

  processUrl: (url) ->
    if @proxy?
      [port, host, path] = [@proxy.port, @proxy.host, url]
      @isHttps = true if @proxy.protocol is 'https'
    else
      reqUrl = url.parse url
      @isHttps = reqUrl.protocol is 'https:'
      [host, path] = [reqUrl.hostname, reqUrl.path]
      port = reqUrl.port ? if @isHttps then 443 else 80
    _.extend @requestOpts, {port, host, path}

  processOpts: (options) ->
    @allowRedirects = options.allowRedirects isnt false
    if @allowRedirects
      @maxRedirects = options.maxRedirects ? 10
      @redirectCount = 0

    @proxy = options.proxy

    if options.parameters
      params = query.stringify options.parameters
      if options.method is 'GET'
        path += "?#{params}"
      else
        body = new Buffer params, 'utf8'
        contentType = 'application/x-www-form-urlencoded; charset=UTF-8'

    if options.json
      body = new Buffer JSON.stringify(options.json), 'utf8'
      contentType = 'application/json'

    if options.body
      body = new Buffer options.body, 'utf8'
      contentType = null

    @requestOpts = requestOpts = {method: options.method}
    @processUrl options.url

    requestOpts.headers = headers = {}
    headers['Content-Length'] = body.length if body?
    headers['Content-Type'] = contentType if contentType?
    headers['Cookie'] = options.cookies.join "; " if options.cookies?
    _.extend headers, options.headers

    if @isHttps and options.rejectUnauthorized?
      requestOpts.rejectUnauthorized = options.rejectUnauthorized
    requestOpts.agent = options.agent if options.agent?

    # remove headers with undefined keys and values
    for headerName, headerValue of headers
      delete headers[headerName] unless headerValue?

exports.get = (url, options = {}, callback) ->
  if typeof options is 'function'
    callback = options
    options = {}
  options.url = url
  options.method = 'GET'

  doRequest options, callback

exports.post = (url, options = {}, callback) ->
  if typeof options is 'function'
    callback = options
    options = {}

  options.url = url
  options.method = 'POST'

  doRequest options, callback
