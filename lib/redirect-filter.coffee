{RetryError} = require './http-error'
url = require 'url'

module.exports =
class RedirectFilter
  filterOption: (option, requestOpts) ->
    @allowRedirects = option.allowRedirects isnt false
    if @allowRedirects
      @maxRedirects = option.maxRedirects ? 10
      @redirectCount = 0

  filterResponse: (res, next) ->
    if res.headers.location and @allowRedirects
      if @redirectCount++ < @maxRedirects
        originUrl = res.getClient().url
        res.getClient().parseUrl url.resolve(originUrl, res.headers.location)
        throw new RetryError
      else
        throw new Error("Too many redirects (>#{@maxRedirects})")
    next()
