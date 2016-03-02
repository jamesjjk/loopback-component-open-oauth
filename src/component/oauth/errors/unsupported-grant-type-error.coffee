###*
# Module dependencies.
###

{ defaults } = require 'lodash'
{ OAuthError } = require './oauth-error'

###*
# Constructor.
#
# "The authorization grant type is not supported by the authorization server."
#
# @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
###

messages =
  UNSUPPORTED: 'Unsupported grant type: `grant_type` is invalid'

class exports.UnauthorizedRequestError extends OAuthError
  constructor: (message, properties) ->
    properties = defaults {}, properties,
      code: 400
      name: 'unsupported_grant_type'

    super messages[message], properties
