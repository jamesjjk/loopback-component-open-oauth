###*
# Module dependencies.
###

{ parse } = require 'url'
{ InvalidArgumentError } = require '../errors/invalid-argument-error'

###*
# Build redirect uri.
###

class CodeResponseType
  constructor: (@code) ->
    if not @code
      throw new InvalidArgumentError 'CODE'

    return

  buildRedirectUri: (redirectUri) ->
    if not redirectUri
      throw new InvalidArgumentError 'REDIRECT'

    uri = parse redirectUri, true
    uri.query.code = @code
    uri.search = null
    uri

module.exports = CodeResponseType