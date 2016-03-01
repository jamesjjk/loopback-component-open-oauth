###*
# Module dependencies.
###

{ defaults } = require 'lodash'
{ OAuthError } = require './oauth-error'

###*
# Constructor.
#
# "The access token provided is expired, revoked, malformed, or invalid for other reasons."
#
# @see https://tools.ietf.org/html/rfc6750#section-3.1
###

messages =
  INVALID: 'Invalid token: access token is invalid'
  EXPIRED: 'Invalid token: access token has expired'

class exports.InvalidTokenError extends OAuthError
  constructor: (message, properties) ->
    properties = defaults {}, properties,
      code: 401
      name: 'invalid_token'

    super messages[message], properties
