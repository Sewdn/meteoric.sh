#!/bin/bash44

# defaults
APP_PORT=80
BRANCH=master

PWD=`pwd`
if [ -z "$2" ]; then
	ENV=production
else
	ENV=$2
fi
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
APP_DIR = $USER_DIR/$ENV/$APP_NAME
ROOT_URL=http://$APP_HOST
MONGO_URL=mongodb://localhost:27017/$APP_NAME

if $METEORITE; then
	METEOR_CMD=mrt
	METEOR_OPTIONS=''
else
	METEOR_CMD=meteor
	METEOR_OPTIONS='--release 0.6.2'
fi

if [ -z "$EC2_PEM_FILE" ]; then
	SSH_HOST="$APP_USER@$APP_HOST" SSH_OPT=""
else
	SSH_HOST="ubuntu@$APP_HOST" SSH_OPT="-i $EC2_PEM_FILE"
fi



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
sudo mkdir -p $APP_DIR;
cd $APP_DIR;
sudo git clone $GIT_URL .;
"

DEPLOY="
cd $APP_DIR;
git checkout $BRANCH;
git pull origin $BRANCH;
$METEOR_CMD bundle ../bundle.tgz $METEOR_OPTIONS;
cd ..;
tar -zxvf bundle.tgz;
rm bundle.tgz;
"

RUN="
cd $APP_DIR;
cd ..;
export MONGO_URL=$MONGO_URL;
export ROOT_URL=$ROOT_URL;
export PORT=$APP_PORT;
forever start bundle/main.js;
"

case "$1" in
setup)
	ssh $SSH_OPT $SSH_HOST $SETUP
	;;
init)
	ssh $SSH_OPT $SSH_HOST $INIT
	;;
deploy)
	ssh $SSH_OPT $SSH_HOST $DEPLOY
	;;
run)
	ssh $SSH_OPT $SSH_HOST $RUN
	;;
*)
	cat <<ENDCAT
meteoric [action]

Available actions:

setup   - Install a meteor environment on a fresh Ubuntu server
init    - Initialize your app
deploy  - Deploy the app to the server
run  		- Run the app
ENDCAT
	;;
esac

