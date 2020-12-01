# Lambda Image Page Recorder

A sample AWS Lambda function using a container image.
This application is based on the AWS-provided Node.js Lambda base image.
It uses Xvfb, ffmpeg and Firefox WebDriver to record a 30 second video of a requested web page. The resulting video capture is uploaded to S3.

## Building and Running Locally

1. `npm install`
2. `make run`


## Building and Running with AWS SAM

...coming really soon...

