# .envファイルの環境変数を読み込む
ifneq (,$(wildcard ./.env))
	include .env
	export
endif

ENV ?= dev
ENVIRONMENT = development
ifeq ($(ENV), prod)
ENVIRONMENT = production
else ifeq ($(ENV), test)
ENVIRONMENT = $(ENV)
else ifneq ($(ENV), dev)
$(error ERROR: Unkown value for ENV: "$(ENV)". Only 'dev' or 'prod' or 'test' are allowed)
endif
COMPOSE_FILE = compose.yaml
COMPOSE_FILE_FLAG = -f $(COMPOSE_FILE)
COMPOSE_CMD = docker compose
API_CONTAINER = api
DB_CONTAINER = db
DB_HOST = $(POSTGRES_HOST)
DB_USER = $(POSTGRES_USER)
DB_NAME = api_$(ENVIRONMENT)
DB_SETTINGS = "  host: <%%= ENV['POSTGRES_HOST'] %%>\n  username: <%%= ENV['POSTGRES_USER'] %%>\n  password: <%%= ENV['POSTGRES_PASSWORD'] %%>\n"

# Gemfileの初期内容
GEMFILE_CONTENT = source \"https://rubygems.org\"\n\ngem \"rails\", \"~> 7.2.1\"\n

# cleanコマンドで削除しないファイルのリスト
EXCLUDE_PATTERNS := 'Gemfile*' 'Dockerfile*' '.dockerignore' 'entrypoint.sh'

# For debugging
print-vars:
	@echo "DBMS: $(DBMS)"
	@echo "DB_USER: $(DB_USER)"
	@echo "DB_NAME: $(DB_NAME)"
	@echo "ENV: $(ENV)"
	@echo "ENVIRONMENT: $(ENVIRONMENT)"

# Set the Docker compose context to the current directory
docker_context:
	@curl -L -o rails_pg.zip https://github.com/MKoichiro/rails_pg/archive/refs/heads/main.zip
	@unzip -o rails_pg.zip
	@rm rails_pg.zip
	@mv rails_pg-main/* .
	@rm -r rails_pg-main/ rails_pg.zip

# Create .env file
.env: ./create_env.sh
	./create_env.sh

# Run rails new command
new:
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) run --rm --no-deps $(API_CONTAINER) rails new . --force --skip-bundle --database=$(DBMS)ql --api

# database.ymlの設定を変更
database.yml:
	@printf $(DB_SETTINGS) \
	| sed -i '/^  encoding: unicode$$/r /dev/stdin' ./api/config/database.yml

# Create empty database
db:
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) run --rm $(API_CONTAINER) rails db:create

# Build the containers
build:
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) build

# Open a bash session in the api container
bash:
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) run --rm $(API_CONTAINER) bash

# Access the PostgreSQL shell in the db container
db_shell:
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) run --rm $(DB_CONTAINER) psql -h $(DB_HOST) -U $(DB_USER) -d $(DB_NAME)

# Start up the services
up:
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) up

# Shut down and remove images
down:
	$(COMPOSE_CMD) down --rmi all

# Clean up
clean: down
	@printf "[!] All files except those related to Docker will be deleted.\nAre you sure you want to continue? (y/n): "
	@read confirm; \
		if [ "$$confirm" != "y" ]; then \
		echo "Aborted."; \
		exit 0; \
	fi
	@find ./api/ -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
	@#find ./api/ -type f ! \( -name 'Gemfile*' -o -name 'Dockerfile*' -o -name '.dockerignore' -o -name 'entrypoint.sh' \) -delete
	@find ./api/ -type f ! \( $(foreach names, $(EXCLUDE_PATTERNS), -name $(names) -o) -false \) -print
	@: > ./api/Gemfile.lock
	@echo "$(GEMFILE_CONTENT)" > ./api/Gemfile
	@echo "deleted the following directories and all their subdirectories and files."
	@find ./api/ -mindepth 1 -maxdepth 1 -type d -print
	@echo -e "\ndeleted the following files."
	@find ./api/ -type f ! \( -name 'Gemfile*' -o -name 'Dockerfile*' -o -name '.dockerignore' -o -name 'entrypoint.sh' \) -print

# Show help
help:
	@echo "Available commands:"
	@grep -hE '^- [a-zA-Z_\.-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "%-20s %s\n", $$1, $$2}' | \
	sort


SEED_TEMPLATE =\
User.create(name: 'John Doe', email: 'john@example.com')\n\
User.create(name: 'Jane Smith', email: 'jane@example.com')\n

CONTROLLER_TEMPLATE =\
class Api::V1::UsersController < ApplicationController\n\
\tdef index\n\
\t\t@users = User.all\n\
\t\trender json: @users\n\
\tend\n\
\tdef show\n\
\t\t@user = User.find(params[:id])\n\
\t\trender json: @user\n\
\tend\n\
end\n

ROUTES_TEMPLATE =\
Rails.application.routes.draw do\n\
\tnamespace :api do\n\
\t\tnamespace :v1 do\n\
\t\t\tresources :users, only: [:index, :show]\n\
\t\tend\n\
\tend\n\
end\n

# Make test api project
test_project: db
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) run --rm $(API_CONTAINER) rails g model User name:string email:string
	@echo "Generate User model."
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) run --rm $(API_CONTAINER) rails db:migrate
	@echo "Migrate User model."
	@printf "$(SEED_TEMPLATE)" | sed 's/^ //g' >> ./api/db/seeds.rb
	@echo "Edit db/seeds.rb"
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) run --rm $(API_CONTAINER) rails db:seed
	@echo "Seed the database."
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) run --rm $(API_CONTAINER) rails g controller Api::V1::Users
	@echo "Generate Users controller."
	@printf "$(CONTROLLER_TEMPLATE)" | sed 's/^ //g' > ./api/app/controllers/api/v1/users_controller.rb
	@echo "edit users_controller.rb"
	@printf "$(ROUTES_TEMPLATE)" | sed 's/^ //g' > ./api/config/routes.rb
	@echo "edit routes.rb"
	@echo "...Complete."
	@echo "Please run 'make up' to start the services. Then, access 'http://localhost:3000/api/v1/users' in your browser."


# Mark the targets with comments for help display
- docker_context:	## : Set the Docker compose context to the current directory. Curl from git repository.
- .env:          	## : Create .env file
- new:           	## : Run rails new command
- database.yml:  	## : Change the database.yml settings
- db:            	## : Create empty database
- build:         	## : Build the images
- bash:          	## : Open a bash session in the api container
- db_shell:      	## : Access the PostgreSQL shell in the db container
- up:            	## : Start up the services
- down:          	## : Shut down and remove images
- clean:         	## : Delete all files except those related to Docker
- test_project:  	## : Make test api project
- help:          	## : Show help
