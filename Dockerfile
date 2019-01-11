FROM ubuntu

EXPOSE 8080 8000

ENV TERM xterm
ENV DISP_SIZE 1600x900x16

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils dialog
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata locales && \
    cp /usr/share/zoneinfo/Asia/Manila /etc/localtime

RUN apt-get update && \
    apt-get -y install sudo procps wget unzip mc curl gnupg2 vim && \
    echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    useradd -u 1000 -G users,sudo -d /home/user --shell /bin/bash -m user && \
    echo "secret\nsecret" | passwd user

# install midori (browser), xserver, blackbox

USER user

RUN sudo apt-get update -qqy && \
  sudo apt-get -qqy install \
  supervisor \
  x11vnc \
  xvfb \
  subversion \
  net-tools \
  blackbox \
  rxvt-unicode \
  xfonts-terminus

USER root

RUN apt-get install -y libjavascriptcoregtk-1.0-0 libwebkitgtk-1.0-0 libgck-1-0 libgcr-base-3-1 libsoup-gnome2.4-1 libzeitgeist-2.0-0 dbus-x11  && \
    wget http://archive.ubuntu.com/ubuntu/pool/universe/m/midori/midori_0.5.11-ds1-2_amd64.deb && \
    dpkg -i midori_0.5.11-ds1-2_amd64.deb

USER user

# download and install noVNC, Firefox, Eclipse CDT, configure Blackbox
RUN sudo mkdir -p /opt/noVNC/utils/websockify && \
    wget -qO- "http://github.com/kanaka/noVNC/tarball/master" | sudo tar -zx --strip-components=1 -C /opt/noVNC && \
    wget -qO- "https://github.com/kanaka/websockify/tarball/master" | sudo tar -zx --strip-components=1 -C /opt/noVNC/utils/websockify && \
    sudo apt-get install -y firefox && \
    sudo mkdir -p /etc/X11/blackbox && \
    echo "[begin] (Blackbox) \n \
    [exec] (Terminal)    {urxvt -fn "xft:Terminus:size=14"} \n \
    [exec] (Browser)     {midori} \n \
    [exec] (Firefox)     {firefox} \n \
    [exec] (Eclipse CDT) {/opt/eclipse/eclipse} \n \
    [end]" | sudo tee -a /etc/X11/blackbox/blackbox-menu

ADD index.html  /opt/noVNC/
ADD supervisord.conf /opt/

RUN sudo mkdir -p /home/user/KeepAlive
ADD keepalive.html /home/user/KeepAlive

EXPOSE 6080 32745
ENV DISPLAY :20.0

ENV MAVEN_VERSION=3.3.9 \
    TOMCAT_HOME=/home/user/tomcat8

ENV M2_HOME=/home/user/apache-maven-$MAVEN_VERSION

ENV PATH=$M2_HOME/bin:$PATH

RUN sudo apt-get -qqy install openjdk-8-jre
RUN mkdir /home/user/cbuild /home/user/tomcat8 /home/user/apache-maven-$MAVEN_VERSION && \
  sudo wget -qO- "http://apache.ip-connect.vn.ua/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz" | tar -zx --strip-components=1 -C /home/user/apache-maven-$MAVEN_VERSION/
RUN sudo wget -qO- "http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.24/bin/apache-tomcat-8.0.24.tar.gz" | sudo tar -zx --strip-components=1 -C /home/user/tomcat8 && \
    sudo rm -rf /home/user/tomcat8/webapps/*

ENV LANG en_GB.UTF-8
ENV LANG en_US.UTF-8

# Add run commands in /home/user/.bashrc
RUN echo "export JAVA_HOME=/opt/jdk$JAVA_VERSION_PREFIX\n\
export M2_HOME=/home/user/apache-maven-$MAVEN_VERSION\n\
export TOMCAT_HOME=/home/user/tomcat8\n\
export PATH=$JAVA_HOME/bin:$M2_HOME/bin:$PATH\n\
if [ ! -f /projects/KeepAlive/keepalive.html ]\nthen\nsleep 5\ncp -rf /home/user/KeepAlive /projects\nfi" | sudo tee -a /home/user/.bashrc
#if [ ! -f /projects/KeepAlive/keepalive.html ]\nthen\nsleep 5\ncp -rf /home/user/KeepAlive /projects\nfi\n\
#if [ ! -f /projects/eclipse-workspace ]\nthen\nsleep 5\nmkdir -p /projects/.eclipse /projects/eclipse-workspace\n\
#sudo chown -R user:user /projects/eclipse-workspace /projects/.eclipse\nfi\n\
#sudo ln -s /projects/.eclipse /home/user/.eclipse\n\
#sudo chown -h user:user /home/user/.eclipse" | sudo tee -a /home/user/.bashrc

RUN sudo locale-gen en_US.UTF-8

RUN sudo mkdir -p /etc/pki/tls/certs && \
    sudo openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/pki/tls/certs/novnc.pem -out /etc/pki/tls/certs/novnc.pem -days 3650 \
         -subj "/C=PH/ST=Cebu/L=Cebu/O=NA/OU=NA/CN=codenvy.io" && \
    sudo chmod 444 /etc/pki/tls/certs/novnc.pem
#Then later update /opt/supervisord.conf last line to read -> command=/opt/noVNC/utils/launch.sh --cert /etc/pki/tls/certs/novnc.pem --ssl-only

# zmart/eclipse-cdt for unattended CDT install
USER root
ENV USER_NAME=user
ENV HOME=/home/${USER_NAME}

RUN apt-get update && apt-get install -y software-properties-common 
RUN apt-get update && apt-get install -y libxext-dev libxrender-dev libxtst-dev && apt-get -y autoremove
RUN apt-get install -y libgtk2.0-0 libcanberra-gtk-module
RUN apt-get install -y g++ libboost-all-dev build-essential gdb cmake

ARG ECLIPSE_MIRROR=http://ftp.fau.de/eclipse/technology/epp/downloads/release/photon/R
ARG ECLIPSE_TAR=eclipse-cpp-photon-R-linux-gtk-x86_64.tar.gz

RUN wget ${ECLIPSE_MIRROR}/${ECLIPSE_TAR} -O /tmp/eclipse.tar.gz -q && tar -xf /tmp/eclipse.tar.gz -C /opt && rm /tmp/eclipse.tar.gz
RUN chmod +x /opt/eclipse/eclipse
RUN sudo sed "s/@user.home/\/projects/g" -i /opt/eclipse/eclipse.ini
#&& useradd -ms /bin/bash ${USER_NAME}

USER user

WORKDIR /projects

ENV ECLIPSE_WORKSPACE=/projects/eclipse-workspace
ENV ECLIPSE_DOT=/projects/.eclipse

CMD /usr/bin/supervisord -c /opt/supervisord.conf & sleep 365d
