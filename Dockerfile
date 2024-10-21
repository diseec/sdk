FROM alpine:latest

RUN apk add --no-cache bash

COPY . /toolkit

WORKDIR /app

RUN alias toolkit="/toolkit/cli"

CMD ["bash", "cli", "--help"]