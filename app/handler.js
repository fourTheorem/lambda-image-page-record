'use strict'

const middy = require('@middy/core')
const loggerMiddleware = require('lambda-logger-middleware')

const log = require('./log')
const pageRecorder = require('./page-recorder')

const handleEvent = middy(function ({ url }) {
  return pageRecorder.record(url)
}).use(loggerMiddleware({ logger: log }))

module.exports = {
  handleEvent,
}
