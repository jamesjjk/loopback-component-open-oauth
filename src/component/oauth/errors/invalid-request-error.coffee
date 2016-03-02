###*
# Module dependencies.
###

{ defaults } = require 'lodash'
{ OAuthError } = require './oauth-error'

###*
# Constructor.
#
# "The request is missing a required parameter, includes an invalid parameter value,
# includes a parameter more than once, or is otherwise malformed."
#
# @see https://tools.ietf.org/html/rfc6749#section-4.2.2.1
###

messages =
  ONEAUTH: 'Invalid request: only one authentication method is allowed'
  MALFORMED: 'Invalid request: malformed authorization header'
  QUERYSTRING: 'Invalid request: do not send bearer tokens in query URLs'
  GETBODY: 'Invalid request: token may not be passed in the body when using the GET verb'
  FORMENCODED: 'Invalid request: content must be application/x-www-form-urlencoded'
  MISSINGCLIENT: 'Missing parameter: `client_id`'
  INVALIDCLIENT: 'Invalid parameter: `client_id`'
  MISSINGSTATE: 'Missing parameter: `state`'
  INVALIDSTATE: 'Invalid parameter: `state`'
  MISSINGRESPNSETYPE: 'Missing parameter: `response_type`'
  INVALIDRESPNSETYPE: 'Invalid parameter: `response_type`'
  MISSINGGRANTTYPE: 'Missing parameter: `grant_type`'
  INVALIDGRANTTYPE: 'Invalid parameter: `grant_type`'

class exports.InvalidRequestError extends OAuthError
  constructor: (message, properties) ->
    properties = defaults {}, properties,
      code: 400
      name: 'invalid_request'

    super messages[message], properties
