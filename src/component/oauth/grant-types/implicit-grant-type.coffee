'use strict'

###*
# Module dependencies.
###

Promise = require 'bluebird'

{ AbstractGrantType } = require './abstract-grant-type'

{ InvalidArgumentError } = require '../errors/invalid-argument-error'

###*
# Constructor.
###

class ImplicitGrantType extends AbstractGrantType
  constructor: (options = {}) ->
    if not options.user
      throw new InvalidArgumentError 'Missing parameter: `user`'

    @scope = options.scope
    @user = options.user

    super options

    return

  ###*
  # Handle implicit token grant.
  ###

  handle: (request, client) ->
    if not request
      throw new InvalidArgumentError 'Missing parameter: `request`'

    if not client
      throw new InvalidArgumentError 'Missing parameter: `client`'

    @saveToken @user, client, @scope

  ###*
  # Save token.
  ###

  saveToken: (user, client, scope) ->
    fns = [
      @validateScope(user, client, scope)
      @generateAccessToken()
      @getAccessTokenExpiresAt()
    ]

    Promise.all fns
      .bind @
      .spread (scope, accessToken, accessTokenExpiresAt) ->
        token =
          accessToken: accessToken
          accessTokenExpiresAt: accessTokenExpiresAt
          scope: scope

        @modelHelpers.createToken token, client, user

module.exports = ImplicitGrantType