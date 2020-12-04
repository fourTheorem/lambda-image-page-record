'use strict'

const chromeLauncher = require('chrome-launcher')
const CDP = require('chrome-remote-interface')

const log = require('./log')

function browser(chromeClient) {
  const { Page: page } = chromeClient
  async function loadUrl(url) {
    log.info({ url }, 'Loading')
    await page.navigate({ url })
    await page.loadEventFired()
  }

  return {
    loadUrl,
  }
}

function startBrowser() {
  log.info('Starting Chrome')
  return chromeLauncher
    .launch({
      chromeFlags: [
        '--disable-crash-reporter',
        '--disable-extensions',
        '--disable-notifications',
        '--disable-default-apps',
        '--disable-translate',
        '--no-first-run',
        '--no-sandbox',
        '--test-type',
      ],
    })
    .then((chrome) => {
      log.info('Initialising chrome client')
      return CDP({ port: chrome.port })
    })
    .then((client) => {
      log.info('Chrome started')
      client.Network.enable()
      client.Page.enable()
      log.info('Chrome ready')
      return browser(client)
    })
}

module.exports = {
  startBrowser,
}
