###*
# Module dependencies.
###

{ InvalidArgumentError } = require '../errors/invalid-argument-error'

###*
# Constructor.
###

class exports.AbstractTokenType
  constructor: ({ @accessToken, @accessTokenExpiresAt, @refreshToken, @refreshTokenExpiresAt, @client, @scope, @user }) ->
    if !@accessToken
      throw new InvalidArgumentError 'ACCESSTOKEN'

    if !@client
      throw new InvalidArgumentError 'CLIENT'

    if !@user
      throw new InvalidArgumentError 'USER'

    if @accessTokenExpiresAt and !(@accessTokenExpiresAt instanceof Date)
      throw new InvalidArgumentError 'ACCESSTOKENEXPIRESAT'

    if @refreshTokenExpiresAt and !(@refreshTokenExpiresAt instanceof Date)
      throw new InvalidArgumentError 'REFRESHTOKENEXPIRESAT'

    if @accessTokenExpiresAt
      @accessTokenLifetime = Math.floor((@accessTokenExpiresAt - (new Date)) / 1000)

    return

