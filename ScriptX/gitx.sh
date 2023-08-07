#!/bin/sh

gitx() {
    git "$@"
}

#Git branch
gitx.br() {
    # if no arguments, print all branches
    if [ $# -eq 0 ]; then
        git branch
    # if provide -g, use grep to filter the branches
    elif [ "$1" = "-g" ]; then
        git branch | grep "$2"
    # else run git branch
    else
        git branch "$@"
    fi
}

# Rename current branch
gitx.br.rename() {
    git branch -m "$1"
}

# Current branch
gitx.br.name() {
    git branch --show-current
}

# Current branch with remote
gitx.br.info() {
    curBr=$(git branch --show-current)
    git branch -vv --color=always | grep --color=never "$curBr"
}

# Reset upstream branch
gitx.br.upstream() {
    # if no arguments, print the upstream branch
    if [ $# -eq 0 ]; then
        git rev-parse --abbrev-ref --symbolic-full-name @{upstream}
    # else set the upstream branch
    else
        git branch --set-upstream-to=origin/"$1"
    fi
}

# New branch
gitx.br.new() {
    git checkout -b "$1" "$2"
}

# Git status
gitx.st() {
    git status
}

# Git commit
gitx.cm() {
    git commit -m "$1"
}

# Git add and commit all
gitx.acm() {
    git add -A
    git commit -m "$1"
}

# Git smart checkout
gitx.co() {
    # if no arguments, let user to choose a branch
    if [ $# -eq 0 ]; then
        git checkout $(git branch | fzf)
    # if provide -g, use grep to filter the branches
    elif [ "$1" = "-g" ]; then
        git checkout $(git branch | grep "$2" | fzf)
    # else checkout the branch
    else
        git checkout "$1"
    fi
}

# Short alias for all the method above
g.br() {
    gitx.br "$@"
}

g.br.rename() {
    gitx.br.rename "$@"
}

g.br.name() {
    gitx.br.name "$@"
}

g.br.info() {
    gitx.br.info "$@"
}

g.br.upstream() {
    gitx.br.upstream "$@"
}

g.br.new() {
    gitx.br.new "$@"
}

g.st() {
    gitx.st "$@"
}

g.cm() {
    gitx.cm "$@"
}

g.acm() {
    gitx.acm "$@"
}

g.co() {
    gitx.co "$@"
}

