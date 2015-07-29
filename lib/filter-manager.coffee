_ = require 'underscore'

class FilterWorker
  constructor: (client, filterConstructors) ->
    @_handlers = filterConstructors.map (handler) ->
      filter = new handler[0](client, handler[2..])
      filter.setManagerScope? handler[1]
      filter

  getFilters: -> @_handlers

  _applyFilter: (method, defFilter) ->
    args = Array::slice.call arguments, 2
    handlers = @_handlers
    length = handlers.length
    curIndex = 0
    isFinish = false
    next = ->
      return if isFinish
      ++curIndex while curIndex < length and not handlers[curIndex][method]?
      if curIndex >= length
        return defFilter()
      h = handlers[curIndex++]
      try
        h[method].apply h, args.concat(next)
      catch err
        isFinish = true
        defFilter err
    next.retry = ->
      isFinish = true
      defFilter new RetryError()
    next()

  applyRequestFilter: (req, defFilter) ->
    filter = (err) -> defFilter(req, err) if defFilter?
    @_applyFilter 'filterRequest', filter, req

  applyResponseFilter: (res, defFilter) ->
    filter = (err) -> defFilter(res, err) if defFilter?
    @_applyFilter 'filterResponse', filter, res

  applyOptionFilter: (option, requestOpts) ->
    for handler in @_handlers
      handler.filterOption option, requestOpts if handler.filterOption?

  applyRequestOptionFilter: (requestOpts) ->
    for handler in @_handlers
      handler.filterRequestOption requestOpts if handler.filterRequestOption?

module.exports =
class FilterManager
  constructor: (filters...) ->
    @_handlers = []
    @use filters...

  getFilterWorker: (client) ->
    new FilterWorker client, @_handlers

  use: (filters...) ->
    @_handlers = @_handlers.concat filters.map (filter) ->
      # add managerScope for each filter
      if _.isArray filter
        filter.splice 1, 0, {}
        filter
      else
        [filter, {}]
