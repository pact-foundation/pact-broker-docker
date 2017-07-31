## Publishing to Docker Hub

Docker hub will build an image every time a tag with pattern /^[0-9.\-]+/ (eg. 2.3.0-1) is pushed.

To release a new image with a tag:

    script/release.sh
