'use strict'

###*
# Module dependencies.
###

Promise = require 'bluebird'

{ InvalidArgumentError } = require '../errors/invalid-argument-error'

###*
# Constructor.
###

class CodeResponseType
  constructor: ({ @authorizationCodeLifetime, @modelHelpers }) ->
    @code = null

    return

  ###*
  # Handle code response type.
  ###

  handle: (request, client, user, uri, scope) ->
    if not request
      throw new InvalidArgumentError 'Missing parameter: `request`'

    if not client
      throw new InvalidArgumentError 'Missing parameter: `client`'

    if not user
      throw new InvalidArgumentError 'Missing parameter: `user`'

    if not uri
      throw new InvalidArgumentError 'Missing parameter: `uri`'

    fns = [
      @generateAuthorizationCode()
      @getAuthorizationCodeExpiresAt(client)
    ]

    Promise.all fns
      .bind @
      .spread (authorizationCode, expiresAt) ->
        @saveAuthorizationCode authorizationCode, expiresAt, scope, client, uri, user
      .then (code) ->
        @code = code.authorizationCode
        code

  ###*
  # Get authorization code expiration date.
  ###

  getAuthorizationCodeExpiresAt: (client) ->
    expires = new Date
    authorizationCodeLifetime = @getAuthorizationCodeLifetime(client)
    expires.setSeconds expires.getSeconds() + authorizationCodeLifetime
    expires

  ###*
  # Get authorization code lifetime.
  ###

  getAuthorizationCodeLifetime: (client) ->
    client.authorizationCodeLifetime or @authorizationCodeLifetime

  ###*
  # Save authorization code.
  ###

  saveAuthorizationCode: (authorizationCode, expiresAt, scope, client, redirectUri, user) ->
    userId = user.__data.id

    code =
      id: authorizationCode
      expiresAt: expiresAt
      clientId: client.id
      userId: userId
      redirectURI: redirectUri

    if scope
      code.scopes = [ scope ]

    @modelHelpers.saveAuthorizationCode code

  ###*
  # Generate authorization code.
  ###

  generateAuthorizationCode: ->
    if @modelHelpers.generateAuthorizationCode
      return @modelHelpers.generateAuthorizationCode()

    @modelHelpers.generateRandomToken()

  ###*
  # Build redirect uri.
  ###

  buildRedirectUri: (redirectUri) ->
    if not redirectUri
      throw new InvalidArgumentError 'Missing parameter: `redirectUri`'

    redirectUri.search = null

    @setRedirectUriParam redirectUri, 'code', @code

  ###*
  # Set redirect uri parameter.
  ###

  setRedirectUriParam: (redirectUri, key, value) ->
    if not redirectUri
      throw new InvalidArgumentError 'Missing parameter: `redirectUri`'

    if not key
      throw new InvalidArgumentError 'Missing parameter: `key`'

    redirectUri.query = redirectUri.query or {}
    redirectUri.query[key] = value
    redirectUri

module.exports = CodeResponseType