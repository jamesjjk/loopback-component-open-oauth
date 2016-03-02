###*
# Module dependencies.
###

{ defaults } = require 'lodash'
{ OAuthError } = require './oauth-error'

###*
# Constructor.
#
# "The resource owner or authorization server denied the request"
#
# @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
###

messages =
  NOACCESS: 'Access denied: user denied access to application'

class exports.AccessDeniedError extends OAuthError
  constructor: (message, properties) ->
    properties = defaults {}, properties,
      code: 400
      name: 'access_denied'

    super messages[message], properties
