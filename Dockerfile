FROM debian:10.4-slim

# Install libraries
RUN apt update && \
    apt-get install -y curl unzip && \
    apt-get install -y --no-install-recommends socat

# Create config and data dirs
RUN mkdir -p sia-antfarm/data

# Download sia-antfarm and siad-dev binaries
ARG SIA_ANTFARM_VERSION=v1.0.2
WORKDIR /sia-antfarm
RUN curl -o tag-page.html --fail "https://gitlab.com/NebulousLabs/Sia-Ant-Farm/-/tags/${SIA_ANTFARM_VERSION}" && \
    download_link="https://gitlab.com$(cat tag-page.html | grep job=build | grep -Po '(?<=href=\")[^\"]*')" && \
    curl -o binaries.zip -L --fail "${download_link}" && \
    unzip binaries.zip && \
    mv artifacts/sia* . && \
    rm tag-page.html && \
    rm binaries.zip && \
    rm -r artifacts

# Copy default config
ENV CONFIG=config/basic-renter-5-hosts-docker.json
COPY ${CONFIG} config/

# Set path for sia-antfarm and siad-dev binaries
ENV PATH=/sia-antfarm:$PATH

# Start Ant Farm
COPY run.sh .
ENTRYPOINT ["./run.sh"]