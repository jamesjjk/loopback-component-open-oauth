###*
# Module dependencies.
###

auth = require 'basic-auth'
Promise = require 'bluebird'
validate = require '../validator/is'

{ has, assign, contains } = require 'lodash'

{ InvalidArgumentError } = require '../errors/invalid-argument-error'
{ InvalidClientError } = require '../errors/invalid-client-error'
{ InvalidRequestError } = require '../errors/invalid-request-error'

{ UnauthorizedClientError } = require '../errors/unauthorized-client-error'
{ UnsupportedGrantTypeError } = require '../errors/unsupported-grant-type-error'

{ OAuthError } = require '../errors/oauth-error'
{ ServerError } = require '../errors/server-error'

{ Request } = require '../request'
{ Response } = require '../response'

ModelHelpers = require '../helpers'

###*
# Grant types.
###

grantTypes =
  authorization_code: require '../grant-types/authorization-code-grant-type'
  client_credentials: require '../grant-types/client-credentials-grant-type'
  password: require '../grant-types/password-grant-type'
  refresh_token: require '../grant-types/refresh-token-grant-type'

###*
# Token types.
###

tokenTypes =
  bearer: require '../token-types/bearer-token-type'
  mac: require '../token-types/mac-token-type'

###*
# Token Handler.
###

class exports.TokenHandler
  constructor: ({ @accessTokenLifetime, @refreshTokenLifetime, extendedGrantTypes }) ->
    if not accessTokenLifetime
      throw new InvalidArgumentError 'AUTHCODELIFE'

    if not refreshTokenLifetime
      throw new InvalidArgumentError 'REFRESHLIFE'

    @grantTypes = assign {}, grantTypes, extendedGrantTypes

    return

  handle: (request, response) ->
    if not request instanceof Request
      throw new InvalidArgumentError 'REQUEST'

    if not response instanceof Response
      throw new InvalidArgumentError 'RESPONSE'

    if request.method isnt 'POST'
      return Promise.reject new InvalidRequestError 'POST'

    if not request.is 'application/x-www-form-urlencoded'
      return Promise.reject new InvalidRequestError 'FORMENCODED'

    Promise.bind this
      .then ->
        @getClient request, response
      .then (client) ->
        @handleGrantType request, client
      .tap (data) ->
        @getTokenType client.tokenType, data
      .tap (tokenType) ->
        @updateSuccessResponse response, tokenType
      .catch (e) ->
        if not e instanceof OAuthError
          e = new ServerError e

        @updateErrorResponse response, e

        throw e

        return

  ###*
  # Get the client from the model.
  ###

  getClient: (request, response) ->
    { clientId, clientSecret } = @getClientCredentials request

    if not clientId
      throw new InvalidRequestError 'MISSINGCLIENT'

    if not clientSecret
      throw new InvalidRequestError 'MISSINGCLIENTSECRET'

    if not validate.vschar clientId
      throw new InvalidRequestError 'INVALIDCLIENT'

    if not validate.vschar clientSecret
      throw new InvalidRequestError 'INVALIDCLIENTSECRET'

    clientCredentials = [ clientId, clientSecret ]

    ModelHelpers.getClientApplicationByKey clientCredentials
      .then (client) ->
        if not client
          throw new InvalidClientError 'INVALID'

        if not client.grants
          throw new ServerError 'MISSINGGRANTS'

        if not client.grants instanceof Array
          throw new ServerError 'INVALIDGRANTS'

        client
      .catch (e) ->
        if e instanceof InvalidClientError and request.get 'authorization'
          # Include the "WWW-Authenticate" response header field if the client
          # attempted to authenticate via the "Authorization" request header.
          #
          # @see https://tools.ietf.org/html/rfc6749#section-5.2.
          response.set 'WWW-Authenticate', 'Basic realm="Service"'

          throw new InvalidClientError e, code: 401

        throw e

  ###*
  # Get client credentials.
  #
  # The client credentials may be sent using the HTTP Basic authentication scheme or, alternatively,
  # the `client_id` and `client_secret` can be embedded in the body.
  #
  # @see https://tools.ietf.org/html/rfc6749#section-2.3.1
  ###

  getClientCredentials: (request) ->
    credentials = auth request

    if credentials
      data =
        clientId: credentials.name
        clientSecret: credentials.pass

    if request.body.client_id and request.body.client_secret
      data =
        clientId: request.body.client_id
        clientSecret: request.body.client_secret

    if data
      return data

    throw new InvalidClientError 'NORESPONSE'

    return

  ###*
  # Handle grant type.
  ###

  handleGrantType: (request, client) ->
    { grant_type } = request.body

    if not grant_type
      throw new InvalidRequestError 'MISSINGGRANTTYPE'

    if not validate.nchar grant_type and not validate.uri grant_type
      throw new InvalidRequestError 'INVALIDGRANTTYPE'

    if not has @grantTypes, grant_type
      throw new UnsupportedGrantTypeError 'UNSUPPORTED'

    if not contains client.grants, grant_type
      throw new UnauthorizedClientError 'INVALIDGRANTTYPE'

    accessTokenLifetime = @getAccessTokenLifetime client
    refreshTokenLifetime = @getRefreshTokenLifetime client

    grantType = @grantTypes[grant_type]

    options =
      accessTokenLifetime: accessTokenLifetime
      refreshTokenLifetime: refreshTokenLifetime

    new grantType(options).handle request, client

  ###*
  # Get access token lifetime.
  ###

  getAccessTokenLifetime: (client) ->
    client.accessTokenLifetime or @accessTokenLifetime

  ###*
  # Get refresh token lifetime.
  ###

  getRefreshTokenLifetime: (client) ->
    client.refreshTokenLifetime or @refreshTokenLifetime

  ###*
  # Get token type.
  ###

  getTokenType: (tokenType, tokenData) ->
    new tokenTypes[tokenType] tokenData

  ###*
  # Update response when a token is generated.
  ###

  updateSuccessResponse: (response, tokenType) ->
    response.body = tokenType.valueOf()

    response.set 'Cache-Control', 'no-store'
    response.set 'Pragma', 'no-cache'

    return

  ###*
  # Update response when an error is thrown.
  ###

  updateErrorResponse: (response, error) ->
    response.body =
      error: error.name
      error_description: error.message

    response.status = error.code

    return
