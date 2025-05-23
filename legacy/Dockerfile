FROM alpine:latest

RUN apk add --no-cache bash

COPY . /kit

RUN ln -s /kit/cli /bin/kit

WORKDIR /app

CMD ["kit", "--help"]