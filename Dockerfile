FROM golang:1.7.1-alpine

RUN apk add --update git curl bash openssh hub

RUN git config --global github.user glidebot && git config --global user.email "glidebot@bzzt.net" && git config --global user.name "Glidebot"

RUN curl https://glide.sh/get | sh

COPY glidebot.sh /

CMD "/glidebot.sh"
