FROM ghcr.io/actions/actions-runner:2.325.0 AS base
USER root

ARG NODE_VERSION=24
ARG HUGO_RELEASE="0.154.2"
ARG HUGO_ARCH="linux-amd64"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg wget tar unzip zip \
    git rsync tree build-essential \
    jq ripgrep fd-find \
    procps iproute2 lsof netcat-openbsd dnsutils \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
 && apt-get update && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/* \
 && npm install -g typescript eslint \
 && npm cache clean --force > /dev/null 2>&1

RUN wget "https://github.com/gohugoio/hugo/releases/download/v${HUGO_RELEASE}/hugo_${HUGO_RELEASE}_${HUGO_ARCH}.deb" \
 && apt-get update && apt-get install -y "./hugo_${HUGO_RELEASE}_${HUGO_ARCH}.deb" \
 && rm -rf /var/lib/apt/lists/* \
 && rm "./hugo_${HUGO_RELEASE}_${HUGO_ARCH}.deb"

USER runner
WORKDIR /home/runner

# --- devcontainer ---
FROM base AS dev
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    shellcheck \
 && rm -rf /var/lib/apt/lists/*
USER runner

# --- runner ---
FROM base AS runner
USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    fonts-liberation \
    libasound2 libatk-bridge2.0-0 libc6 libnspr4 libnss3 \
    libx11-xcb1 libxcomposite1 libxdamage1 libxrandr2 \
    xdg-utils libu2f-udev libvulkan1 \
 && rm -rf /var/lib/apt/lists/*

RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/google-chrome.gpg \
 && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
    > /etc/apt/sources.list.d/google-chrome.list \
 && apt-get update && apt-get install -y --no-install-recommends google-chrome-stable \
 && rm -rf /var/lib/apt/lists/*

ENV CHROME_PATH=/usr/bin/google-chrome

RUN npm install -g broken-link-checker @lhci/cli \
 && npm cache clean --force > /dev/null 2>&1

USER runner
WORKDIR /home/runner
