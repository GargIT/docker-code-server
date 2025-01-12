FROM ghcr.io/linuxserver/baseimage-ubuntu:bionic

# set version label
ARG BUILD_DATE
ARG VERSION
ARG CODE_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="GargIT"

# environment settings
ENV HOME="/config"

RUN \
  echo "**** install node repo ****" && \
  apt-get update && \
  apt-get install -y \
    gnupg && \
  curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
  echo 'deb https://deb.nodesource.com/node_14.x bionic main' \
    > /etc/apt/sources.list.d/nodesource.list && \
  curl -s https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo 'deb https://dl.yarnpkg.com/debian/ stable main' \
    > /etc/apt/sources.list.d/yarn.list && \
  echo "**** install build dependencies ****" && \
  apt-get update && \
  apt-get install -y \
    build-essential \
    autoconf \
    automake \
    autopoint \
    libtool \
    flex \
    bison \
    libssl-dev \
    gettext \
    libgettextpo-dev \
    libjansson-dev \
    libboost-dev \
    libpq-dev \
    zlib1g-dev \
    libcurl4 \
    libcurl4-openssl-dev \
    libx11-dev \
    libxkbfile-dev \
    libsecret-1-dev \
    default-jre \
    pkg-config && \
  echo "**** install runtime dependencies ****" && \
  apt-get install -y \
    git \
    jq \
    nano \
    net-tools \
    nodejs \
    sudo \
    htop \
    apache2 \
    apache2-utils \
    rsync \
    tomcat9 \
    unzip \
    yarn && \
  echo "**** install code-server ****" && \
  if [ -z ${CODE_RELEASE+x} ]; then \
    CODE_RELEASE=$(curl -sX GET https://registry.yarnpkg.com/code-server \
    | jq -r '."dist-tags".latest' | sed 's|^|v|'); \
  fi && \
  CODE_VERSION=$(echo "$CODE_RELEASE" | awk '{print substr($1,2); }') && \
  yarn config set network-timeout 600000 -g && \
  yarn --production --verbose --frozen-lockfile global add code-server@"$CODE_VERSION" && \
  yarn cache clean && \
  echo "**** clean up ****" && \
  apt-get autoremove -y && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

RUN \
  echo "**** install sencha ****" && \
  curl -o /cmd.run.zip https://cdn.sencha.com/cmd/7.3.1.27/no-jre/SenchaCmd-7.3.1.27-linux-amd64.sh.zip && \
  unzip -p /cmd.run.zip > /cmd-install.run && \
  chmod +x /cmd-install.run && \
  /cmd-install.run -q -dir /opt/Sencha/Cmd/7.3.1.27 && \
  rm /cmd-install.run /cmd.run.zip && \
  sed -i "s/^\-Xmx.*/\-Xmx2096m/" /opt/Sencha/Cmd/7.3.1.27/sencha.vmoptions

ENV PATH=$PATH:$HOME/workspace:/opt/Sencha/Cmd
# add local files
COPY /root /
COPY /usr /

# ports and volumes
EXPOSE 8443
EXPOSE 80