Template: Docker X Rails X PostgreSQL

If you have'nt installed "curl" or "unzip" yet.
```bash
sudo apt install curl unzip
```

Then download a Makefile to workspace.
```bash
cd <workspace>
curl -O https://raw.githubusercontent.com/MKoichiro/rails_pg/main/Makefile
```

And execute the following to setup current directory as docker compose context
```bash
make docker_context
```