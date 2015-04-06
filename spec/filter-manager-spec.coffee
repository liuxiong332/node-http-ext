
FilterManager = require '../lib/filter-manager'
assert = require 'should'
util = require 'util'
sinon = require 'sinon'

describe 'filter manager', ->

  it 'should use and apply filter handler', ->
    filter =
      filterRequest: (req, next) -> next()
      filterResponse: (req, res, next) -> next()
    sinon.spy filter, 'filterRequest'
    sinon.spy filter, 'filterResponse'

    defFilter =
      filterRequest: ->
      filterResponse: ->
    sinon.spy defFilter, 'filterRequest'
    sinon.spy defFilter, 'filterResponse'

    FilterManager.use filter
    new FilterManager(defFilter).applyRequestFilter 'req'
    filter.filterRequest.calledWith('req').should.true
    defFilter.filterRequest.calledWith('req').should.true

    new FilterManager(defFilter).applyResponseFilter 'req', 'res'
    filter.filterResponse.calledWith('req', 'res').should.true
    defFilter.filterResponse.calledWith('req', 'res').should.true
