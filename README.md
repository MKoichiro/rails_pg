# Template: Docker X Rails X PostgreSQL

## Setup Workspace
If you haven't installed "curl" or "unzip" yet, run:
```bash
sudo apt install curl unzip
```

Then download a Makefile to your workspace:
```bash
cd path/to/your/working/directory/
```
```bash
curl -O https://raw.githubusercontent.com/MKoichiro/rails_pg/main/Makefile
```

Next, execute the following command to set up the current directory as the Docker Compose context:
```bash
make dc_context
```

## To establish a test Rails API project
0. You can check the available `make` commands by running:
```bash
make help
```

1. Create a `.env` file:
```bash
make env
```
This will execute `./create_env.sh`. You can set up necessary environments interactively.

2. Run `rails new` in an ephemeral api container:
```bash
make new
```
This will execute `rails new . --force --skip-bundle --database=postgresql --api`.

3. Rebuild the image with the updated Gemfile:
```bash
make build
```
This will execute `docker compose build`.

4. Edit `database.yml` to configure PostgreSQL:
```bash
make database.yml
```
This will insert `host`, `username` and `password`  into `default` section of database.yml.

5. Create an empty database:
```bash
make db
```
This will execute `rails db:create` in an ephemeral api container.

<details>
  <summary>
    You can skip final step and develop your own application code.
  </summary>

  6. Create a User model and controller, and set up routing:
  ```bash
  make test_project
  ```
  This will generate a User model and controller, and set up the necessary routes.

  Finally, run `make up`(or `docker compose up` for instead) to start the services. Then, access http://localhost:3000/api/v1/users in your browser to see the users JSON response.
</details>


## Other Features

### Setup docker aliases
Run following at root directory:
```bash
. ./docker_aliases.sh
```
or
```bash
source ./docker_aliases.sh
```
Refer to `docker_aliases.sh` to check default aliases and if necessary, customize them as you like.
Note that this change is limited to the current shell session.
If you want to make it permanent, you will need to add the equivalent to `~/.bash_aliases`.

### 
