
FilterManager = require '../lib/filter-manager'
assert = require 'should'
util = require 'util'
sinon = require 'sinon'

describe 'filter manager', ->

  it 'should use and apply filter handler', ->
    filter =
      filterReq: (req, next) -> next()
      filterRes: (req, res, next) -> next()
    sinon.spy filter, 'filterReq'
    sinon.spy filter, 'filterRes'

    defFilter =
      filterReq: ->
      filterRes: ->
    sinon.spy defFilter, 'filterReq'
    sinon.spy defFilter, 'filterRes'

    FilterManager.use filter
    new FilterManager(defFilter).applyRequestFilter 'req'
    filter.filterReq.calledWith('req').should.true
    defFilter.filterReq.calledWith('req').should.true

    new FilterManager(defFilter).applyResponseFilter 'req', 'res'
    filter.filterRes.calledWith('req', 'res').should.true
    defFilter.filterRes.calledWith('req', 'res').should.true
