FROM hexpm/elixir:1.14.3-erlang-25.2.1-alpine-3.17.0

WORKDIR /code

RUN mix local.hex --force && \
    mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get

COPY ./ ./

RUN mix do compile

CMD [ "mix", "test" ]
