'use strict'

###*
# Module dependencies.
###

{ InvalidArgumentError } = require '../errors/invalid-argument-error'

ImplicitGrantType = require '../grant-types/implicit-grant-type'
Promise = require 'bluebird'

###*
# Constructor.
###

class TokenResponseType
  constructor: ({ @accessTokenLifetime, @modelHelpers }) ->
    if not @accessTokenLifetime
      throw new InvalidArgumentError 'Missing parameter: `accessTokenLifetime`'

    @accessToken = null

    return

  ###*
  # Handle token response type.
  ###

  handle: (request, client, user, uri, scope) ->
    if not request
      throw new InvalidArgumentError 'Missing parameter: `request`'

    if not client
      throw new InvalidArgumentError 'Missing parameter: `client`'

    accessTokenLifetime = @getAccessTokenLifetime client

    options =
      user: user
      scope: scope
      modelHelpers: @modelHelpers
      accessTokenLifetime: accessTokenLifetime

    grantType = new ImplicitGrantType options

    Promise.bind @
      .then ->
        grantType.handle request, client
      .then (token) ->
        @accessToken = token.accessToken
        token

  ###*
  # Get access token lifetime.
  ###

  getAccessTokenLifetime: (client) ->
    client.accessTokenLifetime or @accessTokenLifetime

  ###*
  # Build redirect uri.
  ###

  buildRedirectUri: (redirectUri) ->
    @setRedirectUriParam redirectUri, 'access_token', @accessToken

  ###*
  # Set redirect uri parameter.
  ###

  setRedirectUriParam: (redirectUri, key, value) ->
    if not redirectUri
      throw new InvalidArgumentError 'Missing parameter: `redirectUri`'

    if not key
      throw new InvalidArgumentError 'Missing parameter: `key`'

    redirectUri.hash = redirectUri.hash or ''
    redirectUri.hash += (if redirectUri.hash then '&' else '') + key + '=' + encodeURIComponent(value)
    redirectUri

module.exports = TokenResponseType