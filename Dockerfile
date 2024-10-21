
FROM alpine:latest

WORKDIR /

COPY . .

RUN alias cli="/cli"

CMD ["sh", "cli", "--help"]