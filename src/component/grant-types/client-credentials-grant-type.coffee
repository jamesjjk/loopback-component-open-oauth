###*
# Module dependencies.
###

Promise = require 'bluebird'

{ AbstractGrantType } = require './abstract-grant-type'

{ InvalidArgumentError } = require '../errors/invalid-argument-error'
{ InvalidGrantError } = require '../errors/invalid-grant-error'

###*
# Constructor.
###

class ClientCredentialsGrantType extends AbstractGrantType
  constructor: (options = {}) ->
    super options

    return

  ###*
  # Handle client credentials grant.
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.4.2
  ###

  handle: (request, client) ->
    if !request
      throw new InvalidArgumentError 'REQUEST'

    if !client
      throw new InvalidArgumentError 'CLIENT'

    scope = @getScope(request)

    Promise.bind this
      .then ->
        @getUserFromClient client
      .then (user) ->
        @saveToken user, client, scope

  getUserFromClient = (client) ->
    @modelHelpers.getUserFromClient client
      .then (user) ->
        if !user
          throw new InvalidGrantError 'Invalid grant: user credentials are invalid'
        user

  ###*
  # Save token.
  ###

  saveToken: (user, client, scope) ->
    fns = [
      @generateAccessToken()
      @getAccessTokenExpiresAt()
    ]

    Promise.all fns
      .bind this
      .spread (accessToken, accessTokenExpiresAt) ->
        token =
          accessToken: accessToken
          accessTokenExpiresAt: accessTokenExpiresAt
          scope: scope

        @modelHelpers.createToken token, client, user

module.exports = ClientCredentialsGrantType