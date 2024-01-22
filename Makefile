ARM_ACCESS_KEY = "1234567890"
ANSIBLE_SSH_KEY = "1234567890"
PROXMOX_TERRAFORM_TOKEN_KEY = "1234567890"

DESCRIBE           := $(shell git describe --match "v*" --always --tags)
DESCRIBE_PARTS     := $(subst -, ,$(DESCRIBE))

VERSION_TAG        := $(word 1,$(DESCRIBE_PARTS))
VERSION            := $(subst v,,$(VERSION_TAG))

all: build apply

build:
	@echo "Building"
	@podman build . --tag docker.io/clincha/terraform-init:${VERSION}

apply: build
	@echo "Applying"
	@podman run --env="ARM_ACCESS_KEY=${ARM_ACCESS_KEY}" docker.io/clincha/terraform-init:${VERSION}

debug: build
	@echo "Applying"
	@podman run -it --entrypoint /bin/sh --env="ARM_ACCESS_KEY=${ARM_ACCESS_KEY}" docker.io/clincha/terraform-init:${VERSION}