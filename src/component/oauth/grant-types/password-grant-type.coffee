###*
# Module dependencies.
###

Promise = require 'bluebird'
validate = require '../validator/is'

{ AbstractGrantType } = require './abstract-grant-type'

{ InvalidArgumentError } = require '../errors/invalid-argument-error'
{ InvalidGrantError } = require '../errors/invalid-grant-error'
{ InvalidRequestError } = require '../errors/invalid-request-error'

###*
# Constructor.
###

class PasswordGrantType extends AbstractGrantType
  constructor: (options = {}) ->
    super options

    return

  ###*
  # Retrieve the user from the model using a username/password combination.
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.3.2
  ###

  handle: (request, client) ->
    if !request
      throw new InvalidArgumentError 'REQUEST'

    if !client
      throw new InvalidArgumentError 'CLIENT'

    scope = @getScope(request)

    Promise.bind this
      .then ->
        @getUser request
      .then (user) ->
        @saveToken user, client, scope

  getUser: (request) ->
    { username, password } = request.body

    if not username
      throw new InvalidRequestError 'Missing parameter: `username`'

    if not password
      throw new InvalidRequestError 'Missing parameter: `password`'

    if not validate.uchar username
      throw new InvalidRequestError 'Invalid parameter: `username`'

    if not validate.uchar password
      throw new InvalidRequestError 'Invalid parameter: `password`'

    @modelHelpers.getUser request
      .then (user) ->
        if not user
          throw new InvalidGrantError 'Invalid grant: user credentials are invalid'
        user

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

module.exports = PasswordGrantType