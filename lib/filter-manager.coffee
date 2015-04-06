Mixin = require 'mixto'
_ = require 'underscore'

module.exports =
class FilterManager extends Mixin
  constructor: (handler) ->
    @_defFilter = handler

  defaultFilter: (handler) ->
    @_defFilter = handler

  _applyFilter: (method) ->
    args = Array::slice.call arguments, 1

    handlers = FilterManager._handlers
    defFilter = @_defFilter
    length = handlers.length
    curIndex = 0
    next = ->
      ++curIndex while curIndex < length and not handlers[curIndex][method]?
      if curIndex >= length
        return defFilter[method].apply defFilter, args
      h = handlers[curIndex++]
      h[method].apply h, args.concat(next)
    next()

  applyRequestFilter: (req) ->
    @_applyFilter 'filterRequest', req

  applyResponseFilter: (req, res) ->
    @_applyFilter 'filterResponse', req, res

  @_handlers = []
  @use: (handler) ->
    if _.isArray handler
      @_handlers = @_handlers.concat handler
    else
      @_handlers.push handler
