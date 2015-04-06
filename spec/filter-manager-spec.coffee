
FilterManager = require '../lib/filter-manager'
assert = require 'should'
util = require 'util'
sinon = require 'sinon'

describe 'filter manager', ->

  it 'should use and apply filter handler', ->
    filter =
      filterRequest: (req, next) -> next()
      filterResponse: (res, next) -> next()
    sinon.spy filter, 'filterRequest'
    sinon.spy filter, 'filterResponse'

    defReqFilter = sinon.spy()
    defResFilter = sinon.spy()

    new FilterManager(filter).applyRequestFilter 'req', defReqFilter
    filter.filterRequest.calledWith('req').should.true
    defReqFilter.calledWith('req').should.true

    new FilterManager(filter).applyResponseFilter 'res', defResFilter
    filter.filterResponse.calledWith('res').should.true
    defResFilter.calledWith('res').should.true
