###*
# Module dependencies.
###

typeis = require 'type-is'

{ InvalidArgumentError } = require './errors/invalid-argument-error'

###*
# Get a request header.
###

class exports.Request
  constructor: (options) ->
    { headers, @body, @method, @query } = options

    if not headers
      throw new InvalidArgumentError 'HEADERS'

    if not @method
      throw new InvalidArgumentError 'METHOD'

    if not @query
      throw new InvalidArgumentError 'QUERY'

    @headers = {}

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
  # Check if the content-type matches any of the given mime type.
  ###

  is: (types) ->
    if not Array.isArray(types)
      types = [].slice.call(arguments)

    typeis(this, types) or false
