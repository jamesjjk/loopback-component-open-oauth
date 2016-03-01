###*
# Get a response header.
###

class exports.Response
  constructor: ({ @body, headers }) ->
    @status = 200

    # Store the headers in lower case.
    @headers = {}

    for field of headers
      @headers[field.toLowerCase()] = headers[field]

    return

  get: (field) ->
    @headers[field.toLowerCase()]

  ###*
  # Redirect response.
  ###

  redirect: (url) ->
    @set 'Location', url
    @status = 302

    return

  ###*
  # Set a response header.
  ###

  set: (field, value) ->
    @headers[field.toLowerCase()] = value
    return
