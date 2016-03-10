###*
# Get a response header.
###

class exports.Response
  constructor: (options) ->
    { @body, headers } = options

    @headers = {}
    @status = 200

    for field of headers
      if headers.hasOwnProperty(field)
        @headers[field.toLowerCase()] = options.headers[field]

    for property of options
      if options.hasOwnProperty(property) and !@[property]
        @[property] = options[property]

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
