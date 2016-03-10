###*
# Module dependencies.
###

debug = require('debug')('loopback:oauth:handler:auth')
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
ApplicationTokenType = require '../token-types/application-token-type'

###*
# Authenticate Handler.
###

class exports.AuthenticateHandler
  constructor: ({ @scope, @throwErrors, @addAcceptedScopesHeader, @validateScope, @addAuthorizedScopesHeader, @allowBearerTokensInQueryString, @currentUserLiteral, @modelHelpers }) ->
    if @scope and @addAcceptedScopesHeader is undefined
      throw new InvalidArgumentError 'ACCPTSCOPEHEADER'

    if @scope and @addAuthorizedScopesHeader is undefined
      throw new InvalidArgumentError 'AUTHSCOPEHEADER'

    if typeof @currentUserLiteral is 'string'
      @currentUserLiteral = @currentUserLiteral.replace /[.*+?^${}()|[\]\\]/g, '\\$&'

    return

  handle: (request, response) ->
    if not request instanceof Request
      throw new InvalidArgumentError 'REQUEST'

    if not response instanceof Response
      throw new InvalidArgumentError 'RESPONSE'

    tokenExists = @modelHelpers.checkAccessTokenContext request

    if tokenExists
      return Promise.resolve()

    Promise.bind this
      .then ->
        @getTokenFromRequest request
      .then (token) ->
        @getAccessToken token
      .then (token) ->
        @getUserById token
      .tap (token) ->
        @validateAccessToken token
      #.tap (token) ->
      #  return if not @scope
      #  @validateScope token
      .tap (token) ->
        @rewriteUserLiteral request, token, @currentUserLiteral
      .tap (token) ->
        @updateResponse request, response, token
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
      ApplicationTokenType.getTokenFromRequest(request)
      BearerTokenType.getTokenFromRequest(request)
      MacTokenType.getTokenFromRequest(request)
    ]

    Promise.all fns
      .bind this
      .spread (appToken, bearerToken, macToken) ->
        if appToken
          @modelHelpers.setAccessTokenContext request, appToken
          return

        if not bearerToken or macToken
          #throw new UnauthorizedRequestError 'NOAUTH'
          return

        bearerToken or macToken

  ###*
  # Get the access token from the model.
  ###

  getAccessToken: (token) ->
    if not token
      return

    @modelHelpers.getAccessToken token
      .then (accessToken) ->
        if not accessToken
          throw new InvalidTokenError 'INVALID'

        return accessToken

  getUserById: (token) ->
    if not token
      return

    @modelHelpers.getUserById token
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
    if not accessToken
      return

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
    if not accessToken
      return

    scopeData = [
      accessToken
      @scope
    ]

    @modelHelpers.validateScope scopeData
      .then (scope) ->
        if not scope
          throw new InvalidScopeError 'INVALID'
        scope

  ###*
  # Update response.
  ###

  updateResponse: (request, response, accessToken) ->
    if not accessToken
      return

    if @scope and @addAcceptedScopesHeader
      response.set 'X-Accepted-OAuth-Scopes', @scope

    if @scope and @addAuthorizedScopesHeader
      response.set 'X-OAuth-Scopes', accessToken.scope

    @modelHelpers.setAccessTokenContext request, accessToken

    return

  ###
  # Rewrite the url to replace current user literal with the logged in user id
  ###

  rewriteUserLiteral: (request, accessToken, currentUserLiteral) ->
    if not accessToken
      return

    if accessToken.userId and currentUserLiteral
      urlBeforeRewrite = request.url

      request.url = request.url.replace(new RegExp('/' + currentUserLiteral + '(/|$|\\?)', 'g'), '/' + accessToken.userId + '$1')

      if request.url isnt urlBeforeRewrite
        debug 'request.url has been rewritten from %s to %s', urlBeforeRewrite, request.url

    return