FROM bitwalker/alpine-elixir:1.10.2

RUN mkdir /app
COPY . /app
WORKDIR /app

RUN apk update && \
apk add -u musl musl-dev musl-utils nodejs-npm build-base
RUN mix deps.get
RUN mix compile
RUN cd assets && \
    npm install && \
    cd .. && \
    mix phx.digest

# Install hex package manager
# By using --force, we don’t need to type “Y” to confirm the installation
RUN mix local.hex --force

# Compile the project
RUN mix compile

CMD ["/app/entrypoint.sh"]
