
request = require '../lib/http-request'
express = require 'express'
http = require 'http'
assert = require 'should'
util = require 'util'
bodyParser = require 'body-parser'
q = require 'q'

describe 'http ext', ->
  server = null
  beforeEach (done) ->
    app = express()
    app.use (req, res, next) ->
      req.headers['content-type'] ?= 'text/plain'
      next()
    app.use bodyParser.urlencoded extended: false
    app.use bodyParser.text()
    app.use bodyParser.json()

    app.get '/', (req, res) -> res.send 'Index'
    app.get '/parameter', (req, res) ->
      res.send JSON.stringify(req.query)
    app.get '/redirect', (req, res) -> res.redirect '/'
    app.post '/echo', (req, res) ->
      res.send req.body
    server = http.createServer(app).listen 8080, -> done()

  afterEach (done) ->
    server.close -> done()

  describe 'HttpRequest', ->

    it 'should request index content', (done) ->
      request.get 'http://localhost:8080/', (err, {res, body}) ->
        body.should.eql 'Index'
        done()

    it 'get with parameter', (done) ->
      reqUrl = 'http://localhost:8080/parameter'
      request.get reqUrl, {parameters: {opt: 'hello'}}, (err, {body}) ->
        JSON.parse(body).should.eql {opt: 'hello'}
        done()

    it 'post with parameter', (done) ->
      reqUrl = 'http://localhost:8080/echo'
      request.post reqUrl, {parameters: {opt: 'hello'}}, (err, {body}) ->
        JSON.parse(body).should.eql {opt: 'hello'}
        done()

    it 'post with json', (done) ->
      reqUrl = 'http://localhost:8080/echo'
      request.post reqUrl, {json: {opt: 'hello'}}, (err, {body}) ->
        JSON.parse(body).should.eql {opt: 'hello'}
        done()

    it 'post with body', (done) ->
      reqUrl = 'http://localhost:8080/echo'
      body = JSON.stringify {opt: 'hello'}
      request.post reqUrl, {body}, (err, {body}) ->
        JSON.parse(body).should.eql {opt: 'hello'}
        done()

    # it 'get with redirect', (done) ->
    #   request.get 'http://localhost:8080/redirect', (err, {body}) ->
    #     body.should.eql 'Index'
    #     done()
    #
    it 'get with responseModel is stream', (done) ->
      request.get 'http://localhost:8080/', {responseMode: 'stream'}, (err, res) ->
        res.on 'data', (data) -> data.toString('utf8').should.eql 'Index'
        res.on 'end', -> done()

  describe 'HttpStreamRequest', ->

    it 'get index', (done) ->
      reqUrl = 'http://localhost:8080/'
      req = request.get reqUrl, {requestMode: 'stream'}, (err, {body}) ->
        body.should.eql 'Index'
        done()
      req.end()

    it 'post with data', (done) ->
      reqUrl = 'http://localhost:8080/echo'
      req = request.post reqUrl, {requestMode: 'stream'}, (res, {body}) ->
        JSON.parse(body).should.eql {opt: 'hello'}
        done()
      req.end JSON.stringify({opt: 'hello'})

    it 'test http benchmark', (done) ->
      begin = Date.now()
      promises = [1..100].map ->
        defer = q.defer()
        http.get 'http://localhost:8080/', (res) ->
          defer.resolve()
        defer.promise
      q.all(promises).then ->
        end = Date.now()
        util.log "http spend #{end - begin}ms"
        done()

    it 'test request benchmark', (done) ->
      begin = Date.now()
      promises = [1..100].map ->
        defer = q.defer()
        request.get 'http://localhost:8080/', ->
          defer.resolve()
        defer.promise
      q.all(promises).then ->
        end = Date.now()
        util.log "request spend #{end - begin}ms"
        done()
