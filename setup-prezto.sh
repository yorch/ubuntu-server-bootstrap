#!/bin/zsh

git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"

setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done

curl -s https://gist.githubusercontent.com/yorch/e60087118c0126b2f5f8bf8a271633eb/raw/74d2593d6fd277c05f93fd62ee5a3eb3399f2139/.zpreztorc > "${ZDOTDIR:-$HOME}/.zprezto/runcoms/zpreztorc"
