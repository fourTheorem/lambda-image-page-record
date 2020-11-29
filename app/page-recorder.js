'use strict'

const childProcess = require('child_process')
const fs = require('fs')
const { promisify } = require('util')
const exec = promisify(childProcess.exec)
const AWS = require('aws-sdk')
const webdriver = require('selenium-webdriver')

const log = require('./log')

const VID_EXT = 'mov'
const { DATA_DIR, BUCKET_NAME, DISPLAY } = process.env
if (!BUCKET_NAME) {
  throw new Error('BUCKET_NAME is required')
}
const DISPLAY_NUM = Number(DISPLAY.split(':')[1])
const RESOLUTION = '1280x720'
const OUTPUT_FILE = `${DATA_DIR || '/tmp'}/out.${VID_EXT}`
const s3 = new AWS.S3()

const xvfbCmd = `Xvfb :${DISPLAY_NUM} -screen 0 ${RESOLUTION}x24`
log.info({ xvfbCmd }, 'Starting Xvfb')

exec(xvfbCmd).catch((err) => {
  log.error(err, 'Xvfb failed')
  process.exit(1)
})

log.info('Starting Firefox')

const driver = new webdriver.Builder().forBrowser('firefox').build()

function record(url) {
  const site = url.replace(/\W+/g, '_')
  const file = new Date().toISOString().replace(/[-:.]+/g, '_') + '.' + VID_EXT

  const key = `capture/${site}/${file}`
  return new Promise((resolve) => {
    const ffCmd = `ffmpeg -nostats -nostdin -draw_mouse 0 -y -f x11grab -s ${RESOLUTION} -i :${DISPLAY_NUM} -vcodec qtrle ${OUTPUT_FILE}`
    log.info({ ffCmd }, 'Running ffmpeg')
    const childPromise = exec(ffCmd)
    const proc = childPromise.child
    proc.on('exit', (code) => {
      log.info({ code }, 'ffmpeg exited')
      resolve(childPromise)
    })
    // Go to page
    driver.get(url)
    setTimeout(() => {
      proc.kill('SIGINT')
    }, 30000)
  })
    .then(({ stderr, stdout }) => log.info({ stderr, stdout }, 'ffmpeg output'))
    .catch((err) => {
      if (!err.killed) {
        throw err
      }
    })
    .then(() =>
      s3
        .upload({
          Bucket: BUCKET_NAME,
          Key: key,
          Body: fs.readFileSync(OUTPUT_FILE),
        })
        .promise()
        .then(() => key)
    )
    .then((key) => log.info({ key }, 'Capture complete'))
}

module.exports = {
  record,
}
