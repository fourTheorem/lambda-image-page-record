'use strict'

const childProcess = require('child_process')
const fs = require('fs')
const { promisify } = require('util')
const exec = promisify(childProcess.exec)
const { spawn } = childProcess

const AWS = require('aws-sdk')

const log = require('./log')
const { startBrowser } = require('./browser')

const VID_EXT = 'mov'
const { DATA_DIR, BUCKET_NAME, DISPLAY } = process.env
if (!BUCKET_NAME) {
  throw new Error('BUCKET_NAME is required')
}
const DISPLAY_NUM = Number(DISPLAY.split(':')[1])
const RESOLUTION = '1280x720'
const OUTPUT_FILE = `${DATA_DIR || '/tmp'}/out.${VID_EXT}`
const RECORD_TIME = 10000

const s3 = new AWS.S3()

const xvfbCmd = `Xvfb :${DISPLAY_NUM} -screen 0 ${RESOLUTION}x24`
log.info({ xvfbCmd }, 'Starting Xvfb')
const [prog, ...args] = xvfbCmd.split(' ')
spawn(prog, args)
log.info('Xvfb started')
const browserPromise = startBrowser().then((browser) => {
  log.info('Got browser')
  return browser
})

async function record(url) {
  log.info({ url }, 'Record request')
  const site = url.replace(/\W+/g, '_')
  const file = new Date().toISOString().replace(/[-:.]+/g, '_') + '.' + VID_EXT
  const key = `capture/${site}/${file}`

  const browser = await browserPromise
  log.info('Starting FFmpeg')
  const ffCmd = `ffmpeg -nostats -nostdin -draw_mouse 0 -y -f x11grab -s ${RESOLUTION} -i :${DISPLAY_NUM} -vcodec qtrle ${OUTPUT_FILE}`
  log.info({ ffCmd }, 'Running ffmpeg')
  const childPromise = exec(ffCmd)
  const proc = childPromise.child
  proc.on('exit', (code) => log.info({ code }, 'ffmpeg exited'))

  await browser.loadUrl(url)
  setTimeout(() => proc.kill('SIGINT'), RECORD_TIME)

  try {
    await childPromise
  } catch (err) {
    if (!err.killed) {
      throw err
    }
  }

  log.info(`Uploading to s3://${BUCKET_NAME}/${key}`)
  await s3
    .upload({
      Bucket: BUCKET_NAME,
      Key: key,
      Body: fs.readFileSync(OUTPUT_FILE),
    })
    .promise()
  log.info({ key }, 'Capture complete')
}

module.exports = {
  record,
}
