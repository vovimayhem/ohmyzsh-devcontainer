ARG DEBIAN_VARIANT=bullseye
FROM debian:${DEBIAN_VARIANT}-slim AS runtime

# Install zsh:
RUN <<EOF
apt-get update
apt-get install -y --no-install-recommends ca-certificates git zsh
rm -rf rm -rf /var/lib/apt/lists/*
EOF

# Set as the default command:
CMD ["zsh"]

FROM runtime AS ohmyzsh
RUN useradd -r -m --shell /usr/bin/zsh -c "Example User,,," example-user
USER example-user
RUN git clone --depth=1 \
  -c core.eol=lf \
  -c core.autocrlf=false \
  -c fsck.zeroPaddedFilemode=ignore \
  -c fetch.fsck.zeroPaddedFilemode=ignore \
  -c receive.fsck.zeroPaddedFilemode=ignore \
  "https://github.com/ohmyzsh/ohmyzsh" /home/example-user/.oh-my-zsh

FROM runtime AS development

RUN apt-get update \
 && apt-get install -y --no-install-recommends gpg sudo

# Install node from the official image
COPY --from=node:hydrogen-bullseye-slim /opt/yarn* /opt/yarn
COPY --from=node:hydrogen-bullseye-slim /usr/local/bin/node /usr/local/bin/node
COPY --from=node:hydrogen-bullseye-slim /usr/local/include/node /usr/local/include/node
COPY --from=node:hydrogen-bullseye-slim /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn \
 && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
 && ln -s /opt/yarn/bin/yarnpkg /usr/local/bin/yarnpkg \
 && ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
 && ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# Receive the developer user's UID and USER:
ARG DEVELOPER_UID=1000
ARG DEVELOPER_USERNAME=you

# Replicate the developer user in the development image:
RUN addgroup --gid ${DEVELOPER_UID} ${DEVELOPER_USERNAME} \
 ;  useradd -r -m -u ${DEVELOPER_UID} --gid ${DEVELOPER_UID} \
    --shell /bin/bash -c "Developer User,,," ${DEVELOPER_USERNAME}

# Add the developer user to the sudoers list:
RUN echo "${DEVELOPER_USERNAME} ALL=(ALL) NOPASSWD:ALL" | tee "/etc/sudoers.d/${DEVELOPER_USERNAME}"

# Ensure that the home directory, the app path and bundler directories are owned
# by the developer user:
# (A workaround to a side effect of setting WORKDIR before creating the user)
RUN mkdir -p /workspaces/ohmyzsh-devcontainer \
 && chown -R ${DEVELOPER_USERNAME}:${DEVELOPER_USERNAME} /home/${DEVELOPER_USERNAME} \
 && chown -R ${DEVELOPER_USERNAME}:${DEVELOPER_USERNAME} /workspaces/ohmyzsh-devcontainer

USER ${DEVELOPER_USERNAME}

COPY --chown=${DEVELOPER_USERNAME}:${DEVELOPER_USERNAME} ./zshrc.zsh-template /home/${DEVELOPER_USERNAME}/.zshrc
COPY --from=ohmyzsh --chown=${DEVELOPER_USERNAME}:${DEVELOPER_USERNAME} /home/example-user/.oh-my-zsh /home/${DEVELOPER_USERNAME}/.oh-my-zsh
COPY --chown=${DEVELOPER_USERNAME}:${DEVELOPER_USERNAME} ./devcontainers.zsh-theme /home/${DEVELOPER_USERNAME}/.oh-my-zsh/custom/themes/

FROM ohmyzsh AS builder
COPY --chown=example-user:example-user ./zshrc.zsh-template /home/example-user/.zshrc
COPY --chown=example-user:example-user ./devcontainers.zsh-theme /home/example-user/.oh-my-zsh/custom/themes/
RUN cd /home/example-user/.oh-my-zsh && git repack -a -d -f --depth=1 --window=1

FROM runtime AS release
RUN useradd -r -m --shell /usr/bin/zsh -c "Example User,,," example-user
COPY --from=builder --chown=example-user:example-user /home/example-user /home/example-user
USER example-user
