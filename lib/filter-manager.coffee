_ = require 'underscore'

module.exports =
class FilterManager
  constructor: (filters...) ->
    @_handlers = []
    @use filters...

  _applyFilter: (method, defFilter) ->
    args = Array::slice.call arguments, 2
    handlers = @_handlers
    length = handlers.length
    curIndex = 0
    next = ->
      ++curIndex while curIndex < length and not handlers[curIndex][method]?
      if curIndex >= length
        return defFilter()
      h = handlers[curIndex++]
      h[method].apply h, args.concat(next)
    next()

  applyRequestFilter: (req, defFilter) ->
    filter = -> defFilter(req) if defFilter?
    @_applyFilter 'filterRequest', filter, req

  applyResponseFilter: (res, defFilter) ->
    filter = -> defFilter(res) if defFilter?
    @_applyFilter 'filterResponse', filter, res

  applyOptionFilter: (option, requestOpts, defFilter) ->
    filter = -> defFilter(option, requestOpts) if defFilter?
    @_applyFilter 'filterOption', filter, option, requestOpts

  use: (filters...) ->
    @_handlers = @_handlers.concat filters
