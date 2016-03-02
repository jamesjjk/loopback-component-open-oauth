###*
# Module dependencies.
###

typeis = require 'type-is'

{ InvalidArgumentError } = require './errors/invalid-argument-error'

###*
# Get a request header.
###

class exports.Request
  constructor: ({ headers, @body, @method, @query }) ->
    if not headers
      throw new InvalidArgumentError 'HEADERS'

    if not @method
      throw new InvalidArgumentError 'METHOD'

    if not @query
      throw new InvalidArgumentError 'QUERY'

    # Store the headers in lower case.
    @headers = {}

    for field of headers
      @headers[field.toLowerCase()] = headers[field]

    return

  get: (field) ->
    @headers[field.toLowerCase()]

  ###*
  # Check if the content-type matches any of the given mime type.
  ###

  is: (types) ->
    if not Array.isArray(types)
      types = [].slice.call(arguments)

    typeis(this, types) or false
