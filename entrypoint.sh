#!/bin/bash

echo "Database $POSTGRES_DATABASE does not exist. Creating..."
mix do ecto.create, ecto.migrate
mix run priv/repo/seeds.exs
echo "Database $POSTGRES_DATABASE created."

exec "$@"
