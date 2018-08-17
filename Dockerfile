FROM codenvy/selenium

USER user

RUN cd /home/user && \
    sudo apt-get -y install vim

RUN echo "[begin] (Blackbox) \n [exec] (Terminal)     {urxvt -fn "xft:Terminus:size=14"} \n \
    [exec] (Browser)     {midori} \n \
    [end]" | sudo tee /etc/X11/blackbox/blackbox-menu
    
CMD /usr/bin/supervisord -c /opt/supervisord.conf & \
    cd /home/user & sleep 365d
