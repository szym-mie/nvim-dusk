FROM alpine:latest@sha256:a8560b36e8b8210634f77d9f7f9efd7ffa463e380b75e2e74aff4511df3ef88c

RUN apk add --no-cache neovim

RUN adduser -D dev
USER dev
WORKDIR /home/dev

CMD [ "nvim" ]
