;(function () {
  var source, origin

  /**
   * Initialize browser state
   */

  var re = /\bop\.state=([^\s;]*)/
  var stateCookie = document.cookie.match(re)
  var opbs = stateCookie && stateCookie.pop()
  var localStorage = window.localStorage
  var EventSource = window.EventSource
  var CryptoJS = window.CryptoJS

  localStorage['auth.op.state'] = opbs

  /**
   * Get browser state
   */

  function getOPBrowserState () {
    return localStorage['auth.op.state']
  }

  /**
   * Set browser state
   */

  function setOPBrowserState (event) {
    var key = 'auth.op.state'
    var current = localStorage[key]
    var update = event.data

    if (current !== update) {
      document.cookie = 'auth.op.state=' + update
      localStorage['auth.op.state'] = update
    }
  }

  /**
   * Server Sent Events
   */

  var updates = new EventSource('/session/events')
  updates.addEventListener('update', setOPBrowserState, false)

  /**
   * Watch localStorage and keep the RP updated
   */

  function pushToRP (event) {
    if (source) {
      console.log('updating RP: changed')
      source.postMessage('changed', origin)
    } else {
      console.log('updateRP called but source undefined')
    }
  }

  window.addEventListener('storage', pushToRP, false)

  /**
   * Compare session state
   */

  function compareSessionState (rpss, opss) {
    return (rpss === opss) ? 'unchanged' : 'changed'
  }

  /**
   * Respond to RP postMessage
   */

  function respondToRPMessage (event) {
    var parser, messenger, clientId, rpss,
      salt, opbs, input, opss, comparison

    // Parse message origin
    origin = event.origin
    parser = document.createElement('a')
    parser.href = document.referrer
    messenger = parser.protocol + '//' + parser.host

    // Ignore the message if origin doesn't match
    if (origin !== messenger) {
      return
    }

    // get a reference to the source so we can message it
    // immediately in response to a change in sessionState
    source = event.source

    // Parse the message
    clientId = event.data.split(' ')[0]
    rpss = event.data.split(' ')[1]
    salt = rpss.split('.')[1]

    // Validate message syntax
    if (!clientId || !rpss || !salt) {
      event.source.postMessage('error', origin)
    }

    // Get the OP browser state
    opbs = getOPBrowserState()

    // Recalculate session state for comparison
    input = [clientId, origin, opbs, salt].join(' ')
    opss = [CryptoJS.SHA256(input), salt].join('.')

    // Compare the RP session state with the OP session state
    comparison = compareSessionState(rpss, opss)

    // Compare session state and reply to RP
    event.source.postMessage(comparison, origin)
  }

  window.addEventListener('message', respondToRPMessage, false)
})()
