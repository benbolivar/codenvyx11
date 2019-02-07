FROM openjdk:8u181-jre-slim-stretch

EXPOSE 8080 8000 5900

ENV TERM xterm
ENV DISP_SIZE 1600x900x16
ENV DEBIAN_FRONTEND=noninteractive
ENV SWT_GTK3=0
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils locales tzdata && \
    \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="en_US.UTF-8"'>/etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8 && \
    echo "Asia/Manila" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    \
    apt-get install -y --no-install-recommends dialog sudo procps wget unzip mc curl gnupg2 vim supervisor x11vnc xvfb subversion net-tools \
    fluxbox xterm xfonts-terminus dbus-x11 python-numpy \
    libjavascriptcoregtk-3.0-0 libwebkitgtk-3.0-0 libgck-1-0 libgcr-base-3-1 libsoup-gnome2.4-1 libzeitgeist-2.0-0 && \
    \
    echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    useradd -u 1000 -G users,sudo -d /home/user --shell /bin/bash -m user && \
    echo "secret\nsecret" | passwd user

#    apt-get install -y --no-install-recommends dialog sudo procps wget unzip mc curl gnupg2 vim supervisor x11vnc xvfb subversion net-tools \
#    libjavascriptcoregtk-3.0-0 libwebkitgtk-3.0-0 libgck-1-0 libgcr-base-3-1 libsoup-gnome2.4-1 libzeitgeist-2.0-0 && \
#USER user

#RUN sudo apt-get -qqy install supervisor x11vnc xvfb subversion net-tools fluxbox xterm xfonts-terminus

#USER root

#RUN apt-get install -y libjavascriptcoregtk-3.0-0 libwebkitgtk-3.0-0 libgck-1-0 libgcr-base-3-1 libsoup-gnome2.4-1 libzeitgeist-2.0-0 \
#    dbus-x11 python-numpy
    
USER user

# download and install noVNC, Firefox, Eclipse CDT, configure Blackbox
RUN sudo mkdir -p /opt/noVNC/utils/websockify && \
    wget -qO- "http://github.com/kanaka/noVNC/tarball/master" | sudo tar -zx --strip-components=1 -C /opt/noVNC && \
    wget -qO- "https://github.com/kanaka/websockify/tarball/master" | sudo tar -zx --strip-components=1 -C /opt/noVNC/utils/websockify && \
    sudo wget -O FirefoxSetup.tar.bz2 "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US" && \
    sudo tar xjf FirefoxSetup.tar.bz2 -C /opt/
    
ADD index.html  /opt/noVNC/
ADD supervisord.conf /opt/

RUN sudo mkdir -p /home/user/KeepAlive
ADD keepalive.html /home/user/KeepAlive

EXPOSE 6080 32745
ENV DISPLAY :20.0

ENV MAVEN_VERSION=3.3.9 \
    TOMCAT_HOME=/home/user/tomcat8

ENV M2_HOME=/home/user/apache-maven-$MAVEN_VERSION

ENV PATH=$M2_HOME/bin:/opt/firefox/firefox:$PATH

#RUN sudo apt-get -qqy install openjdk-8-jre
RUN mkdir /home/user/cbuild /home/user/tomcat8 /home/user/apache-maven-$MAVEN_VERSION && \
    sudo wget -qO- "http://apache.ip-connect.vn.ua/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz" | tar -zx --strip-components=1 -C /home/user/apache-maven-$MAVEN_VERSION/ && \
    sudo wget -qO- "http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.24/bin/apache-tomcat-8.0.24.tar.gz" | sudo tar -zx --strip-components=1 -C /home/user/tomcat8 && \
    sudo rm -rf /home/user/tomcat8/webapps/*


# Add run commands in /home/user/.bashrc
#RUN echo "export JAVA_HOME=/opt/jdk$JAVA_VERSION_PREFIX\n\
#export PATH=$JAVA_HOME/bin:$M2_HOME/bin:$PATH\n\
RUN echo "\n\
export M2_HOME=/home/user/apache-maven-$MAVEN_VERSION\n\
export TOMCAT_HOME=/home/user/tomcat8\n\
export PATH=$M2_HOME/bin:$PATH\n\
if [ ! -f /projects/KeepAlive/keepalive.html ]\nthen\nsleep 5\ncp -rf /home/user/KeepAlive /projects\nfi\n\
sudo date >> /home/user/date.log" | sudo tee -a /home/user/.bashrc

RUN sudo mkdir -p /etc/pki/tls/certs && \
    sudo openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/pki/tls/certs/novnc.pem -out /etc/pki/tls/certs/novnc.pem -days 3650 \
         -subj "/C=PH/ST=Cebu/L=Cebu/O=NA/OU=NA/CN=codenvy.io" && \
    sudo chmod 444 /etc/pki/tls/certs/novnc.pem
#Then later update /opt/supervisord.conf last line to read -> command=/opt/noVNC/utils/launch.sh --cert /etc/pki/tls/certs/novnc.pem --ssl-only

# Thanks to zmart/eclipse-cdt for ideas on unattended CDT install
USER root
ENV USER_NAME=user
ENV HOME=/home/${USER_NAME}

RUN apt-get update && apt-get install -y libxext-dev libxrender-dev libxtst-dev \
    libcanberra-gtk-module g++ build-essential gdb cmake && \
    apt-get -y autoremove
#RUN apt-get update && apt-get install -y software-properties-common libxext-dev libxrender-dev libxtst-dev libgtk2.0-0 \
#    libcanberra-gtk-module g++ libboost-all-dev build-essential gdb cmake && \

ARG ECLIPSE_MIRROR=http://ftp.fau.de/eclipse/technology/epp/downloads/release/photon/R
ARG ECLIPSE_TAR=eclipse-cpp-photon-R-linux-gtk-x86_64.tar.gz

RUN wget ${ECLIPSE_MIRROR}/${ECLIPSE_TAR} -O /tmp/eclipse.tar.gz -q && tar -xf /tmp/eclipse.tar.gz -C /opt && rm /tmp/eclipse.tar.gz && \
    sudo sed "s/@user.home/\/projects/g" -i /opt/eclipse/eclipse.ini

ADD --chown=user:user menu /home/user/.menu
ADD --chown=user:user init /home/user/.init

USER user

WORKDIR /projects

ENV ECLIPSE_WORKSPACE=/projects/eclipse-workspace
ENV ECLIPSE_DOT=/projects/.eclipse
ENV DELAY=50

CMD /usr/bin/supervisord -c /opt/supervisord.conf & sleep 365d
