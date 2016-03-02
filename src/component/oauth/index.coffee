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

routes = (loopbackApplication, options) ->
  loopback = loopbackApplication.loopback

  options = defaults({}, options,
    mountPath: '/oauth'
    apiInfo: loopbackApplication.get('apiInfo') or {})

  router = new loopback.Router()

  remotes = loopbackApplication.remotes()
  setupCors loopbackApplication, remotes

  router.use loopback.static STATIC_ROOT

  router

module.exports = (loopbackApplication, options) ->
  options = defaults {}, options, mountPath: '/oauth'

  loopbackApplication.use options.mountPath, routes(loopbackApplication, options)
  loopbackApplication.set 'loopback-component-open-oauth', options

  loopbackApplication.once 'started', ->
    baseUrl = loopbackApplication.get('url').replace /\/$/, ''
    adminPath = options.mountPath or options.route

    console.log 'Browse your OAuth UI at %s%s', baseUrl, adminPath

  return