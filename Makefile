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

COMPOSE_FILE_FLAG = -f $(COMPOSE_FILE)
COMPOSE_CMD = docker compose
API_CONTAINER = api
DB_CONTAINER = db
DB_USER = $(POSTGRES_USER)
DB_NAME = api_$(ENVIRONMENT)

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
	@curl 

# Create .env file
.env: ./create_env.sh
	./create_env.sh

# Run rails new command
new:
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) run --rm --no-deps $(API_CONTAINER) rails new . --force --skip-bundle --database=$(DBMS) --api

# Build the containers
build:
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) build

# Open a bash session in the api container
bash:
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) run --rm $(API_CONTAINER) bash

# Access the PostgreSQL shell in the db container
db_shell:
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) run --rm $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME)

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
	@grep -hE '^- [a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "%-10s %s\n", $$1, $$2}' | \
	sort

developing:
	@find ./api/ -type f ! \( $(foreach names, $(EXCLUDE_PATTERNS), -name $(names) -o) -false \) -print


# Mark the targets with comments for help display
- docker_context: ## : Set the Docker compose context to the current directory. Curl from git repository.
- .env:       		## : Create .env file
- new:        		## : Run rails new command
- build:      		## : Build the images
- bash:       		## : Open a bash session in the api container
- db_shell:   		## : Access the PostgreSQL shell in the db container
- up:         		## : Start up the services
- down:       		## : Shut down and remove images
- clean:      		## : Delete all files except those related to Docker
