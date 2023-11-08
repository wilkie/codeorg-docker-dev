# Ubuntu 20.04
FROM ubuntu:focal

ARG USERNAME=cdodev

ARG MYSQL_VERSION=5.7.41

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles

# Additional required packages
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
    autoconf gcc g++ bison build-essential libssl-dev libyaml-dev libreadline-dev \
    zlib1g-dev libncurses-dev libffi-dev git chromium-browser parallel

# Set the non-root user for the container and switch
ARG UID
ARG GID
RUN apt-get -y install sudo
RUN groupadd -g ${GID} ${USERNAME} \
    && useradd -r -u ${UID} -g ${USERNAME} --shell /bin/bash --create-home ${USERNAME} \
    && echo "${USERNAME} ALL=NOPASSWD: ALL" >> /etc/sudoers \
    && chown -R ${USERNAME} /usr/local
USER ${USERNAME}

# Install ImageMagick
RUN sudo -E apt-get -y install --no-install-recommends libmagickwand-dev imagemagick

# MySQL Dependencies
RUN sudo -E apt-get -y install --no-install-recommends cmake wget libaio-dev

# Needed dependencies in order to VNC into the container
#RUN sudo -E apt-get -y install xvfb x11vnc firefox

# Build and Install MySQL Native Client
RUN cd /home/${USERNAME} \
    && wget https://downloads.mysql.com/archives/get/p/23/file/mysql-${MYSQL_VERSION}.tar.gz \
    && tar xvf mysql-${MYSQL_VERSION}.tar.gz

RUN cd /home/${USERNAME}/mysql-${MYSQL_VERSION} \
    && mkdir bld \
    && cd bld \
    && cmake -DDOWNLOAD_BOOST=1 -DWITH_BOOST=boost -DBUILD_CONFIG=mysql_release -DCMAKE_INSTALL_PREFIX=/usr .. \
    && make \
    && sudo make install

# Install rbenv
RUN sudo -E apt-get -y install rbenv \
    && sudo mkdir -p "/opt/plugins" \
    && mkdir -p /home/${USERNAME}/.rbenv/plugins \
    && sudo chown -R ${USERNAME} /opt/plugins \
    && git clone https://github.com/rbenv/ruby-build.git /opt/plugins/ruby-build \
    && ln -s /opt/plugins/ruby-build /home/${USERNAME}/.rbenv/plugins/ruby-build

# Install Ruby. Also replace the system ruby (required for RubyMine debugging).
ARG RUBY_VERSION=3.0.5
RUN rbenv install ${RUBY_VERSION} \
    && echo -n '\n# rbenv init\neval "$(rbenv init -)"\n' >> ~/.bashrc \
    && rbenv global ${RUBY_VERSION} \
    && sudo rm /usr/bin/ruby \
    && sudo ln -s /home/${USERNAME}/.rbenv/versions/${RUBY_VERSION}/bin/ruby /usr/bin/ruby

# Install nvm
ARG NODE_VERSION=18.16.0
ARG NVM_VERSION=0.39.3
ARG NVM_DIR=/home/${USERNAME}/.nvm
RUN cd /home/${USERNAME} && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

# Install Yarn
ARG YARN_VERSION=1.22.19
RUN . $NVM_DIR/nvm.sh \
    && npm i -g yarn@${YARN_VERSION} \
    && sudo mkdir -p /opt/base-nvm \
    && sudo chown -R ${USERNAME} /opt/base-nvm \
    && cp -r ${NVM_DIR}/* /opt/base-nvm/. \
    && rm -f /opt/base-nvm/README.md \
    && sudo chown -R ${USERNAME} /opt/base-nvm

# Install AWSCLI
RUN cd /home/${USERNAME} \
    && if [ $(uname -m) = "aarch64" ]; then curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"; else curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; fi \
    && unzip awscliv2.zip \
    && ./aws/install

# Add AWS_PROFILE env var
ENV AWS_PROFILE=cdo

# Add Ruby binaries to path
RUN echo -n "\n# Add Ruby binaries on path\nexport PATH=\$PATH:/home/${USERNAME}/.rbenv/versions/${RUBY_VERSION}/bin\n" >> ~/.bashrc

# Install node-pre-gyp (required for Web packaging)
RUN sudo -E apt install -y node-pre-gyp

# Install debugging tools
RUN sudo -E apt-get -y install gdb rsync lsof

# Install rbspy
RUN cd /home/${USERNAME} \
    && if [ $(uname -m) = "aarch64" ]; then curl -L "https://github.com/rbspy/rbspy/releases/download/v0.12.1/rbspy-aarch64-musl.tar.gz" -o "rbspy.tar.gz"; else curl -L "https://github.com/rbspy/rbspy/releases/download/v0.12.1/rbspy-x86_64-musl.tar.gz" -o "rbspy.tar.gz"; fi \
    && tar -xvf ./rbspy.tar.gz \
    && chmod +x ./rbspy*musl \
    && sudo cp ./rbspy*musl /usr/local/bin

RUN sudo apt-get -y install --no-install-recommends \
    python2

# Make temporary directory and do a bundle install
ARG BUNDLER_VERSION=2.3.22
RUN sudo mkdir -p /app/src
COPY src/Gemfile /app/src/.
COPY src/Gemfile.lock /app/src/.
COPY src/.ruby-version /app/src/.
RUN sudo chown -R ${USERNAME} /app
RUN cd /app/src \
    && eval "$(rbenv init -)" \
    && gem install bundler -v ${BUNDLER_VERSION} \
    && RAILS_ENV=development bundle config set --local without staging production test levelbuilder \
    && RAILS_ENV=development bundle install \
    && sudo cp -r /home/${USERNAME}/.rbenv /opt/base-rbenv \
    && sudo chown -R ${USERNAME} /opt/base-rbenv
