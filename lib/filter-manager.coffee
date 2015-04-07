_ = require 'underscore'

class FilterWorker
  constructor: (filterConstructors) ->
    @_handlers = filterConstructors.map (constructor) -> new constructor

  getFilters: -> @_handlers

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
      try
        h[method].apply h, args.concat(next)
      catch err
        defFilter err
    next()

  applyRequestFilter: (req, defFilter) ->
    filter = (err) -> defFilter(req, err) if defFilter?
    @_applyFilter 'filterRequest', filter, req

  applyResponseFilter: (res, defFilter) ->
    filter = (err) -> defFilter(res, err) if defFilter?
    @_applyFilter 'filterResponse', filter, res

  applyOptionFilter: (option, requestOpts, defFilter) ->
    filter = -> defFilter(option, requestOpts) if defFilter?
    @_applyFilter 'filterOption', filter, option, requestOpts

module.exports =
class FilterManager
  constructor: (filters...) ->
    @_handlers = []
    @use filters...

  getFilterWorker: ->
    new FilterWorker @_handlers

  use: (filters...) ->
    @_handlers = @_handlers.concat filters
