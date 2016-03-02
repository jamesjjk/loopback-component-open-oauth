###*
# Module dependencies.
###

{ AbstractTokenType } = require './abstract-token-type'

{ ServerError } = require '../errors/server-error'

{ InvalidRequestError }  = require '../errors/invalid-request-error'
{ InvalidArgumentError } = require '../errors/invalid-argument-error'

{ pseudoRandomBytes } = require 'crypto'

###*
# Constructor.
###

class MacTokenType extends AbstractTokenType
  constructor: (data = {}) ->
    super data

    if not @accessToken
      throw new InvalidArgumentError 'ACCESSTOKEN'

    @macKey = pseudoRandomBytes(32).toString 'hex'

    return

  valueOf: ->
    object =
      access_token: @accessToken
      token_type: 'mac'
      mac_key: @macKey
      mac_algorithm: 'hmac-sha-256'

    if @accessTokenLifetime
      object.expires_in = @accessTokenLifetime

    if @refreshToken
      object.refresh_token = @refreshToken

    if @scope
      object.scope = @scope

    object

  @getTokenFromRequest: (request) ->
    headerToken = request.get 'authorization'

    if headerToken
      return @getTokenFromRequestHeader request

    return

  ###*
  # Get the mac token from the request header.
  #
  # @see http://tools.ietf.org/html/rfc6750#section-2.1
  ###

  @getTokenFromRequestHeader: (request) ->
    header = request.get 'authorization'

    if header.substring 0, 4 isnt 'MAC '
      return

    pairs = header.substring(4).trim().split(',')

    keyValues = {}

    for pair in pairs
      matches = pair.match /([a-zA-Z]*)="([\w=\/+]*)"/

      if matches.length isnt 3
        return

      [ key, value ] = matches

      keyValues[key.trim()] = value.trim()

    if keyValues.id is false or keyValues.ts is false or keyValues.nonce is false or keyValues.mac is false
      throw new InvalidRequestError 'MALFORMED'

    currentTimeStamp = Math.abs(keyValues.ts) - now()

    if currentTimeStamp > 300
      throw new InvalidRequestError 'EXPIRED'

    keyValues

module.exports = MacTokenType