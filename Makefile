build:
	docker build -t x  .

run: build
	docker run \
		-v $(HOME)/.aws:/root/.aws \
		-v $(PWD)/data:/data \
		-e DATA_DIR=/data \
		-e BUCKET_NAME=superawesomehappybucket \
		-e AWS_SDK_LOAD_CONFIG=1 \
		-e AWS_PROFILE=$(AWS_PROFILE) \
		--rm \
		-p 9000:8080 x | pino-pretty -t "yyyy-mm-dd HH:MM:ss"
