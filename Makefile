STACK_NAME = page-capture
ACCOUNT_ID = $(shell aws sts get-caller-identity --query Account --output text)
REPOSITORY_URI = $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/page-capture

all: check-env create-ecr-stack push create-function-stack

check-env:
ifndef REGION
	$(error REGION is not set)
endif
ifndef BUCKET_NAME
	$(error BUCKET_NAME is not set)
endif

build: check-env
	docker build -t $(REPOSITORY_URI)  .

push: build
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
			--stack-name $(STACK_NAME) \
			--template-body file:///$(PWD)/template-ecr.yaml \

install:
	npm install

run: build install
	docker run \
		-v $(HOME)/.aws:/root/.aws \
		-v $(PWD)/data:/data \
		-e DATA_DIR=/data \
		-e BUCKET_NAME=$(BUCKET_NAME) \
		-e AWS_SDK_LOAD_CONFIG=1 \
		-e AWS_PROFILE=$(AWS_PROFILE) \
		--rm \
		-p 9000:8080 x | pino-pretty -t "yyyy-mm-dd HH:MM:ss"
