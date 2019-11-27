#!/bin/sh

cp -R /tmp/.ssh /root/.ssh
chmod 700 /root/.ssh
chmod 644 /root/.ssh/id_rsa.pub
chmod 600 /root/.ssh/id_rsa

git config --global user.email $GIT_EMAIL
git config --global user.name $GIT_NAME

sh