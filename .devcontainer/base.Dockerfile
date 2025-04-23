FROM ghcr.io/actions/actions-runner:2.323.0

 USER root

# ----- Node.js 16 + VSCode向けツール -----
ARG NODE_VERSION=16
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get update \
    && apt-get install -y nodejs wget tar \
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
    RUN getent group runner || groupadd -g 1001 runner \
    && id -u runner >/dev/null 2>&1 || useradd -m -u 1001 -g 1001 runner

# ----- デフォルトユーザー・作業ディレクトリ -----
USER runner
WORKDIR /home/runner