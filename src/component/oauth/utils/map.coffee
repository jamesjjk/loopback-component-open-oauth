
###*
# Get deep property
#
# @param  {Object} source
# @param  {Array} chain
# @return {undefined}
###

getDeepProperty = (source, chain) ->
  key = chain.shift()

  # there's nothing to see here, move along
  if source[key] == undefined
    return

  # if property is null then return null
  if source[key] == null
    return null

  # if property is false then return false
  if source[key] == false
    return false

  # if property is empty then return empty
  if source[key] == ''
    return ''

  # we're at the end of the line, this is the value you're looking for
  if source[key] and chain.length == 0
    return source[key]

  # traverse the object
  if source[key] != undefined
    return getDeepProperty(source[key], chain)

  return

###*
# Set deep property
#
# @param {Object} target
# @param {Array} chain
# @param {any} value
###

setDeepProperty = (target, chain, value) ->
  key = chain.shift()

  if chain.length == 0
    if value != undefined
      target[key] = value
  else
    if !target[key]
      target[key] = {}

    setDeepProperty target[key], chain, value

  return

###*
# Exports
#
# @param  {Object} mapping
# @param  {Object} source
# @param  {Object} target
###

module.exports = (mapping, source, target) ->
  Object.keys(mapping).forEach (path) ->
    from = mapping[path]
    to = path.split('.')

    if typeof from == 'function'
      value = from(source)

      if value
        setDeepProperty target, to, value
    else
      setDeepProperty target, to, getDeepProperty(source, from.split('.'))

    return
  return
