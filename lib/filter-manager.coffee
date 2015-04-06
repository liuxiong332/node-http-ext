_ = require 'underscore'

module.exports =
class FilterManager
  constructor: (filters...) ->
    @_handlers = []
    @use filters...

  _applyFilter: (method, defFilter, arg) ->
    handlers = @_handlers
    length = handlers.length
    curIndex = 0
    next = ->
      ++curIndex while curIndex < length and not handlers[curIndex][method]?
      if curIndex >= length
        return defFilter? arg
      h = handlers[curIndex++]
      h[method].call h, arg, next
    next()

  applyRequestFilter: (req, defFilter) ->
    @_applyFilter 'filterRequest', defFilter, req

  applyResponseFilter: (res, defFilter) ->
    @_applyFilter 'filterResponse', defFilter, res

  use: (filters...) ->
    @_handlers = @_handlers.concat filters
