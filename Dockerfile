FROM codenvy/selenium

CMD /usr/bin/supervisord -c /opt/supervisord.conf & \
    cd /home/user & sleep 365d
