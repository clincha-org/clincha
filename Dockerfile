FROM docker.io/clincha/terraform-provider-proxmox:1.0.4

RUN apk add py3-pip
RUN apk add gcc musl-dev python3-dev libffi-dev openssl-dev cargo make

RUN python3 -m venv .venv
RUN .venv/bin/pip install --no-cache-dir -U pip setuptools azure-cli
ENV PATH="/app/.venv/bin:$PATH"

COPY terraform .