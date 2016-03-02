###*
# Module dependencies.
###

{ defaults } = require 'lodash'
StandardHttpError = require 'standard-http-error'

###*
# Constructor.
###

class exports.OAuthError extends StandardHttpError
  constructor: (messageOrError, properties) ->
    message = if messageOrError instanceof Error then messageOrError.message else messageOrError
    error = if messageOrError instanceof Error then messageOrError else null

    if error
      properties.inner = error

    super properties.code, message, properties
