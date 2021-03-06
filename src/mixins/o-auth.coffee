###*
# Module dependencies.
###

{ defaults } = require 'lodash'

{ AuthenticateHandler } = require '../component/oauth/handlers/authenticate-handler'
{ AuthorizeHandler } = require '../component/oauth/handlers/authorize-handler'

{ TokenHandler } = require '../component/oauth/handlers/token-handler'

{ Request } = require '../component/oauth/request'
{ Response } = require '../component/oauth/response'

ModelHelpers = require '../component/oauth/helpers'

###*
# Authenticate a token.
###

module.exports = (Model, options) ->

  { addAcceptedScopesHeader
    addAuthorizedScopesHeader
    allowBearerTokensInQueryString
    allowEmptyState
    authorizationCodeLifetime
    accessTokenLifetime
    currentUserLiteral
    refreshTokenLifetime
    models } = options

  models = defaults {}, models,
    userModel: Model.modelName
    tokenModel: 'accessToken'
    authModel: 'AuthorizationCode'
    appModel: 'ClientApplication'
    refreshModel: 'RefreshToken'

  modelHelpers = new ModelHelpers models

  ###*
  # Authenticate a request.
  ###

  Model.on 'attached', (server) ->
    server.middleware 'auth', (req, res, callback) ->
      request = new Request req
      response = new Response res

      authenticateOptions =
        modelHelpers: modelHelpers
        addAcceptedScopesHeader: addAcceptedScopesHeader or true
        addAuthorizedScopesHeader: addAuthorizedScopesHeader or true
        allowBearerTokensInQueryString: allowBearerTokensInQueryString or false

      new AuthenticateHandler authenticateOptions
        .handle request, response
        .nodeify callback

  ###*
  # Authorize a request.
  ###

  Model.authorize = (req, res, callback) ->
    request = new Request req
    response = new Response res

    authorizeOptions =
      modelHelpers: modelHelpers
      currentUserLiteral: currentUserLiteral or 'me'
      allowEmptyState: allowEmptyState or true
      accessTokenLifetime: accessTokenLifetime or 60 * 60
      authorizationCodeLifetime: authorizationCodeLifetime or 5 * 60

    new AuthorizeHandler authorizeOptions
      .handle request, response
      .nodeify callback

  Model.remoteMethod 'authorize',
    description: 'authorize a user with username/email and password.'
    accepts: [
      {
        arg: 'req'
        type: 'object'
        required: true
        http: source: 'req'
      }
      {
        arg: 'res'
        type: 'object'
        required: true
        http: source: 'res'
      }
      {
        arg: 'client_id'
        type: 'string'
      }
      {
        arg: 'redirect_url'
        type: 'string'
      }
      {
        arg: 'response_type'
        type: 'string'
      }
      {
        arg: 'scope'
        type: 'string'
      }
    ]
    returns:
      arg: 'accessToken'
      type: 'object'
      root: true
      description: 'The response body contains properties of the AccessToken created on login.\n' + 'Depending on the value of `include` parameter, the body may contain ' + 'additional properties:\n\n' + '  - `user` - `{User}` - Data of the currently logged in user. (`include=user`)\n\n'
    http: verb: 'post'

  ###*
  # Create a token.
  ###

  Model.token = (req, res, callback) ->
    request = new Request req
    response = new Response res

    responseType = request.body.response_type or request.query.response_type

    ttl = switch responseType
      when 'code' then 300
      else accessTokenLifetime

    tokenOptions =
      modelHelpers: modelHelpers
      accessTokenLifetime: accessTokenLifetime or 14 * 24 * 3600
      refreshTokenLifetime: refreshTokenLifetime or 60 * 60 * 24 * 14

    new TokenHandler tokenOptions
      .handle request, response
      .nodeify callback

  Model.remoteMethod 'token',
    description: 'authorize a user with username/email and password.'
    accepts: [
      {
        arg: 'req'
        type: 'object'
        required: true
        http: source: 'req'
      }
      {
        arg: 'res'
        type: 'object'
        required: true
        http: source: 'res'
      }
      {
        arg: 'client_id'
        type: 'string'
      }
      {
        arg: 'client_secret'
        type: 'string'
      }
      {
        arg: 'grant_type'
        type: 'string'
      }
      {
        arg: 'refresh_token'
        type: 'string'
      }
      {
        arg: 'username'
        type: 'string'
      }
      {
        arg: 'password'
        type: 'string'
      }
    ]
    returns:
      arg: 'accessToken'
      type: 'object'
      root: true
      description: 'The response body contains properties of the AccessToken created on login.\n' + 'Depending on the value of `include` parameter, the body may contain ' + 'additional properties:\n\n' + '  - `user` - `{User}` - Data of the currently logged in user. (`include=user`)\n\n'
    http: verb: 'post'