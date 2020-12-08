'use strict'

const chromium = require('chrome-aws-lambda')

const log = require('./log')

function browserContext(page) {
  async function loadUrl(url) {
    log.info({ url }, 'Loading')
    await page.goto(url)
  }

  return {
    loadUrl,
  }
}

async function startBrowser() {
  log.info('Starting Chrome')
  const puppeteerOptions = {
    args: chromium.args,
    headless: false,
    dumpio: true,
  }
  log.info({ puppeteerOptions }, 'Launching with Puppeteer')
  const browser = await chromium.puppeteer.launch(puppeteerOptions)
  log.info('Chrome started')
  const page = await browser.newPage()
  log.info('Chrome ready')
  return browserContext(page)
}

module.exports = {
  startBrowser,
}
