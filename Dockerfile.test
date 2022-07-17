ARG BASE_IMAGE=ubuntu:20.04

FROM $BASE_IMAGE

# Avoids 'Configuring tzdata’ interactive prompt
# https://techoverflow.net/2019/05/18/how-to-fix-configuring-tzdata-interactive-input-when-building-docker-images/
ENV DEBIAN_FRONTEND=noninteractive

ADD ../server-setup.sh /server-setup.sh

RUN cat /etc/lsb-release

RUN bash server-setup.sh

ENTRYPOINT [ "zsh" ]
