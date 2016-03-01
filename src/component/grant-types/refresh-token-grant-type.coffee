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

###*
# Constructor.
###

class RefreshTokenGrantType extends AbstractGrantType
  constructor: (options = {}) ->
    super options

    return

  ###*
  # Handle refresh token grant.
  #
  # @see https://tools.ietf.org/html/rfc6749#section-6
  ###

  handle: (request, client) ->
    if not request
      throw new InvalidArgumentError 'REQUEST'

    if not client
      throw new InvalidArgumentError 'CLIENT'

    Promise.bind this
      .then ->
        @getRefreshToken request, client
      .tap (token) ->
        @revokeRefreshToken token
      .then (token) ->
        @saveToken token.user, client, token.scope

  ###*
  # Revoke the refresh token.
  #
  # "The refresh token MUST expire shortly after it is issued to mitigate
  # the risk of leaks. [...] If an refresh token is used more than once,
  # the authorization server MUST deny the request."
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.1.2
  ###

  revokeRefreshToken: (refreshToken) ->
    @modelHelpers.revokeRefreshToken refreshToken
      .then (code) ->
        if not code
          throw new InvalidGrantError 'Invalid grant: refresh token is invalid'

        if not code.expiresAt instanceof Date
          throw new ServerError 'Server error: `expiresAt` must be a Date instance'

        if code.expiresAt >= new Date
          throw new ServerError 'Server error: refresh token should be expired'

        code
  ###*
  # Save token.
  ###

  saveToken: (user, client, scope) ->
    fns = [
      @generateAccessToken()
      @generateRefreshToken()
      @getAccessTokenExpiresAt()
      @getRefreshTokenExpiresAt()
    ]

    Promise.all fns
      .bind this
      .spread (accessToken, refreshToken, accessTokenExpiresAt, refreshTokenExpiresAt) ->
        token =
          accessToken: accessToken
          accessTokenExpiresAt: accessTokenExpiresAt
          refreshToken: refreshToken
          refreshTokenExpiresAt: refreshTokenExpiresAt
          scope: scope

        @modelHelpers.createToken token, client, user

module.exports = RefreshTokenGrantType