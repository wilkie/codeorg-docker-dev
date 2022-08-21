FROM ubuntu:bionic

# Additional required packages
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm5 libgdbm-dev git chromium-browser parallel

# Set the non-root user for the container and switch
RUN apt-get -y install sudo
RUN groupadd -g 999 cdodev \
    && useradd -r -u 999 -g cdodev --shell /bin/bash --create-home cdodev \
    && echo 'cdodev ALL=NOPASSWD: ALL' >> /etc/sudoers \
    && chown -R cdodev /usr/local
USER cdodev

# Install rbenv
RUN sudo apt-get -y install rbenv \
    && mkdir -p "$(rbenv root)"/plugins \
    && git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build

# Install Ruby 2.6.6 and Bundler 1.17.3
RUN rbenv install 2.6.6 \
    && echo -n '\n# rbenv init\neval "$(rbenv init -)"\n' >> ~/.bashrc

# Install Node 14.17.1
RUN sudo apt-get -y install nodejs npm \
    && npm install -g n \
    && n 14.17.1

# Install Yarn 1.22.5
RUN npm i -g yarn@1.22.5

# # Install ImageMagick
RUN sudo apt-get -y install libmagickwand-dev imagemagick

# # Install MySQL Native Client
RUN sudo apt-get -y install libsqlite3-dev libmysqlclient-dev mysql-client-core-5.7

# Install AWSCLI
RUN cd /home/cdodev \
    && if [ $(uname -m) = "aarch64" ]; then curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"; else curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; fi \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install

# Add AWS_PROFILE env var to bashrc
RUN echo -n '\n# AWS Profile\nexport AWS_PROFILE=cdo\n' >> ~/.bashrc

# Add CHROME_BIN env var to bashrc
RUN echo -n '\n# Chromium Binary\nexport CHROME_BIN=/usr/bin/chromium-browser\n' >> ~/.bashrc

# Make temporary directory and do a bundle install
RUN sudo mkdir -p /app/src
COPY src/Gemfile /app/src/.
COPY src/Gemfile.lock /app/src/.
COPY src/.ruby-version /app/src/.
RUN cd /app/src \
    && eval "$(rbenv init -)" \
    && gem install bundler -v 1.17.3 \
    && bundle install

# Install node-pre-gyp (required for Web packaging)
RUN sudo apt install -y node-pre-gyp
