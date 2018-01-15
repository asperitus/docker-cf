##
FROM ubuntu:16.04

MAINTAINER Qiang Li "li.qiang@gmail.com"

##
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    build-essential \
    curl \
    git \
    openssh-client \
    sudo \
    unzip \
    wget \
    zip \
    \
    libxext-dev \
    libxrender-dev \
    libxtst-dev \
    libxslt1.1 \
    libgtk2.0-0 \
    \
    xterm

RUN ln -sf bash /bin/sh

##
ENV LOGIN=vcap
ENV HOME /home/$LOGIN

RUN echo "Add su user $LOGIN ..." \
    && useradd -m -b /home -s /bin/bash $LOGIN \
    && echo "$LOGIN ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

#### Install additional packages

#http://docs.cloudfoundry.org/cf-cli/install-go-cli.html#pkg-linux
RUN apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates

RUN wget -q -O - http://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key  | apt-key add - \
    && echo "deb http://packages.cloudfoundry.org/debian stable main" | tee /etc/apt/sources.list.d/cloudfoundry-cli.list \
    && apt-get update \
    && apt-get install cf-cli

##
RUN echo "Installing Go ..." \
    && wget "https://redirector.gvt1.com/edgedl/go/go1.9.2.linux-amd64.tar.gz" -O /tmp/go.tar.gz --no-check-certificate --quiet --show-progress=off \
    && tar -xf /tmp/go.tar.gz -C /usr/local/ \
    && rm /tmp/go.tar.gz

ENV GOROOT /usr/local/go
ENV GOPATH $HOME/go


##
RUN apt-get install -y --no-install-recommends \
    lsb-release

RUN echo "Installing Node.js ..." \
    && echo "deb http://deb.nodesource.com/node_6.x $(lsb_release -sc) main" >> /etc/apt/sources.list \
	&& apt-key adv --keyserver keyserver.ubuntu.com --recv 68576280 \
	&& apt-get update \
    && apt-get install -y --no-install-recommends \
       nodejs

##
RUN git config --system http.sslVerify "false"

##
USER $LOGIN
WORKDIR $HOME

##
RUN echo "Update rc ..." \
    && echo "export PATH=\"\$PATH:$HOME/go/bin:/usr/local/go/bin\"" >> $HOME/.bashrc \
    && echo "alias cdgh=\"cd $GOPATH/src/github.com\"" >> $HOME/.bashrc \
    && echo "alias cfin=\"cf login -a  https://api.system.aws-usw02-pr.ice.predix.io\"" >> $HOME/.bashrc \
    && echo "alias cfout=\"cf logout\"" >> $HOME/.bashrc

##
CMD ["/bin/bash"]

##