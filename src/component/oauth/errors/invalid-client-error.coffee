###*
# Module dependencies.
###

{ defaults } = require 'lodash'
{ OAuthError } = require './oauth-error'

###*
# Constructor.
#
# "Client authentication failed (e.g., unknown client, no client
# authentication included, or unsupported authentication method)"
#
# @see https://tools.ietf.org/html/rfc6749#section-5.2
###

messages =
  REDIRECT: 'Invalid request: `redirect_uri` is not a valid URI'
  CLIENTCREDS: 'Invalid client: client credentials are invalid'
  INVALID: 'Invalid client: client is invalid'
  NORESPONSE: 'Invalid client: cannot retrieve client credentials'

class exports.InvalidClientError extends OAuthError
  constructor: (message, properties) ->
    properties = defaults {}, properties,
      code: 400
      name: 'invalid_client'

    super messages[message], properties
