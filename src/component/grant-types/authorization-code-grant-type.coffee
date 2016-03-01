###*
# Module dependencies.
###

Promise = require 'bluebird'
validate = require '../validator/is'

{ AbstractGrantType } = require './abstract-grant-type'

{ InvalidArgumentError } = require '../errors/invalid-argument-error'
{ InvalidGrantError } = require '../errors/invalid-grant-error'
{ InvalidRequestError } = require '../errors/invalid-request-error'

{ ServerError } = require '../errors/server-error'

ModelHelpers = require '../helpers'

###*
# Constructor.
###

class AuthorizationCodeGrantType extends AbstractGrantType
  constructor: (options = {}) ->
    super options

    return

  ###*
  # Handle authorization code grant.
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.1.3
  ###

  handle: (request, client) ->
    if !request
      throw new InvalidArgumentError 'REQUEST'

    if !client
      throw new InvalidArgumentError 'CLIENT'

    Promise.bind this
      .then ->
        @getAuthorizationCode request, client
      .tap (code) ->
        @validateRedirectUri request, code
      .tap (code) ->
        @revokeAuthorizationCode code
      .then (code) ->
        @saveToken code.user, client, code.authorizationCode, code.scope

  ###*
  # Get the authorization code.
  ###

  getAuthorizationCode: (request, client) ->
    if !request.body.code
      throw new InvalidRequestError 'Missing parameter: `code`'

    if !validate.vschar(request.body.code)
      throw new InvalidRequestError 'Invalid parameter: `code`'

    ModelHelpers.getAuthorizationCode request.body.code
      .then (code) ->
        if !code
          throw new InvalidGrantError 'Invalid grant: authorization code is invalid'

        if !code.client
          throw new ServerError 'Server error: `getAuthorizationCode()` did not return a `client` object'

        if !code.user
          throw new ServerError 'Server error: `getAuthorizationCode()` did not return a `user` object'

        if code.client.id != client.id
          throw new InvalidGrantError 'Invalid grant: authorization code is invalid'

        if !(code.expiresAt instanceof Date)
          throw new ServerError 'Server error: `expiresAt` must be a Date instance'

        if code.expiresAt < new Date
          throw new InvalidGrantError 'Invalid grant: authorization code has expired'

        if code.redirectUri and !validate.uri(code.redirectUri)
          throw new InvalidGrantError 'Invalid grant: `redirect_uri` is not a valid URI'

        code

  ###*
  # Validate the redirect URI.
  #
  # "The authorization server MUST ensure that the redirect_uri parameter is
  # present if the redirect_uri parameter was included in the initial
  # authorization request as described in Section 4.1.1, and if included
  # ensure that their values are identical."
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.1.3
  ###

  validateRedirectUri: (request, code) ->
    if !code.redirectUri
      return

    redirectUri = request.body.redirect_uri or request.query.redirect_uri

    if !validate.uri(redirectUri)
      throw new InvalidRequestError 'Invalid request: `redirect_uri` is not a valid URI'

    if redirectUri != code.redirectUri
      throw new InvalidRequestError 'Invalid request: `redirect_uri` is invalid'

    return

  ###*
  # Revoke the authorization code.
  #
  # "The authorization code MUST expire shortly after it is issued to mitigate
  # the risk of leaks. [...] If an authorization code is used more than once,
  # the authorization server MUST deny the request."
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.1.2
  ###

  revokeAuthorizationCode: (authCode) ->
    ModelHelpers.revokeAuthorizationCode authCode
      .then (code) ->
        if !code
          throw new InvalidGrantError 'Invalid grant: authorization code is invalid'

        if !(code.expiresAt instanceof Date)
          throw new ServerError 'Server error: `expiresAt` must be a Date instance'

        if code.expiresAt >= new Date
          throw new ServerError 'Server error: authorization code should be expired'

        code

  ###*
  # Save token.
  ###

  saveToken: (user, client, authorizationCode, scope) ->
    fns = [
      @generateAccessToken()
      @generateRefreshToken()
    ]

    Promise.all fns
      .bind this
      .spread (accessToken, refreshToken) ->
        token =
          accessToken: accessToken
          authorizationCode: authorizationCode
          refreshToken: refreshToken
          scope: scope

        ModelHelpers.createToken token, client, user

module.exports = AuthorizationCodeGrantType