###*
# Validation rules.
###

rules =
  NCHAR: /^[\u002D|\u002E|\u005F|\w]+$/
  NQCHAR: /^[\u0021|\u0023-\u005B|\u005D-\u007E]+$/
  NQSCHAR: /^[\u0020-\u0021|\u0023-\u005B|\u005D-\u007E]+$/
  UNICODECHARNOCRLF: /^[\u0009|\u0020-\u007E|\uD7FF|\uE000-\uFFFD|\u10000-\u10FFFF]+$/
  URI: /^[a-zA-Z][a-zA-Z0-9+.-]+:/
  VSCHAR: /^[\u0020-\u007E]+$/

###*
# Export validation functions.
###

module.exports =
  nchar: (value) ->
    rules.NCHAR.test value

  nqchar: (value) ->
    rules.NQCHAR.test value

  nqschar: (value) ->
    rules.NQSCHAR.test value

  uchar: (value) ->
    rules.UNICODECHARNOCRLF.test value

  uri: (value) ->
    rules.URI.test value

  vschar: (value) ->
    rules.VSCHAR.test value
