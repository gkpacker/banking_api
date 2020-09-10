FROM bitwalker/alpine-elixir-phoenix:1.10.2

ARG SECRET_KEY_BASE

# Set exposed ports
EXPOSE 4000
ENV SECRET_KEY_BASE=${SECRET_KEY_BASE}

COPY . .

# Update and install packages
RUN apk update && \
apk add -u musl musl-dev musl-utils nodejs-npm build-base erlang

# Add local node module binaries to PATH
ENV PATH=./assets/node_modules/.bin:$PATH

# Cache elixir deps
ADD mix.exs mix.lock ./
RUN mix do deps.get, deps.compile

# Same with npm deps
ADD assets/package.json assets/
RUN cd assets && \
    npm install && \
    cd .. && \
    mix phx.digest

# Install hex package manager
# By using --force, we don’t need to type “Y” to confirm the installation
RUN mix local.hex --force

ENTRYPOINT [ "./entrypoint.sh" ]
CMD [ "foreground" ]
