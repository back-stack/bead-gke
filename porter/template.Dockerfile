# syntax=docker/dockerfile-upstream:1.4.0
# This is a template Dockerfile for the bundle's invocation image
# You can customize it to use different base images, install tools and copy configuration files.
#
# Porter will use it as a template and append lines to it for the mixins
# and to set the CMD appropriately for the CNAB specification.
#
# Add the following line to porter.yaml to instruct Porter to use this template
# dockerfile: template.Dockerfile

# You can control where the mixin's Dockerfile lines are inserted into this file by moving the "# PORTER_*" tokens
# another location in this file. If you remove a token, its content is appended to the end of the Dockerfile.

# Porter targets linux/amd64 by default. Change the --platform flag to target a different platform
FROM --platform=linux/amd64 debian:stable-slim

# PORTER_INIT

RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# Install gcloud cli
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt \
    apt-get update && apt-get install -y ca-certificates apt-transport-https gnupg curl gettext-base google-cloud-sdk

# PORTER_MIXINS

# Use the BUNDLE_DIR build argument to copy files into the bundle's working directory
COPY --link . ${BUNDLE_DIR}
