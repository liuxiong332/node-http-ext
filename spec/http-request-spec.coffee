
request = require '../lib/http-request'
express = require 'express'
http = require 'http'
assert = require 'should'
util = require 'util'

describe 'nodeHttpRequest', ->
  server = null
  beforeEach (done) ->
    app = express()
    server = http.createServer(app).listen 8080, -> done()

  afterEach (done) ->
    server.close -> done()

  it 'should be awesome', (done) ->
    request.get 'http://localhost:8080', (err, {res, body}) ->
      util.log res.statusCode
      done()
