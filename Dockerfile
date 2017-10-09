FROM ubuntu:14.04
FROM python:3


RUN curl -sL https://deb.nodesource.com/setup_6.x | bash
#RUN DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common python-software-properties
#RUN add-apt-repository ppa:chris-lea/redis-server

ENV DEBIAN_FRONTEND=noninteractive

MAINTAINER Alexander Swensen <alex.swensen@gmail.com>

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install Required Packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y \
    python-pip build-essential python-dev mysql-server \
    nginx python-software-properties \
    software-properties-common

RUN apt-get update \
  && apt-get install -y \
    git mercurial xvfb \
    locales sudo openssh-client ca-certificates tar gzip parallel \
    net-tools netcat unzip zip bzip2 \
    libgtk3.0-cil-dev libasound2 libasound2 libdbus-glib-1-2 libdbus-1-3

#========================================
# Add normal user with passwordless sudo
#========================================

RUN groupadd --gid 3434 circleci \
  && useradd --uid 3434 --gid circleci --shell /bin/bash --create-home circleci \
  && echo 'circleci ALL=NOPASSWD: ALL' >> /etc/sudoers.d/50-circleci \
  && echo 'Defaults    env_keep += "DEBIAN_FRONTEND"' >> /etc/sudoers.d/env_keep

# Install latest npm
#RUN npm install -g npm@latest

# Install Redis from source
ENV REDIS_VERSION 4.0.2
ENV REDIS_DOWNLOAD_URL http://download.redis.io/releases/redis-$REDIS_VERSION.tar.gz
ENV REDIS_DOWNLOAD_SHA1 d2588569a35531fcdf03ff05cf0e16e381bc278f

RUN buildDeps='gcc libc6-dev make' \
    && set -x \
    && apt-get update &&  apt-get install -y $buildDeps --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && wget -O redis.tar.gz "$REDIS_DOWNLOAD_URL" \
    && echo "$REDIS_DOWNLOAD_SHA1 *redis.tar.gz" | sha1sum -c - \
    && mkdir -p /usr/src/redis \
    && tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 \
    && rm redis.tar.gz \
    && make -C /usr/src/redis \
    && make -C /usr/src/redis install \
    && rm -r /usr/src/redis



USER circleci

# VIRTUALENV - Set up virtualenv and virtualenvwrapper, can use whichever you prefer
RUN sudo pip install virtualenv virtualenvwrapper


# install java 8
#
RUN if grep -q Debian /etc/os-release && grep -q jessie /etc/os-release; then \
    echo "deb http://http.us.debian.org/debian/ jessie-backports main" | sudo tee -a /etc/apt/sources.list \
    && echo "deb-src http://http.us.debian.org/debian/ jessie-backports main" | sudo tee -a /etc/apt/sources.list \
    && sudo apt-get update; sudo apt-get install -y -t jessie-backports openjdk-8-jre openjdk-8-jre-headless openjdk-8-jdk openjdk-8-jdk-headless \
  ; else \
    sudo apt-get update; sudo apt-get install -y openjdk-8-jre openjdk-8-jre-headless openjdk-8-jdk openjdk-8-jdk-headless \
  ; fi

# install chrome

RUN sudo apt-get update && sudo apt-get install -y \
    ca-certificates \
    fonts-cantarell \
    fonts-droid \
    fonts-liberation \
    fonts-roboto \
    gconf-service \
    hicolor-icon-theme \
    libappindicator1 \
    libasound2 \
    libcanberra-gtk-module \
    libcurl3 \
    libexif-dev \
    libfontconfig1 \
    libfreetype6 \
    libgconf-2-4 \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    libnspr4 \
    libnss3 \
    libpango1.0-0 \
    libv4l-0 \
    libxss1 \
    libxtst6 \
    lsb-base \
    strace \
    wget \
    xdg-utils \
    --no-install-recommends

RUN curl --silent --show-error --location --fail --retry 3 --output /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
      && (sudo dpkg -i /tmp/google-chrome-stable_current_amd64.deb || sudo apt-get -fy install)  \
      && rm -rf /tmp/google-chrome-stable_current_amd64.deb \
      && sudo sed -i 's|HERE/chrome"|HERE/chrome" --disable-setuid-sandbox --no-sandbox|g' \
           "/opt/google/chrome/google-chrome" \
      && google-chrome --version

RUN export CHROMEDRIVER_RELEASE=$(curl --location --fail --retry 3 http://chromedriver.storage.googleapis.com/LATEST_RELEASE) \
      && curl --silent --show-error --location --fail --retry 3 --output /tmp/chromedriver_linux64.zip "http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_RELEASE/chromedriver_linux64.zip" \
      && cd /tmp \
      && unzip chromedriver_linux64.zip \
      && rm -rf chromedriver_linux64.zip \
      && sudo mv chromedriver /usr/local/bin/chromedriver \
      && sudo chmod +x /usr/local/bin/chromedriver \
      && chromedriver --version

# start xvfb automatically to avoid needing to express in circle.yml
ENV DISPLAY :99
RUN printf '#!/bin/sh\nXvfb :99 -screen 0 1280x1024x24 &\nexec "$@"\n' > /tmp/entrypoint \
	&& chmod +x /tmp/entrypoint \
        && sudo mv /tmp/entrypoint /docker-entrypoint.sh

# ensure that the build agent doesn't override the entrypoint
LABEL com.circleci.preserve-entrypoint=true

ENV HOME "/home/circleci"

# install NVM
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.5/install.sh | bash
ENV NVM_DIR "$HOME/.nvm"
ENV NODE_VERSION 6.11.1

# Install a version of node & latest npm
RUN source ~/.bashrc && \
    . ~/.nvm/nvm.sh && \
    cd ~ && \
    nvm install $NODE_VERSION && \
    npm install -g npm@latest

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/bin/sh"]

# Install Google Chrome
#RUN apt-get update && apt-get install -y gconf-service libasound2 libatk1.0-0 libcups2 libgconf-2-4 libgtk-3-0 libnspr4 libx11-xcb1 libxcomposite1 fonts-liberation libappindicator1 libnss3 xdg-utils
#RUN wget https://raw.githubusercontent.com/webnicer/chrome-downloads/master/x64.deb/google-chrome-stable_61.0.3163.100-1_amd64.deb
#RUN dpkg -i ./google-chrome*.deb
#RUN apt-get install -f
#RUN rm google-chrome*.deb



CMD bash
