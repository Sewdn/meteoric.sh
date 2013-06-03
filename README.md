# Meteoric

Deploy Meteor on EC2 (or your own server)

## How to install and update

The easiest way to install (or update) `meteoric` is using curl:

```bash
$ curl https://raw.github.com/Sewdn/meteoric.sh/master/install | sh
```

You may need to `sudo` in order for the script to symlink `meteoric` to your `/usr/local/bin`.

## How to use

Create a conf file named `meteoric.config.sh` and a conf file for each environment `meteoric.config.[env].sh` in your project's folder, setting the following environment variables:

```bash
# username of the root user
SUDO_USER=root

# your local key to provide access for the root user
SSH_IDENTITY=~/.ssh/id_dsa

# the remote user owning the project's source
APP_USER=microscope

# IP or URL of the server you want to deploy to
APP_HOST=example.com

# The port your server will listen to 'default: 80'
APP_PORT=8082

# Comment this if your host is not an EC2 instance
EC2_PEM_FILE=~/.ssh/your-aws-certif.pem

# What's your project's Git repo?
GIT_URL=git://github.com/SachaG/Microscope.git

# the git branch to use for this deployment
BRANCH=develop

# Does your project use meteorite, or plain meteor?
METEORITE=true

# What's your app name?
APP_NAME=microscope
```
Then just run:

```bash
# list all possible commands
$ meteoric

# setup the server with the needed software stack (nodejs, npm, mongodb)
$ meteoric setup develop

# initialize your environment: setup the directories, clone your repo, do a first meteor run to update all dependencies
$ meteoric init develop

# run your server (using forever)
$ meteoric run develop

# update your source to the latest version, regenerate the bundle and restart the server
$ meteoric deploy develop
```

## Tested on

- Ubuntu 13.04
- Ubuntu 12.10

## Inspiration

Hat tip to @netmute for his [meteor.sh script](https://github.com/netmute/meteor.sh). In our case though, we think having to rebuild native packages like `fibers` kind of defeats the whole point of bundling the Meteor app. Additionally, our approach enables hot code fixes (you don't have to stop/start your node server, and your users' apps shouldn't be disrupted).

This script is also based on this previous post: [How to deploy Meteor on Amazon EC2](http://julien-c.fr/2012/10/meteor-amazon-ec2/).

Cheers!
