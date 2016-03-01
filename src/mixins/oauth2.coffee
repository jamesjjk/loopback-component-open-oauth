###*
# Module dependencies.
###

{ AuthenticateHandler } = require '../component/oauth/handlers/authenticate-handler'
{ AuthorizeHandler } = require '../component/oauth/handlers/authorize-handler'

{ TokenHandler } = require '../component/oauth/handlers/token-handler'

{ Request } = require '../component/oauth/request'
{ Response } = require '../component/oauth/response'

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
    refreshTokenLifetime } = options

  Model.authenticate = (req, res, callback) ->
    request = new Request req
    response = new Response res

    authenticateOptions =
      modelName: Model.modelName
      addAcceptedScopesHeader: addAcceptedScopesHeader or true
      addAuthorizedScopesHeader: addAuthorizedScopesHeader or true
      allowBearerTokensInQueryString: allowBearerTokensInQueryString or false

    new AuthenticateHandler authenticateOptions
      .handle request, response
      .nodeify callback

  Model.remoteMethod 'authenticate',
    description: 'authenticate a user with username/email and password.'
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
    ]
    returns:
      arg: 'accessToken'
      type: 'object'
      root: true
      description: 'The response body contains properties of the AccessToken created on login.\n' + 'Depending on the value of `include` parameter, the body may contain ' + 'additional properties:\n\n' + '  - `user` - `{User}` - Data of the currently logged in user. (`include=user`)\n\n'
    http: verb: 'post'

  ###*
  # Authorize a request.
  ###

  Model.authorize = (req, res, callback) ->
    request = new Request req
    response = new Response res

    authorizeOptions =
      modelName: Model.modelName
      currentUserLiteral: currentUserLiteral or 'me'
      allowEmptyState: allowEmptyState or true
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
      modelName: Model.modelName
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