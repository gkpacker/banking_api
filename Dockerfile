FROM bitwalker/alpine-elixir-phoenix:1.10.2

ARG SECRET_KEY_BASE
ARG HOST
ARG PORT

# Set exposed ports
EXPOSE ${PORT}
ENV MIX_ENV=prod
ENV DATABASE_URL=ecto://postgres:postgres@db/banking_api_prod
ENV SECRET_KEY_BASE=${SECRET_KEY_BASE}
ENV HOST=${HOST}
ENV PORT=${PORT}

# Cache elixir deps
ADD mix.exs mix.lock ./
RUN mix do deps.get, deps.compile

# Same with npm deps
ADD assets/package.json assets/
RUN cd assets && \
    npm install

ADD . .

RUN mix local.hex --force

# Run frontend build, compile, and digest assets
RUN cd assets/ && \
    npm run deploy && \
    cd - && \
    mix do compile, phx.digest

CMD ["./entrypoint.sh"]
