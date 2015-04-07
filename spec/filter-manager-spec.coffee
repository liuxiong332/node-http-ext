
FilterManager = require '../lib/filter-manager'
assert = require 'should'
util = require 'util'
sinon = require 'sinon'

describe 'filter manager', ->

  it 'should use and apply filter handler', ->
    class Filter
      filterRequest: (req, next) -> next()
      filterResponse: (res, next) -> next()
    manager = new FilterManager(Filter)
    filterWorker = manager.getFilterWorker()
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
