###*
# Module dependencies.
###

{ defaults } = require 'lodash'
{ OAuthError } = require './oauth-error'

###*
# Constructor.
#
# "The authorization server encountered an unexpected condition that prevented it from fulfilling the request."
#
# @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
###

messages =
  ACCESSTOKEN: 'Server error: `getAccessToken()` did not return a `user` object'
  DATEINSTANCE: 'Server error: `expires` must be a Date instance'
  USEROBJECT: 'Server error: `handle()` did not return a `user` object'
  MISSINGGRANTS: 'Server error: missing client `grants`'
  INVALIDGRANTS: 'Server error: `grants` must be an array'
  NOTIMPL: 'Not implemented.'

class exports.ServerError extends OAuthError
  constructor: (message, properties) ->
    properties = defaults {}, properties,
      code: 503
      name: 'server_error'

    super messages[message], properties
