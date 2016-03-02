###*
# Module dependencies.
###

{ defaults } = require 'lodash'
{ OAuthError } = require './oauth-error'

###*
# Constructor.
#
# "The provided authorization grant (e.g., authorization code, resource owner credentials)
# or refresh token is invalid, expired, revoked, does not match the redirection URI used
# in the authorization request, or was issued to another client."
#
# @see https://tools.ietf.org/html/rfc6749#section-5.2
###

class exports.InvalidGrantError extends OAuthError
  constructor: (message, properties) ->
    properties = defaults {}, properties,
      code: 400
      name: 'invalid_grant'

    super message, properties
