FROM elixir:1.14.3

RUN mkdir /app
WORKDIR /app

COPY . .

RUN mix local.hex --force
RUN mix deps.get

EXPOSE 4000

CMD ["mix", "run", "--no-halt"]