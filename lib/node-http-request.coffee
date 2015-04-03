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
    callback ?= ->
    options.maxRedirects ?= 10

    if options.proxy?
      proxy = options.proxy
      [port, host, path] = [proxy.port, proxy.host, options.url]
      isHttps = true if proxy.protocol is 'https'
    else
      reqUrl = url.parse options.url
      isHttps = reqUrl.protocol is 'https:'
      [host, path] = [reqUrl.hostname, reqUrl.path]
      port = reqUrl.port ? if isHttps then 443 else 80

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

    requestOpts = {host, port, path, method: options.method}
    requestOpts.headers = headers = {}
    headers['Content-Length'] = body.length if body?
    headers['Content-Type'] = contentType if contentType?
    headers['Cookie'] = options.cookies.join "; " if options.cookies?
    _.extend headers, options.headers

    if isHttps and options.rejectUnauthorized?
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
  options.allowRedirects ?= true

  doRequest options, callback

exports.post = (url, options = {}, callback) ->
  if typeof options is 'function'
    callback = options
    options = {}
  options.url = url
  options.method = 'POST'

  doRequest options, callback

module.exports = ->
  'awesome'
