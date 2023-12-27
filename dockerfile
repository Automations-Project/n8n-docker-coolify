ARG NODE_VERSION=18
FROM n8nio/base:${NODE_VERSION}

# Download the remote .env file
RUN curl -o .env https://github.com/Automations-Project/n8n-docker-coolify/raw/main/.env

ARG N8N_VERSION
RUN if [ -z "$N8N_VERSION" ] ; then echo "The N8N_VERSION argument is missing!" ; exit 1; fi

ENV N8N_VERSION=${N8N_VERSION}
ENV NODE_ENV=production
ENV N8N_RELEASE_TYPE=stable

# Install necessary dependencies as root
USER root

RUN set -eux; \
    apkArch="$(apk --print-arch)"; \
    case "$apkArch" in \
    'armv7') apk --no-cache add --virtual build-dependencies python3 build-base;; \
    esac && \
    npm install -g --omit=dev n8n@${N8N_VERSION} && \
    case "$apkArch" in \
    'armv7') apk del build-dependencies;; \
    esac && \
    rm -rf /usr/local/lib/node_modules/n8n/node_modules/@n8n/chat && \
    rm -rf /usr/local/lib/node_modules/n8n/node_modules/n8n-design-system && \
    rm -rf /usr/local/lib/node_modules/n8n/node_modules/n8n-editor-ui/node_modules && \
    find /usr/local/lib/node_modules/n8n -type f -name "*.ts" -o -name "*.js.map" -o -name "*.vue" | xargs rm -f && \
    rm -rf /root/.npm
    npm install -g node-html-parser ssh2-sftp-client chance jimp uuid yup simple-crypto-js

# Switch back to the node user
USER node

COPY docker-entrypoint.sh /

RUN \
    mkdir .n8n && \
    chown node:node .n8n

ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]
