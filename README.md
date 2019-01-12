Usage:

1.) docker run --rm --detach --env DISP_SIZE=1600x900x16 --env DELAY=5 --name eclipse --privileged -v ~/mylocalfolder:/projects -p 6080:6080 benbolivar/codenvyx11

2.) Then using a browser, go to https://localhost:6080/vnc.html or on Windows https://192.168.99.100:6080/vnc.html (get IP using docker-machine ip command)
