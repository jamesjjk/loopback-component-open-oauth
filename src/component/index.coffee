'use strict'

cors = require 'cors'
path = require 'path'
url = require 'url'
fs  = require 'fs'

{ defaults } = require 'lodash'

STATIC_ROOT = path.join __dirname, 'public'

setupCors = (adminApp, remotes) ->
  corsOptions = remotes.options and remotes.options.cors or
    origin: true
    credentials: true

  adminApp.use cors(corsOptions)

  return

mountAdmin = (loopbackApplication, adminApp, opts) ->
  resourcePath = opts.resourcePath

  if resourcePath[0] isnt '/'
    resourcePath = '/' + resourcePath

  remotes = loopbackApplication.remotes()

  setupCors adminApp, remotes

  return

routes = (loopbackApplication, options) ->
  loopback = loopbackApplication.loopback

  options = defaults({}, options,
    mountPath: '/admin'
    apiInfo: loopbackApplication.get('apiInfo') or {})

  router = new loopback.Router()

  mountAdmin loopbackApplication, router, options

  router.use loopback.static STATIC_ROOT

  router

module.exports = (loopbackApplication, options) ->
  options = defaults {}, options, mountPath: '/admin'

  loopbackApplication.use options.mountPath, routes(loopbackApplication, options)
  loopbackApplication.set 'loopback-component-open-oauth', options

  loopbackApplication.once 'started', ->
    baseUrl = loopbackApplication.get('url').replace /\/$/, ''
    adminPath = options.mountPath or options.route

    console.log 'Browse your OAuth UI at %s%s', baseUrl, adminPath

  return