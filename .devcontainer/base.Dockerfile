FROM ghcr.io/actions/actions-runner:2.323.0

USER root

# ----- Node.js 16 + VSCode向けツール -----
ARG NODE_VERSION=20
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get update \
    && apt-get install -y nodejs wget tar \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g tslint-to-eslint-config typescript eslint \
    && npm cache clean --force > /dev/null 2>&1

# ----- Hugo (Extended) のインストール -----
ARG HUGO_RELEASE="0.139.3"
ARG HUGO_ARCH="linux-amd64"
RUN wget "https://github.com/gohugoio/hugo/releases/download/v${HUGO_RELEASE}/hugo_extended_${HUGO_RELEASE}_${HUGO_ARCH}.deb" \
    && apt-get install -y "./hugo_extended_${HUGO_RELEASE}_${HUGO_ARCH}.deb" \
    && rm "./hugo_extended_${HUGO_RELEASE}_${HUGO_ARCH}.deb"

# ----- Dart Sass のインストール -----
ARG DARTSASS_RELEASE="1.83.0"
ARG DARTSASS_ARCH="linux-x64"
RUN wget "https://github.com/sass/dart-sass/releases/download/${DARTSASS_RELEASE}/dart-sass-${DARTSASS_RELEASE}-${DARTSASS_ARCH}.tar.gz" \
    && tar -x -C ./ -f dart-sass-${DARTSASS_RELEASE}-${DARTSASS_ARCH}.tar.gz \
    && cp -r ./dart-sass/* /usr/local/bin \
    && rm dart-sass-${DARTSASS_RELEASE}-${DARTSASS_ARCH}.tar.gz \
    && rm -r ./dart-sass

# ----- UID 1001 の runner ユーザー作成（CI環境と一致） -----
# RUN getent group runner || groupadd -g 1001 runner \
# && id -u runner >/dev/null 2>&1 || useradd -m -u 1001 -g 1001 runner

# ----- Chromeの依存を明示的にインストール（最小限） -----
RUN apt-get update && apt-get install -y \
    wget gnupg ca-certificates fonts-liberation \
    libasound2 libatk-bridge2.0-0 libc6 libnspr4 libnss3 \
    libx11-xcb1 libxcomposite1 libxdamage1 libxrandr2 \
    xdg-utils libu2f-udev libvulkan1 \
    --no-install-recommends \
 && rm -rf /var/lib/apt/lists/*

# ----- Google Chrome 安定版を追加 -----
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/google-chrome.gpg \
 && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
    > /etc/apt/sources.list.d/google-chrome.list \
 && apt-get update && apt-get install -y google-chrome-stable \
 && rm -rf /var/lib/apt/lists/*

 ENV CHROME_PATH=/usr/bin/google-chrome

# ----- Lighthouseとリンクチェッカーを追加 -----
RUN npm install -g \
    broken-link-checker \
    @lhci/cli

# RUN mkdir -p /home/runner/_work/_tool && \
#     chown -R runner:runner /home/runner

# ----- デフォルトユーザー・作業ディレクトリ -----
USER runner
WORKDIR /home/runner