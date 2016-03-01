###*
# Module dependencies.
###

Promise = require 'bluebird'

{ Request } = require '../request'
{ Response } = require '../response'

{ InvalidArgumentError } = require '../errors/invalid-argument-error'
{ InvalidRequestError } = require '../errors/invalid-request-error'
{ InvalidScopeError } = require '../errors/invalid-scope-error'
{ InvalidTokenError } = require '../errors/invalid-token-error'

{ OAuthError } = require '../errors/oauth-error'
{ ServerError } = require '../errors/server-error'

{ UnauthorizedRequestError } = require '../errors/unauthorized-request-error'

BearerTokenType = require '../token-types/bearer-token-type'
MacTokenType = require '../token-types/mac-token-type'

ModelHelpers = require '../helpers'

###*
# Authenticate Handler.
###

class exports.AuthenticateHandler
  constructor: ({ @scope, @throwErrors, @addAcceptedScopesHeader, @validateScope, @addAuthorizedScopesHeader, @allowBearerTokensInQueryString }) ->
    if @scope and @addAcceptedScopesHeader is undefined
      throw new InvalidArgumentError 'ACCPTSCOPEHEADER'

    if @scope and @addAuthorizedScopesHeader is undefined
      throw new InvalidArgumentError 'AUTHSCOPEHEADER'

    if @scope and not ModelHelpers.validateScope
      throw new InvalidArgumentError 'VALIDSCOPE'

    return

  handle: (request, response) ->
    if not request instanceof Request
      throw new InvalidArgumentError 'REQUEST'

    if not response instanceof Response
      throw new InvalidArgumentError 'RESPONSE'

    Promise.bind this
      .then ->
        @getTokenFromRequest request
      .then (token) ->
        @getAccessToken token
      .then (token) ->
        @getUserById token
      .tap (token) ->
        @validateAccessToken token
      .tap (token) ->
        return if not @scope
        @validateScope token
      .tap (token) ->
        @updateResponse response, token
      .catch (e) ->
        # Include the "WWW-Authenticate" response header field if the client
        # lacks any authentication information.
        #
        # @see https://tools.ietf.org/html/rfc6750#section-3.1
        if e instanceof UnauthorizedRequestError
          response.set 'WWW-Authenticate', 'Bearer realm="Service"'

        if not e instanceof OAuthError
          throw new ServerError e

        throw e

        return

  ###*
  # Get the token from the header or body, depending on the request.
  #
  # "Clients MUST NOT use more than one method to transmit the token in each request."
  #
  # @see https://tools.ietf.org/html/rfc6750#section-2
  ###

  getTokenFromRequest: (request) ->
    fns = [
      BearerTokenType.getTokenFromRequest(request)
      MacTokenType.getTokenFromRequest(request)
    ]

    Promise.all fns
      .bind this
      .spread (bearerToken, macToken) ->
        if not bearerToken or macToken
          throw new UnauthorizedRequestError 'NOAUTH'

        bearerToken or macToken

  ###*
  # Get the access token from the model.
  ###

  getAccessToken: (token) ->
    ModelHelpers.getAccessToken token
      .then (accessToken) ->
        if not accessToken
          throw new InvalidTokenError 'INVALID'

        return accessToken

  getUserById: (token) ->
    ModelHelpers.getUserById token
      .then (user) ->
        if not user
          throw new InvalidTokenError 'INVALID'

        if not user
          throw new ServerError 'ACCESSTOKEN'

        tokenData = token.__data
        tokenData.user = user

        return tokenData

  ###*
  # Validate access token.
  ###

  validateAccessToken: (accessToken) ->
    { accessTokenExpiresAt } = accessToken

    if accessTokenExpiresAt and not accessTokenExpiresAt instanceof Date
      throw new ServerError 'DATEINSTANCE'

    if accessTokenExpiresAt and accessTokenExpiresAt < new Date
      throw new InvalidTokenError 'EXPIRED'

    accessToken

  ###*
  # Validate scope.
  ###

  validateScope: (accessToken) ->
    scopeData = [
      accessToken
      @scope
    ]

    ModelHelpers.validateScope scopeData
      .then (scope) ->
        if not scope
          throw new InvalidScopeError 'INVALID'
        scope

  ###*
  # Update response.
  ###

  updateResponse: (response, accessToken) ->
    if @scope and @addAcceptedScopesHeader
      response.set 'X-Accepted-OAuth-Scopes', @scope

    if @scope and @addAuthorizedScopesHeader
      response.set 'X-OAuth-Scopes', accessToken.scope

    return
