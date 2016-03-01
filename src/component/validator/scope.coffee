debug = require('debug')('loopback:oauth2:scope')
pathToRegexp = require('path-to-regexp')
Promise = require 'bluebird'

{ InvalidScopeError } = require './errors/invalid-scope-error'

###*
# Validate if the oAuth 2 scope is satisfied
#
# @param {Object} options Options object
# @returns {validateScope}
###

toLowerCase = (m) ->
  m.toLowerCase()

###*
# Normalize scope to string[]
# @param {String|String[]} scope
# @returns {String[]}
###

normalizeScope = (scope) ->
  if not scope
    return []

  list = undefined

  if Array.isArray scope
    list = [].concat scope
  else if typeof scope is 'string'
    list = scope.split(/[\s,]+/g).filter(Boolean)
  else
    throw new Error 'Invalid items: ' + scope

  list

###*
# Check if one of the scopes is in the allowedScopes array
# @param {String[]} allowedScopes An array of required scopes
# @param {String[]} scopes An array of granted scopes
# @returns {boolean}
###

isScopeAllowed = (allowedScopes, tokenScopes) ->
  allowedScopes = normalizeScope allowedScopes
  tokenScopes = normalizeScope tokenScopes

  if allowedScopes.length is 0
    return true

  i = 0
  n = allowedScopes.length

  while i < n
    if tokenScopes.indexOf(allowedScopes[i]) isnt -1
      return true
    i++

  false

###*
# Check if the requested scopes are covered by authorized scopes
# @param {String|String[]) requestedScopes
# @param {String|String[]) authorizedScopes
# @returns {boolean}
###

isScopeAuthorized = (requestedScopes, authorizedScopes) ->
  requestedScopes = normalizeScope requestedScopes
  authorizedScopes = normalizeScope authorizedScopes

  if requestedScopes.length is 0
    return true

  i = 0
  n = requestedScopes.length

  while i < n
    if authorizedScopes.indexOf(requestedScopes[i]) is -1
      return false
    i++

  true

loadScopes = (scopes) ->
  scopeMapping = {}

  if typeof scopes is 'object'
    for s of scopes
      routes = []
      entries = scopes[s]

      debug 'Scope: %s routes: %j', s, entries

      if Array.isArray(entries)
        j = 0
        k = entries.length

        while j < k
          route = entries[j]

          if typeof route is 'string'
            routes.push
              methods: [ 'all' ]
              path: route
              regexp: pathToRegexp(route, [], end: false)
          else
            methods = normalizeScope(methods)

            if methods.length is 0
              methods.push 'all'

            methods = methods.map(toLowerCase)

            routes.push
              methods: methods
              path: route.path
              regexp: pathToRegexp(route.path, [], end: false)

          j++
      else
        debug 'Routes must be an array: %j', entries

      scopeMapping[s] = routes
  else if typeof scopes is 'string'
    scopes = normalizeScope(scopes)

    i = 0
    n = scopes.length

    while i < n
      scopeMapping[scopes[i]] = [ {
        methods: 'all'
        path: '/.+'
        regexp: /\/.+/
      } ]

      i++

  scopeMapping

findMatchedScopes = (req, scopeMapping) ->
  matchedScopes = []

  method = req.method.toLowerCase()
  url = req.originalUrl

  for s of scopeMapping
    routes = scopeMapping[s]

    i = 0
    n = routes.length

    while i < n
      route = routes[i]

      if route.methods.indexOf('all') isnt -1 or route.methods.indexOf(method) isnt -1
        debug 'url: %s, regexp: %s', url, route.regexp
        index = url.indexOf('?')

        if index isnt -1
          url = url.substring(0, index)

        if route.regexp.test(url)
          matchedScopes.push s
      i++

  matchedScopes

class exports.scopeValidate
  constructor: (options = {}) ->
    configuredScopes = options.checkScopes || options.scopes || options.scope

  validate: (req, res) ->
    defer = Peomise.defer()

    scopes = req.accessToken and req.accessToken.scopes
    debug 'Scopes of the access token: ', scopes

    scopeMapping = loadScopes configuredScopes
    debug 'Scope mapping: ', scopeMapping

    allowedScopes = findMatchedScopes req, scopeMapping
    debug 'Allowed scopes: ', allowedScopes

    if isScopeAllowed allowedScopes, scopes
      defer.resolve()
    else
      debug 'Insufficient scope: ', scopes
      defer.reject new InvalidScopeError 'invalid'

    defer.promise
