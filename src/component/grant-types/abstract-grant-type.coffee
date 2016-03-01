###*
# Module dependencies.
###

Promise   = require 'bluebird'
validate = require '../validator/is'

{ InvalidArgumentError } = require '../errors/invalid-argument-error'

ModelHelpers = require '../helpers'

###*
# Generate access token.
###

class exports.AbstractGrantType
  constructor: ({ @accessTokenLifetime, @refreshTokenLifetime }) ->
    if not @accessTokenLifetime
      throw new InvalidArgumentError 'ACCESSLIFE'

    return

  generateAccessToken: ->
    if ModelHelpers.generateAccessToken
      return ModelHelpers.generateAccessToken()

    ModelHelpers.generateRandomToken()

  ###*
  # Generate refresh token.
  ###

  generateRefreshToken: ->
    if ModelHelpers.generateRefreshToken
      return ModelHelpers.generateRefreshToken()

    ModelHelpers.generateRandomToken()

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
