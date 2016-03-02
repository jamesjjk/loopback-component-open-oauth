###*
# Module dependencies.
###

{ defaults } = require 'lodash'
{ OAuthError } = require './oauth-error'

###*
# Constructor.
#
# "If the request lacks any authentication information (e.g., the client
# was unaware that authentication is necessary or attempted using an
# unsupported authentication method), the resource server SHOULD NOT
# include an error code or other error information."
#
# @see https://tools.ietf.org/html/rfc6750#section-3.1
###

messages =
  NOAUTH:  'Unauthorized request: no authentication given'

class exports.UnauthorizedRequestError extends OAuthError
  constructor: (message, properties) ->
    properties = defaults {}, properties,
      code: 401
      name: 'unauthorized_request'

    super messages[message], properties
