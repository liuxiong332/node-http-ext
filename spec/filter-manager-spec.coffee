
FilterManager = require '../lib/filter-manager'
assert = require 'should'
util = require 'util'
sinon = require 'sinon'

describe 'filter manager', ->
  class Filter
    filterRequest: (req, next) -> next()
    filterResponse: (res, next) -> next()
    setManagerScope: (@scope) ->

  it 'should use and apply filter handler', ->
    manager = new FilterManager(Filter)
    client =
      getUrl: -> 'url'
    filterWorker = manager.getFilterWorker(client)
    filterWorker.getFilters().length.should.equal 1
    filter = filterWorker.getFilters()[0]
    sinon.spy filter, 'filterRequest'
    sinon.spy filter, 'filterResponse'

    defReqFilter = sinon.spy()
    defResFilter = sinon.spy()

    filterWorker.applyRequestFilter 'req', defReqFilter
    filter.filterRequest.calledWith('req').should.true
    defReqFilter.calledWith('req').should.true

    filterWorker.applyResponseFilter 'res', defResFilter
    filter.filterResponse.calledWith('res').should.true
    defResFilter.calledWith('res').should.true

  it 'manager scope is valid', ->
    manager = new FilterManager Filter
    work1 = manager.getFilterWorker()
    work1.getFilters()[0].scope['hello'] = 'world'

    work2 = manager.getFilterWorker()
    work2.getFilters()[0].scope['hello'].should.eql 'world'
