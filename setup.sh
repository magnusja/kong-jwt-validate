#!/bin/sh

echo "LUA_PATH=$LUA_PATH"

# Setting up the proper database
if [ -n "$DATABASE" ]; then
  echo -e '\ndatabase: "'$DATABASE'"' >> /etc/kong/kong.yml
fi