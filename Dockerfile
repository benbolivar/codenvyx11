FROM openjdk:8u181-jre-slim-stretch

EXPOSE 8080 8000 5900 6080 32745

ENV TERM xterm
ENV DISP_SIZE 1600x900x16
ENV DEBIAN_FRONTEND=noninteractive
ENV SWT_GTK3=0
ENV LANG en_US.UTF-8
ENV DISPLAY :20.0
ENV MAVEN_VERSION=3.3.9 \
    TOMCAT_HOME=/home/user/tomcat8
ENV M2_HOME=/home/user/apache-maven-$MAVEN_VERSION
ENV PATH=$M2_HOME/bin:/opt/firefox/firefox:$PATH

USER root
ENV USER_NAME=user
ENV HOME=/home/${USER_NAME}

ARG ECLIPSE_MIRROR=http://ftp.fau.de/eclipse/technology/epp/downloads/release/photon/R
ARG ECLIPSE_TAR=eclipse-cpp-photon-R-linux-gtk-x86_64.tar.gz

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils locales tzdata gnupg2 sudo && \
    \
    echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    useradd -u 1000 -G users,sudo -d /home/user --shell /bin/bash -m user && \
    echo "secret\nsecret" | passwd user && \
    \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="en_US.UTF-8"' > /etc/default/locale && \
    echo "Asia/Manila" > /etc/timezone && \
    locale-gen && \
    \
    apt-get install -y --no-install-recommends dialog procps wget unzip mc curl vim supervisor x11vnc xvfb \
    subversion net-tools fluxbox xterm xfonts-terminus dbus-x11 python-numpy \
    libjavascriptcoregtk-3.0-0 libwebkitgtk-3.0-0 libgck-1-0 libgcr-base-3-1 libsoup-gnome2.4-1 libzeitgeist-2.0-0 \
    software-properties-common libxext-dev libxrender-dev libxtst-dev \
    libcanberra-gtk-module g++ gdb cmake && \
    apt-get -y autoremove && \
    \
    mkdir -p /opt/noVNC/utils/websockify && \
    wget -qO- "http://github.com/kanaka/noVNC/tarball/master" | tar -zx --strip-components=1 -C /opt/noVNC && \
    wget -qO- "https://github.com/kanaka/websockify/tarball/master" | tar -zx --strip-components=1 -C /opt/noVNC/utils/websockify && \
    wget -O FirefoxSetup.tar.bz2 "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US" && \
    tar xjf FirefoxSetup.tar.bz2 -C /opt/ && \
    \
    mkdir -p /home/user/KeepAlive && \
    \
    mkdir /home/user/cbuild /home/user/tomcat8 /home/user/apache-maven-$MAVEN_VERSION && \
    wget -qO- "http://apache.ip-connect.vn.ua/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz" | tar -zx --strip-components=1 -C /home/user/apache-maven-$MAVEN_VERSION/ && \
    wget -qO- "http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.24/bin/apache-tomcat-8.0.24.tar.gz" | tar -zx --strip-components=1 -C /home/user/tomcat8 && \
    rm -rf /home/user/tomcat8/webapps/* && \
    \
    mkdir -p /etc/pki/tls/certs && \
    openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/pki/tls/certs/novnc.pem -out /etc/pki/tls/certs/novnc.pem -days 3650 \
         -subj "/C=PH/ST=Cebu/L=Cebu/O=NA/OU=NA/CN=codenvy.io" && \
    chmod 444 /etc/pki/tls/certs/novnc.pem && \
    \
    wget ${ECLIPSE_MIRROR}/${ECLIPSE_TAR} -O /tmp/eclipse.tar.gz -q && tar -xf /tmp/eclipse.tar.gz -C /opt && rm /tmp/eclipse.tar.gz && \
    sed "s/@user.home\/eclipse-workspace/\/projects/g" -i /opt/eclipse/eclipse.ini && \
    \
    printf "\nexport M2_HOME=/home/user/apache-maven-$MAVEN_VERSION\
        \nexport TOMCAT_HOME=/home/user/tomcat8\
        \nexport PATH=$M2_HOME/bin:$PATH\
        \nif [ ! -f /projects/KeepAlive/keepalive.html ]\nthen\
        \nsleep 5\ncp -rf /home/user/KeepAlive /projects\
        \nfi" | sudo tee -a /home/user/.bashrc

#    apt-get install -y software-properties-common libxext-dev libxrender-dev libxtst-dev \
#    libcanberra-gtk-module g++ gdb cmake && \
#    apt-get -y autoremove && \

ADD index.html  /opt/noVNC/
ADD supervisord.conf /opt/
ADD keepalive.html /home/user/KeepAlive
ADD --chown=user:user menu /home/user/.menu
ADD --chown=user:user init /home/user/.init

USER user

WORKDIR /projects

ENV ECLIPSE_WORKSPACE=/projects
ENV ECLIPSE_DOT=/projects/.eclipse
ENV DELAY=50

CMD /usr/bin/supervisord -c /opt/supervisord.conf & sleep 365d
