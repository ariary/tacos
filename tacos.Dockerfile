# syntax=docker/dockerfile:1
FROM golang:1.17-alpine

RUN apk update && apk add socat tmux openssl python3
RUN apk add --update bash && rm -rf /var/cache/apk/*

ENV TERM=xterm-256color
RUN mkdir /tacos
WORKDIR /tacos

COPY ./cmd /tacos/cmd
COPY ./pkg /tacos/pkg
COPY go.mod /tacos/

COPY light-pty4all ./light-pty4all

RUN go mod tidy
RUN go mod download

#CGO_ENABLED=0 for cross-compiling as binary will be used outside of the container
RUN CGO_ENABLED=0 go build ./cmd/tacos  
RUN mv tacos ./light-pty4all/

RUN addgroup --system nonroot
RUN adduser --system nonroot --ingroup nonroot --shell /bin/bash
RUN chown nonroot:nonroot /tacos/light-pty4all
USER nonroot:nonroot


WORKDIR /tacos/light-pty4all
COPY ./entrypoint.sh /tacos/light-pty4all/
ENTRYPOINT ["./entrypoint.sh"]