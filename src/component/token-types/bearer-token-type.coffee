###*
# Module dependencies.
###

{ AbstractTokenType } = require './abstract-token-type'

{ InvalidArgumentError } = require '../errors/invalid-argument-error'
{ InvalidRequestError } = require '../errors/invalid-request-error'

###*
# Retrieve the value representation.
###

class BearerTokenType extends AbstractTokenType
  constructor: (data = {}) ->
    super data

    if not @accessToken
      throw new InvalidArgumentError 'ACCESSTOKEN'

    return

  valueOf: ->
    object =
      access_token: @accessToken
      token_type: 'bearer'

    if @accessTokenLifetime
      object.expires_in = @accessTokenLifetime

    if @refreshToken
      object.refresh_token = @refreshToken

    if @scope
      object.scope = @scope

    object

  @getTokenFromRequest: (request) ->
    headerToken = request.get 'Authorization'
    queryToken = request.query.access_token
    bodyToken = request.body.access_token

    if ! !headerToken + ! !queryToken + ! !bodyToken > 1
      return

    if headerToken
      return @getTokenFromRequestHeader request

    if queryToken
      return @getTokenFromRequestQuery request

    if bodyToken
      return @getTokenFromRequestBody request

    return

  ###*
  # Get the token from the request header.
  #
  # @see http://tools.ietf.org/html/rfc6750#section-2.1
  ###

  @getTokenFromRequestHeader: (request) ->
    token = request.get 'Authorization'
    matches = token.match /Bearer\s(\S+)/

    if not matches
      return

    matches[1]

  ###*
  # Get the token from the request query.
  #
  # "Don't pass bearer tokens in page URLs:  Bearer tokens SHOULD NOT be passed in page
  # URLs (for example, as query string parameters). Instead, bearer tokens SHOULD be
  # passed in HTTP message headers or message bodies for which confidentiality measures
  # are taken. Browsers, web servers, and other software may not adequately secure URLs
  # in the browser history, web server logs, and other data structures. If bearer tokens
  # are passed in page URLs, attackers might be able to steal them from the history data,
  # logs, or other unsecured locations."
  #
  # @see http://tools.ietf.org/html/rfc6750#section-2.3
  ###

  @getTokenFromRequestQuery: (request) ->
    request.query.access_token

  ###*
  # Get the token from the request body.
  #
  # "The HTTP request method is one for which the request-body has defined semantics.
  # In particular, this means that the "GET" method MUST NOT be used."
  #
  # @see http://tools.ietf.org/html/rfc6750#section-2.2
  ###

  @getTokenFromRequestBody: (request) ->
    if request.method is 'GET'
      throw new InvalidRequestError 'GETBODY'

    if not request.is 'application/x-www-form-urlencoded'
      throw new InvalidRequestError 'FORMENCODED'

    request.body.access_token

module.exports = BearerTokenType