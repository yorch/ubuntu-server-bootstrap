ARG BASE_IMAGE=ubuntu:22.04

FROM $BASE_IMAGE

# Avoids 'Configuring tzdata’ interactive prompt
# https://techoverflow.net/2019/05/18/how-to-fix-configuring-tzdata-interactive-input-when-building-docker-images/
ENV DEBIAN_FRONTEND=noninteractive

ENV SCRIPT_FILE=bootstrap.sh

WORKDIR /opt

ADD ${SCRIPT_FILE} ${SCRIPT_FILE}

RUN cat /etc/lsb-release

RUN bash ${SCRIPT_FILE} && \
    rm -f ${SCRIPT_FILE} && \
    rm -rf /apt/cache /var/lib/apt/lists/*

ENTRYPOINT [ "zsh" ]
