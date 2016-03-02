###*
# Module dependencies.
###

{ defaults } = require 'lodash'
{ OAuthError } = require './oauth-error'

###*
# Constructor.
#
# "The requested scope is invalid, unknown, or malformed."
#
# @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
###

messages =
  INVALID: 'Invalid scope: scope is invalid'
  MISSINGSCOPE: 'Invalid parameter: `scope`'

class exports.InvalidScopeError extends OAuthError
  constructor: (message, properties) ->
    properties = defaults {}, properties,
      code: 400
      name: 'invalid_scope'

    super messages[message], properties
