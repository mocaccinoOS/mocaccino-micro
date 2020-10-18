#!/bin/bash
rm -rfv /root/.ssh || true
ln -s $(pwd)/storage /root/.ssh
mkdir -p ~/.config/
rm -rfv /root/.config/hub || true
ln -s $(pwd)/storage/hub /root/.config/hub
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
ssh-keyscan github.com >> ~/.ssh/known_hosts
