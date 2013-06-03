#!/bin/bash

# defaults
APP_PORT=80
BRANCH=master
ENV=production

if [ -z "$2" ]; then
  ENV=production
else
  ENV=$2
fi

PWD=`pwd`
source "$PWD/meteoric.config.sh"
source "$PWD/meteoric.config.$ENV.sh"

if [ -z "$GIT_URL" ]; then
	echo "You need to create a conf file for each environment named meteoric.config.[env].sh"
	exit 1
fi

###################
# You usually don't need to change anything here –
# You should modify your meteoric.config.sh file instead.
# 
USER_DIR=/home/$APP_USER
APP_DIR=$USER_DIR/$ENV/source
ROOT_URL=http://$APP_HOST
MONGO_URL=mongodb://localhost:27017/$APP_NAME-$ENV

if $METEORITE; then
	METEOR_CMD=mrt
	METEOR_OPTIONS=''
else
	METEOR_CMD=meteor
	METEOR_OPTIONS='--release 0.6.2'
fi

if [ -z "$EC2_PEM_FILE" ]; then
	SSH_HOST="$SUDO_USER@$APP_HOST" SSH_OPT="-i $SSH_IDENTITY"
else
	SSH_HOST="ubuntu@$APP_HOST" SSH_OPT="-i $EC2_PEM_FILE"
fi

SSH_CMD="ssh $SSH_OPT $SSH_HOST"
UC="sudo -u $APP_USER"

SETUP="
sudo apt-get install software-properties-common;
sudo add-apt-repository ppa:chris-lea/node.js-legacy;
sudo apt-get -qq update;
sudo apt-get install git mongodb;
sudo apt-get install nodejs npm;
node --version;
sudo npm install -g forever;
curl https://install.meteor.com | /bin/sh;
sudo npm install -g meteorite;
"

INIT="
$UC mkdir -p $APP_DIR;
cd $APP_DIR;
$UC git clone $GIT_URL .;
$UC git checkout $BRANCH;
export MONGO_URL=$MONGO_URL;
export ROOT_URL=$ROOT_URL;
export PORT=$APP_PORT;
$METEOR_CMD $METEOR_OPTIONS;
"

DEPLOY="
cd $APP_DIR;
$UC git checkout $BRANCH;
$UC git pull origin $BRANCH;
sudo $METEOR_CMD bundle ../bundle.tgz $METEOR_OPTIONS;
cd ..;
$UC tar -zxvf bundle.tgz;
sudo rm bundle.tgz;
forever restart bundle/main.js;
"

RUN="
cd $APP_DIR;
cd ..;
export MONGO_URL=$MONGO_URL;
export ROOT_URL=$ROOT_URL;
export PORT=$APP_PORT;
forever start bundle/main.js;
"

TEST="
cd $APP_DIR;
ls -la;
"

CONNECT="
su $APP_USER;
cd ~;
"

case "$1" in
info)
	cat <<ENDCAT
Available info:

APP_NAME   - $APP_NAME
ENV        - $ENV
SSH_CMD    - $SSH_CMD
USER_DIR   - $USER_DIR
APP_DIR    - $APP_DIR
ROOT_URL   - $ROOT_URL
APP_PORT   - $APP_PORT
GIT_URL    - $GIT_URL
BRANCH     - $BRANCH
MONGO_URL  - $MONGO_URL
ENDCAT
	;;
connect)
  ssh $SSH_OPT $SSH_HOST $CONNECT
  ;;
setup)
  $SSH_CMD EXEC=$SETUP 'bash -s' <<'ENDSSH'
$EXEC
ENDSSH
  ;;
init)
  $SSH_CMD EXEC=$INIT 'bash -s' <<'ENDSSH'
$EXEC
ENDSSH
  ;;
deploy)
  $SSH_CMD EXEC=$DEPLOY 'bash -s' <<'ENDSSH'
$EXEC
ENDSSH
  ;;
run)
  $SSH_CMD EXEC=$RUN 'bash -s' <<'ENDSSH'
$EXEC
ENDSSH
  ;;
test)
  $SSH_CMD EXEC=$TEST 'bash -s' <<'ENDSSH'
$EXEC
ENDSSH
  ;;
*)
	cat <<ENDCAT
meteoric [action]

Available actions:

info   - show all info of this setup
setup   - Install a meteor environment on a fresh Ubuntu server
init    - Initialize your app
deploy  - Deploy the app to the server
run     - Run the app
ENDCAT
	;;
esac

