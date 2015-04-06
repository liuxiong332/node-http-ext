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
        return defFilter?[method].apply defFilter, args
      h = handlers[curIndex++]
      h[method].apply h, args.concat(next)
    next()

  applyRequestFilter: (defFilter, req) ->
    @_applyFilter 'filterRequest', defFilter, req

  applyResponseFilter: (defFilter, req, res) ->
    @_applyFilter 'filterResponse', defFilter, req, res

  use: (filters...) ->
    @_handlers = @_handlers.concat filters
