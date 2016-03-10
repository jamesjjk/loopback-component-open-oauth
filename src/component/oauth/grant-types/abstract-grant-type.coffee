###*
# Module dependencies.
###

Promise   = require 'bluebird'
validate = require '../validator/is'

{ InvalidArgumentError } = require '../errors/invalid-argument-error'

###*
# Generate access token.
###

class exports.AbstractGrantType
  constructor: ({ @accessTokenLifetime, @refreshTokenLifetime, @modelHelpers }) ->
    if not @accessTokenLifetime
      throw new InvalidArgumentError 'ACCESSLIFE'

    return

  generateAccessToken: ->
    if @modelHelpers.generateAccessToken
      return @modelHelpers.generateAccessToken()

    @modelHelpers.generateRandomToken()

  ###*
  # Generate refresh token.
  ###

  generateRefreshToken: ->
    if @modelHelpers.generateRefreshToken
      return @modelHelpers.generateRefreshToken()

    @modelHelpers.generateRandomToken()

  ###*
  # Get access token expiration date.
  ###

  getAccessTokenExpiresAt: ->
    expires = new Date
    expires.setSeconds expires.getSeconds() + @accessTokenLifetime
    expires

  ###*
  # Get refresh token expiration date.
  ###

  getRefreshTokenExpiresAt: ->
    expires = new Date
    expires.setSeconds expires.getSeconds() + @refreshTokenLifetime
    expires

  ###*
  # Get scope from the request body.
  ###

  getScope: (request) ->
    if !validate.nqschar(request.body.scope)
      throw new InvalidArgumentError 'SCOPE'

    request.body.scope

  validateScope: (user, client, scope) ->
    validateScope user, client, scope
      .then (isValid) ->
        if not isValid
          throw new InvalidScopeError('Invalid scope: Requested scope is invalid')
        isValid