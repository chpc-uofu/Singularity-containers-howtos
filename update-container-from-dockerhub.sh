#!/bin/bash

# this script checks if sif container file is present or if it has been updated on Dockerhub
# if sif file is not present, or container on Dockerhub was updated, pulls it and creates new sif file
# if this script is started while another one is running (in the same directory), this new script
# will wait till the first script creates the sif container

if [ "$#" -ne 2 ]; then
  echo "Invalid number of parameters. Usage:"
  echo "update-container-from-dockerhub.sh <DockerHub container name> <sif file name>"
  echo "e.g. update-container-from-dockerhub.sh asfdaac/s1tbx-rtc s1tbx-rtc_latest.sif"
  exit 1
fi

DOCKERNAME=$1
SIFNAME=$2

# first check if we have old digest
if [[ ! -f digest.txt || ! -f $SIFNAME ]]; then
  DIGEST="new"
else
  DIGEST=$(cat digest.txt)
fi

# Get a token for your container 
TOKEN=$(curl -s "https://auth.docker.io/token?scope=repository:$DOCKERNAME:pull&service=registry.docker.io" | jq --raw-output .token)

# Get the digest for latest in the config
NEWDIGEST=$(curl -s -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.docker.distribution.manifest.v2+json" -X GET "https://registry-1.docker.io/v2/$DOCKERNAME/manifests/latest" | jq --raw-output .config.digest)

# Pull the container if we don't have it or if digest is different.
# note - can't use -ne since that's only for integer comparison
# see http://mywiki.wooledge.org/BashFAQ/031
if [[ "$NEWDIGEST" != "$DIGEST" && ! -f contlock ]]; then
  # get rid of the pesky XDG_RUNTIME_DIR warnings
  unset XDG_RUNTIME_DIR
  touch contlock
  if [[ -f $SIFNAME ]]; then
    rm $SIFNAME
  fi
  # We need to tell singularity that this is at docker hub:
  echo "Pulling the $DOCKERNAME container from docker hub."
  singularity pull $SIFNAME docker://$DOCKERNAME
  # Update digest file
  echo $NEWDIGEST > digest.txt
  rm contlock
else
  echo "Container $DOCKERNAME already pulled or being pulled."
  # now the Docker container is being pulled so no sif file yet
  while [ ! -f $SIFNAME ]
  do
    echo "Waiting for container to be pulled"
    sleep 10
  done
  # now the sif file exists but may still be being built
  filemtime=`stat -c %Y $SIFNAME`
  currtime=`date +%s`
  diff=$(( (currtime - filemtime) ))
  while [ "$diff" -lt 10 ]; do
    echo "Waiting for sif file to be built"
    sleep 10
    filemtime=`stat -c %Y $SIFNAME`
    currtime=`date +%s`
    diff=$(( (currtime - filemtime) ))
  done
fi
