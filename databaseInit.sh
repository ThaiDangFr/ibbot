#!/bin/bash

rm -f db/ibbot.db
RAILS_ENV=production bundle exec rake db:create
sqlite3 db/ibbot.db -init db/schema.sql .schema
RAILS_ENV=production bundle exec rake db:migrate
