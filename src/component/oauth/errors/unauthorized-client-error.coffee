###*
# Module dependencies.
###

{ defaults } = require 'lodash'
{ OAuthError } = require './oauth-error'

###*
# Constructor.
#
# "The authenticated client is not authorized to use this authorization grant type."
#
# @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
###

messages =
  INVALIDGRANTTYPE: 'Unauthorized client: `grant_type` is invalid'

class exports.UnauthorizedClientError extends OAuthError
  constructor: (message, properties) ->
    properties = defaults {}, properties,
      code: 400
      name: 'unauthorized_client'

    super messages[message], properties
