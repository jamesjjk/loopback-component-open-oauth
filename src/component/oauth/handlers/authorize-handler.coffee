###*
# Module dependencies.
###

{ includes } = require 'lodash'

Promise = require 'bluebird'
validate = require '../validator/is'
url = require 'url'

{ AuthenticateHandler } = require '../handlers/authenticate-handler'
{ AccessDeniedError } = require '../errors/access-denied-error'

{ InvalidArgumentError } = require '../errors/invalid-argument-error'
{ InvalidClientError } = require '../errors/invalid-client-error'
{ InvalidRequestError } = require '../errors/invalid-request-error'
{ InvalidScopeError } = require '../errors/invalid-scope-error'

{ UnauthorizedClientError } = require '../errors/unauthorized-client-error'

{ OAuthError } = require '../errors/oauth-error'
{ ServerError } = require '../errors/server-error'

{ Request } = require '../request'
{ Response } = require '../response'

###*
# Response types.
###

responseTypes =
  code: require '../response-types/code-response-type'
  token: require '../response-types/token-response-type'

###*
# Authorize Handler.
###

class exports.AuthorizeHandler
  constructor: (@options) ->
    { @authenticateHandler, @authorizationCodeLifetime, @allowEmptyState, @modelHelpers } = @options

    if @authenticateHandler and not @authenticateHandler.handle
      throw new InvalidArgumentError 'HANDLE'

    if not @authorizationCodeLifetime
      throw new InvalidArgumentError 'AUTHCODELIFE'

    @authenticateHandler = @authenticateHandler or new AuthenticateHandler options

    return

  handle: (request, response) ->
    if not request instanceof Request
      throw new InvalidArgumentError 'REQUEST'

    if not response instanceof Response
      throw new InvalidArgumentError 'RESPONSE'

    if request.query.allowed is 'false'
      return Promise.reject new AccessDeniedError 'NOACCESS'

    fns = [
      @generateAuthorizationCode()
      @getAuthorizationCodeLifetime()
      @getClient(request)
      @getUser(request, response)
    ]

    Promise.all fns
      .bind @
      .spread (authorizationCode, expiresAt, client, user) ->
        scope = @getScope request
        state = @getState request

        responseType = @getResponseType request, client

        uri = @getRedirectUri request, client

        Promise.bind @
          .then ->
            responseType.handle request, client, user, uri, scope
          .then (code) ->
            redirectUri = @buildSuccessRedirectUri uri, responseType
            @updateResponse response, redirectUri, responseType, state
            code
          .catch (e) ->
            if not e instanceof OAuthError
              e = new ServerError e

            redirectUri = @buildErrorRedirectUri uri, responseType, e

            @updateResponse response, redirectUri, responseType, state

            throw e
            return

  ###*
  # Get the client from the model.
  ###

  getClient: (request) ->
    clientId = request.body.client_id or request.query.client_id

    if not clientId
      throw new InvalidRequestError 'MISSINGCLIENT'

    if not validate.vschar(clientId)
      throw new InvalidRequestError 'INVALIDCLIENT'

    redirectUri = request.body.redirect_uri or request.query.redirect_uri

    if redirectUri and not validate.uri redirectUri
      throw new InvalidRequestError 'REDIRECT'

    @modelHelpers.getClientApplicationById clientId
      .then (client) ->
        if not client
          throw new InvalidClientError 'CLIENTCREDS'

        if not client.grantTypes
          throw new InvalidClientError 'GRANTS'

        if not includes client.grantTypes, 'authorization_code'
          throw new UnauthorizedClientError 'INVALIDGRANTTYPE'

        if not client.redirectURIs or not client.redirectURIs.length
          throw new InvalidClientError 'MISSINGREDIRECT'

        if redirectUri and not includes client.redirectURIs, redirectUri
          throw new InvalidClientError 'REDIRCTMATCH'

        return client

  ###*
  # Get scope from the request.
  ###

  getScope: ({ body, query }) ->
    scope = body.scope or query.scope

    if not validate.nqschar scope
      throw new InvalidScopeError 'MISSINGSCOPE'

    scope

  ###*
  # Get state from the request.
  ###

  getState: ({ body, query }) ->
    state = body.state or query.state

    if not @allowEmptyState and not state
      throw new InvalidRequestError 'MISSINGSTATE'

    if not validate.vschar state
      throw new InvalidRequestError 'INVALIDSTATE'

    state

  ###*
  # Get user by calling the authenticate middleware.
  ###

  getUser: (request, response) ->
    @authenticateHandler.handle request, response
      .then (token) ->
        if not token.user
          throw new ServerError 'USEROBJECT'

        token.user

  ###*
  # Get redirect URI.
  ###

  getRedirectUri: (request, client) ->
    request.body.redirect_uri or request.query.redirect_uri or client.redirectURIs[0]

  ###*
  # Get response type.
  ###

  getResponseType: ({ body, query }, code) ->
    responseType = body.response_type or query.response_type

    if not responseType
      throw new InvalidRequestError 'MISSINGRESPNSETYPE'

    if not includes [ 'code' ], responseType
      throw new InvalidRequestError 'MISSINGRESPNSETYPE'

    Type = responseTypes[responseType]

    new Type @options

  ###*
  # Build a successful response that redirects the user-agent to the client-provided url.
  ###

  buildSuccessRedirectUri: (redirectUri, responseType) ->
    uri = url.parse(redirectUri)
    responseType.buildRedirectUri uri

  ###*
  # Build an error response that redirects the user-agent to the client-provided url.
  ###

  buildErrorRedirectUri: (redirectUri, responseType, error) ->
    uri = url.parse redirectUrl
    uri = responseType.setRedirectUriParam uri, 'error', error.name

    if error.message
      uri = responseType.setRedirectUriParam uri, 'error_description', error.message

    uri

  ###*
  # Update response with the redirect uri and the state parameter, if available.
  ###

  updateResponse: (response, redirectUri, responseType, state) ->
    if state
      redirectUri = responseType.setRedirectUriParam redirectUri, 'state', state

    response.redirect url.format(redirectUri)

    return
