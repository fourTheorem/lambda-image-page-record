STACK_NAME = page-capture
ACCOUNT_ID = $(shell aws sts get-caller-identity --query Account --output text)
REPOSITORY_URI = $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/$(STACK_NAME)
IMAGE_NAME = $(STACK_NAME)

CONTAINER_NAME = $(STACK_NAME)
all: check-env create-ecr-stack push create-function-stack

check-env:
ifndef REGION
	$(error REGION is not set)
endif
ifndef BUCKET_NAME
	$(error BUCKET_NAME is not set)
endif

build:
	docker build -t $(IMAGE_NAME) .

push: check-env build
	docker tag $(IMAGE_NAME) $(REPOSITORY_URI)
	aws ecr get-login-password --region $(REGION) | docker login --username AWS --password-stdin $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com
	docker push $(REPOSITORY_URI)

create-function-stack:
	aws cloudformation create-stack --region $(REGION) \
			--stack-name $(STACK_NAME)-fn \
			--template-body file:///$(PWD)/template.yaml \
			--parameters ParameterKey=BucketName,ParameterValue=$(BUCKET_NAME) ParameterKey=ImageUri,ParameterValue=$(REPOSITORY_URI):latest \
			--capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND

create-ecr-stack:
	aws cloudformation create-stack --region $(REGION) \
			--stack-name $(STACK_NAME)-ecr \
			--template-body file:///$(PWD)/cf-template-ecr.yaml \

install: build
	docker run --rm -it \
		-v $(PWD)/app:/app \
		--entrypoint=npm \
		$(IMAGE_NAME) \
		install

bash:
	docker run --rm -it \
		-v $(PWD)/app:/app \
		--name $(CONTAINER_NAME)_bash \
		--entrypoint=/bin/bash \
		$(IMAGE_NAME)

debug:
	EXTRA_RUN_ARGS="-e AWS_LAMBDA_EXEC_WRAPPER=/app/debug-wrapper.sh -p 9229:9229" make run

run:
	docker run \
		-v $(HOME)/.aws:/root/.aws \
		-v $(PWD)/data:/data \
		-v $(PWD)/app:/app \
		-e DATA_DIR=/data \
		-e BUCKET_NAME=$(BUCKET_NAME) \
		-e AWS_SDK_LOAD_CONFIG=1 \
		-e AWS_PROFILE=$(AWS_PROFILE) \
		$(EXTRA_RUN_ARGS) \
		--rm -i --name $(CONTAINER_NAME) \
		-p 9000:8080 $(IMAGE_NAME) | \
	docker run -i --rm --name $(CONTAINER_NAME)_pino \
		--entrypoint=node $(IMAGE_NAME) \
		/app/node_modules/.bin/pino-pretty
