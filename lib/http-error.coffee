
class RetryError extends Error
  constructor: (@message) ->
    @name = 'RetryError'
    Error.captureStackTrace(this, @constructor)

module.exports = {RetryError}
