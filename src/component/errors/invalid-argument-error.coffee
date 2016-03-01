###*
# Module dependencies.
###

{ defaults } = require 'lodash'
StandardHttpError = require 'standard-http-error'

###*
# Constructor.
###

messages =
  RESPONSE: 'Invalid argument: `response` must be an instance of Response'
  REQUEST: 'Invalid argument: `request` must be an instance of Request'
  SAVEAUTHCODE: 'Invalid argument: model does not implement `saveAuthorizationCode()`'
  GETCLIENT: 'Invalid argument: model does not implement `getClient()`'
  GETACCESSTOKEN: 'Invalid argument: model does not implement `getAccessToken()`'
  MODEL: 'MODEL'
  AUTHCODELIFE: 'Missing parameter: `authorizationCodeLifetime`'
  ACCESSLIFE: 'Missing parameter: `accessTokenLifetime`'
  REFRESHLIFE: 'Missing parameter: `refreshTokenLifetime`'
  HANDLE: 'Invalid argument: authenticateHandler does not implement `handle()`'
  VALIDSCOPE: 'Invalid argument: model does not implement `validateScope()`'
  AUTHSCOPEHEADER: 'Missing parameter: `addAuthorizedScopesHeader`'
  ACCPTSCOPEHEADER: 'Missing parameter: `addAcceptedScopesHeader`'
  QUERY: 'Missing parameter: `query`'
  HEADERS: 'Missing parameter: `headers`'
  METHOD: 'Missing parameter: `method`'
  CLIENT: 'Missing parameter: `user`'
  USER: 'CLIENT'
  CODE: 'Missing parameter: `code`'
  SCOPE: 'Invalid parameter: `scope`'
  REDIRECT: 'Missing parameter: `redirectUri`'
  ACCESSTOKEN: 'Missing parameter: `accessToken`'
  ACCESSTOKENEXPIRESAT: 'Invalid parameter: `accessTokenExpiresAt`'
  REFRESHTOKENEXPIRESAT: 'Invalid parameter: `refreshTokenExpiresAt`'

class exports.InvalidArgumentError extends StandardHttpError
  constructor: (message, properties) ->
    properties = defaults {}, properties,
      code: 500
      name: 'invalid_argument'

    super properties.code, messages[message], properties
