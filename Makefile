# Azure Resource Manager
ARM_ACCESS_KEY = ""

DESCRIBE           := $(shell git describe --match "v*" --always --tags)
DESCRIBE_PARTS     := $(subst -, ,$(DESCRIBE))

VERSION_TAG        := $(word 1,$(DESCRIBE_PARTS))
VERSION            := $(subst v,,$(VERSION_TAG))

all: build plan apply

build:
	@echo "Building..."
	@podman build . --file containers/Dockerfile --tag docker.io/clincha/terraform-init:${VERSION}

debug: build
	@echo "Debugging..."
	@podman run -it --entrypoint /bin/sh --env="ARM_ACCESS_KEY=${ARM_ACCESS_KEY}" docker.io/clincha/terraform-init:${VERSION}

apply: build
	@echo "Applying..."
	@podman run --entrypoint sh --env="TF_VAR*" --env="ARM_ACCESS_KEY=${ARM_ACCESS_KEY}" docker.io/clincha/terraform-init:${VERSION} -c "terraform init && terraform apply"

plan: build
	@echo "Planning..."
	@podman run --entrypoint sh --env="TF_VAR*" --env="ARM_ACCESS_KEY=${ARM_ACCESS_KEY}" docker.io/clincha/terraform-init:${VERSION} -c "terraform init && terraform plan"

destroy: build
	@echo "Destroying..."
	@podman run --entrypoint sh --env="TF_VAR*" --env="ARM_ACCESS_KEY=${ARM_ACCESS_KEY}" docker.io/clincha/terraform-init:${VERSION} -c "terraform init && terraform destroy"