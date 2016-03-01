loopback = require 'loopback'
validate = require './validator/is'
validateScope = require './validator/scope'

{ promisify } = require 'bluebird'
{ randomBytes, createHash } = require 'crypto'

promisedRandomBytes = promisify randomBytes

module.exports =

  getAccessToken: (bearerToken) ->
    console.log 'in getAccessToken (bearerToken: ' + bearerToken + ')'

    TokenModel = loopback.getModel 'accessToken'

    TokenModel.findById bearerToken

  getAuthorizationCode: (code) ->
    console.log 'in getAuthorizationCode (code: ' + code + ')'

    AuthorizationCode = loopback.getModel 'AuthorizationCode'

    AuthorizationCode.findById code

  saveAuthorizationCode: (code) ->
    console.log 'in saveAuthorizationCode (code: ' + code + ')'

    AuthorizationCode = loopback.getModel 'AuthorizationCode'

    AuthorizationCode.create code

  revokeAuthorizationCode: (code) ->
    console.log 'in revokeAuthorizationCode (code: ' + code + ')'

    AuthorizationCode = loopback.getModel 'AuthorizationCode'

    AuthorizationCode.deleteById code

  getUserById: (accessToken) ->
    console.log 'in getUserById (userId: ' + accessToken.userId + ')'

    UserMember = loopback.getModel 'UserMember'
    userId = accessToken.userId.replace /\"/g, ''

    UserMember.findById userId

  generateRandomToken: ->
    promisedRandomBytes 256
      .then (buffer) ->
        createHash('sha1').update(buffer).digest 'hex'

  grantTypeAllowed: (appId, grantType) ->
    console.log 'in grantTypeAllowed (appId: ' + appId + ', grantType: ' + grantType + ')'

    ClientApplication = loopback.getModel 'ClientApplication'

    if grantType is 'password'

      query =
        id: appId

      ClientApplication.findById query

  createToken: (token, appId, expires, userId) ->
    console.log 'in saveAccessToken (token: ' + token + ', appId: ' + appId + ', userId: ' + userId + ', expires: ' + expires + ')'

    AccessToken = loopback.getModel 'AccessToken'

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
    User = loopback.getModel 'User'

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

    console.log 'in getUser (username: ' + credentials.username + ', password: ' + credentials.password + ')'

    User.findOne credentials

  ###*
  # Revoke the refresh token.
  #
  # @see https://tools.ietf.org/html/rfc6749#section-6
  ###
  revokeRefreshToken: (token) ->
    console.log 'in revokeRefreshToken (token: ' + token + ')'

    RefreshToken = loopback.getModel 'RefreshToken'

    RefreshToken.deleteById token

  ###
  # Required to support refreshToken grant type
  ###

  saveRefreshToken: (token, appId, expires, userId) ->
    console.log 'in saveRefreshToken (token: ' + token + ', appId: ' + appId + ', userId: ' + userId + ', expires: ' + expires + ')'

    RefreshToken = loopback.getModel 'RefreshToken'

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

    console.log 'in getRefreshToken (refreshToken: ' + refreshToken + ')'

    RefreshToken = loopback.getModel 'RefreshToken'

    RefreshToken.findOne { refreshToken: refreshToken }


  getClientApplicationByKey: (clientId, clientKey) ->
    console.log 'in getClient (appId: ' + clientId + ', clientKey: ' + clientKey + ')'

    ClientApplication = loopback.getModel 'ClientApplication'

    if clientKey == null
      return ClientApplication.findOne { id: appId }

    clientData =
      id: clientId
      clientKey: clientKey

    ClientApplication.findOne clientData

  getClientApplicationById: (clientId) ->
    console.log 'in getClientApplication (appId: ' + clientId + ')'

    ClientApplication = loopback.getModel 'ClientApplication'

    ClientApplication.findById clientId
