{RetryError} = require './http-error'
url = require 'url'

module.exports =
class RedirectFilter
  constructor: (@client) ->
    @originUrl = @client.getUrl()

  setManagerScope: (@scope) ->
    @scope.redirectMap ?= {}

  filterOption: (option, requestOpts) ->
    @allowRedirects = option.allowRedirects isnt false
    if @allowRedirects
      @maxRedirects = option.maxRedirects ? 10
      @redirectCount = 0

  filterRequestOption: (requestOpts) ->
    requestUrl = @client.getUrl()
    redirectUrl = @scope.redirectMap[requestUrl]
    @client.parseUrl redirectUrl if redirectUrl

  filterResponse: (res, next) ->
    newUrl = res.headers.location
    if newUrl and @allowRedirects
      if @redirectCount++ < @maxRedirects
        newUrl = url.resolve(@client.getUrl(), newUrl)
        @client.parseUrl newUrl
        @scope.redirectMap[@originUrl] = newUrl
        throw new RetryError
      else
        throw new Error("Too many redirects (>#{@maxRedirects})")
    next()
