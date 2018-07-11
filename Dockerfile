FROM elixir:alpine

RUN mix local.hex --force
RUN mix local.rebar --force

RUN mkdir /app
WORKDIR /app

RUN apk update
RUN apk add git curl libcurl yaml-dev gcc musl-dev linux-headers libstdc++ bash

COPY . /app

RUN mix deps.get
RUN MIX_ENV=prod mix compile

CMD epmd -daemon && MIX_ENV=prod mix phx.server
