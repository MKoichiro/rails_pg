#!/usr/bin/env sh

alias dcom='docker compose'
alias dcom-b='docker compose build'
alias dcom-d='docker compose down'
alias dcom-d-rmi='docker compose down --rmi all'
alias dcom-d-v='docker compose down --volumes'
alias dcom-e='docker compose exec'
alias dcom-ls='docker compose ls'
alias dcom-ps='docker compose ps'
alias dcom-u='docker compose up'
alias dcom-i='docker compose images'

alias d='docker'
alias di-l='docker image ls'
alias dcon-l='docker container ls'
alias dcon-la='docker container ls -a'
alias dcon-rm='docker container rm'
alias dcon-rma='docker container rm -f $(docker container ls -a -q)'
