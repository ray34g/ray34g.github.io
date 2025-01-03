# [Choice] Node.js version (use -bullseye variants on local arm64/Apple Silicon): 18, 16, 14, 18-bullseye, 16-bullseye, 14-bullseye, 18-buster, 16-buster, 14-buster
ARG VARIANT=16-bullseye
FROM mcr.microsoft.com/vscode/devcontainers/typescript-node:${VARIANT}

# Install tslint, typescript. eslint is installed by javascript image
ARG NODE_MODULES="tslint-to-eslint-config typescript"
COPY library-scripts/meta.env /usr/local/etc/vscode-dev-containers
RUN su node -c "umask 0002 && npm install -g ${NODE_MODULES}" \
    && npm cache clean --force > /dev/null 2>&1

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>
ARG HUGO_RELEASE="0.139.3"
ARG ARCH="linux-amd64"
RUN wget "https://github.com/gohugoio/hugo/releases/download/v${HUGO_RELEASE}/hugo_extended_${HUGO_RELEASE}_${ARCH}.deb" \
    && apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends "./hugo_extended_${HUGO_RELEASE}_${ARCH}.deb" \
    && rm "./hugo_extended_${HUGO_RELEASE}_${ARCH}.deb"
    
ARG DARTSASS_RELEASE="1.83.0"
ARG DARTSASS_ARCH="linux-x64"
RUN wget "https://github.com/sass/dart-sass/releases/download/${DARTSASS_RELEASE}/dart-sass-${DARTSASS_RELEASE}-${DARTSASS_ARCH}.tar.gz" \
    && export DEBIAN_FRONTEND=noninteractive \
    && tar -v -x -C ./ -f dart-sass-${DARTSASS_RELEASE}-${DARTSASS_ARCH}.tar.gz \
    && cp -r ./dart-sass/* /bin \
    && rm dart-sass-${DARTSASS_RELEASE}-${DARTSASS_ARCH}.tar.gz \
    && rm -r ./dart-sass
# [Optional] Uncomment if you want to install an additional version of node using nvm
# ARG EXTRA_NODE_VERSION=10
# RUN su node -c "source /usr/local/share/nvm/nvm.sh && nvm install ${EXTRA_NODE_VERSION}"