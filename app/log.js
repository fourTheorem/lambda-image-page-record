const pino = require('pino')

const { name } = require('./package.json').name

module.exports = pino({ name, level: 'debug' })
