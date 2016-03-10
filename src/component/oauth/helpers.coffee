debug = require('debug')('loopback:oauth:helpers')

loopback = require 'loopback'
validate = require './validator/is'
validateScope = require './validator/scope'
remap = require './utils/map'

{ promisify, resolve } = require 'bluebird'
{ randomBytes, createHash } = require 'crypto'

promisedRandomBytes = promisify randomBytes

class ModelHelpers
  constructor: ({ @userModel, @tokenModel, @authModel, @appModel, @refreshModel }) ->
    debug """in ModelHelpers (
      User: #{ @userModel },
      AccessToken: #{ @tokenModel },
      AuthorizationCode: #{ @authModel },
      Application: #{ @appModel },
      RefreshToken: #{ @refreshModel }
      )
      """

  lookupUser: (req, info) ->
    defer = q.defer()

    defer.resolve {}

    defer.promise

  determineProvider: (request) ->
    defer = q.defer()

    id = request.params.provider or request.body.provider
    providers = loopback.get 'auth-providers'

    provider = providers[id]

    if provider
      promise.resolve provider
    else
      promise.reject null

    defer.promise

  connectUser: (user, provider, auth, info) ->
    UserMember = loopback.getModel @userModel

    data =
      providers: {}
      lastProvider: provider.id

    data.providers[provider.id] =
      provider: provider.id
      protocol: provider.protocol
      auth: auth
      info: info

    if user
      if provider.refresh_userinfo
        remap provider.mapping, info, data

      return user.updateAttributes data
    else
      remap provider.mapping, info, data

      return UserMember.create data

  @getModelByType: (models, type) ->
    modelType = loopback.getModel type

    for m of models
      if models[m].prototype instanceof modelType
        return models[m].definition.name

    modelType

  getAccessToken: (bearerToken) ->
    debug "in getAccessToken (bearerToken: #{ bearerToken })"

    TokenModel = loopback.getModel @tokenModel

    TokenModel.findById bearerToken

  getAuthorizationCode: (code) ->
    debug "in getAuthorizationCode (code: #{ code })"

    AuthorizationCode = loopback.getModel @authModel

    AuthorizationCode.findById code

  saveAuthorizationCode: (code) ->
    debug "in saveAuthorizationCode (code: #{ code })"

    AuthorizationCode = loopback.getModel @authModel

    AuthorizationCode.create code

  revokeAuthorizationCode: (code) ->
    debug "in revokeAuthorizationCode (code: #{ code })"

    AuthorizationCode = loopback.getModel @authModel

    AuthorizationCode.deleteById code

  getUserById: (accessToken) ->
    userId = accessToken.userId.replace /\"/g, ''

    debug "in getUserById (userId: #{ userId })"

    if not accessToken?.userId
      return resolve()

    UserMember = loopback.getModel @userModel

    UserMember.findById userId

  generateRandomToken: ->
    promisedRandomBytes 256
      .then (buffer) ->
        createHash('sha1').update(buffer).digest 'hex'

  grantTypeAllowed: (appId, grantType) ->
    debug "in grantTypeAllowed (appId: #{ appId }, grantType: #{ grantType })"

    ClientApplication = loopback.getModel @appModel

    if grantType is 'password'

      query =
        id: appId

      ClientApplication.findById query

  createToken: (token, appId, expires, userId) ->
    userId = userId.replace /\"/g, ''

    debug "in saveAccessToken (token: #{ token }, appId: #{ appId }, userId: #{ userId }, expires: #{ expires })"

    AccessToken = loopback.getModel @tokenModel

    accessTokenData =
      accessToken: token
      appId: appId
      userId: userId
      expires: expires

    AccessToken.create accessTokenData

  ###
  # Required to support password grant type
  ###

  getUser: (request) ->
    User = loopback.getModel @userModel

    if not request.body.username
      throw new InvalidRequestError 'Missing parameter: `username`'

    if not request.body.password
      throw new InvalidRequestError 'Missing parameter: `password`'

    if not validate.uchar(request.body.username)
      throw new InvalidRequestError 'Invalid parameter: `username`'

    if not validate.uchar(request.body.password)
      throw new InvalidRequestError 'Invalid parameter: `password`'

    credentials = [
      request.body.username
      request.body.password
    ]

    debug "in getUser (username: #{ credentials.username }, password: #{ credentials.password })"

    User.findOne credentials

  ###*
  # Revoke the refresh token.
  #
  # @see https://tools.ietf.org/html/rfc6749#section-6
  ###
  revokeRefreshToken: (token) ->
    debug "in revokeRefreshToken (token: #{ token })"

    RefreshToken = loopback.getModel @refreshModel

    RefreshToken.deleteById token

  ###
  # Required to support refreshToken grant type
  ###

  saveRefreshToken: (token, appId, expires, userId) ->
    userId = userId.replace /\"/g, ''

    debug "in saveRefreshToken (token: #{ token }, appId: #{ appId }, userId: #{ userId }, expires: #{ expires })"

    RefreshToken = loopback.getModel @refreshModel

    refreshTokenData =
      refreshToken: token
      appId: appId
      userId: userId
      expires: expires

    RefreshToken.create refreshTokenData

  getRefreshToken: (request, client) ->
    if not request.body.refresh_token
      throw new InvalidRequestError 'Missing parameter: `refresh_token`'

    if not validate.vschar request.body.refresh_token
      throw new InvalidRequestError 'Invalid parameter: `refresh_token`'

    refreshToken = request.body.refresh_token

    debug "in getRefreshToken (refreshToken: #{ refreshToken })"

    RefreshToken = loopback.getModel @refreshModel

    RefreshToken.findOne { refreshToken: refreshToken }

  getClientApplicationByKey: (clientId, clientKey) ->
    debug "in getClient (appId: #{ clientId }, clientKey: #{ clientKey })"

    ClientApplication = loopback.getModel @appModel

    if clientKey == null
      return ClientApplication.findOne { id: appId }

    clientData =
      id: clientId
      clientKey: clientKey

    ClientApplication.findOne clientData

  getClientApplicationById: (clientId) ->
    debug "in getClientApplication (appId: #{ clientId })"

    ClientApplication = loopback.getModel @appModel

    ClientApplication.findById clientId

  setAccessTokenContext: (request, accessToken) ->
    debug "in setAccessTokenContext (accessToken: #{ JSON.stringify accessToken })"

    request.accessToken = accessToken

    ctx = loopback.getCurrentContext()

    if ctx
      ctx.set 'accessToken', accessToken

  checkAccessTokenContext: (request) ->
    ctx = loopback.getCurrentContext()

    if ctx
      token = ctx.get 'accessToken'

    debug "in checkAccessTokenContext (token: #{ JSON.stringify token }, requestToken: #{ request.accessToken })"

    token or request.accessToken

module.exports = ModelHelpers