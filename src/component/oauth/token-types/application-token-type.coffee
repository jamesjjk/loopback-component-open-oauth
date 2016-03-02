###*
# Module dependencies.
###

###*
# Constructor.
###

class ApplicationTokenType
  constructor: (data = {}) ->
    return

  valueOf: ->

  @getTokenFromRequest: (request) ->
    headerToken = request.get 'x-application-id'

    if headerToken
      return appId: headerToken

    return

module.exports = ApplicationTokenType