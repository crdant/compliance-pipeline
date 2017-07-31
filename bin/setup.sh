#!/bin/bash

pipelineName= credentialsFile= concourseUrl= concourseTarget= teamName= username= password=

while [ $# -gt 0 ]; do
  case $1 in
    -p | --pipeline-name )
      pipelineName=$2
      shift
      ;;
    -l | --credentials-file )
      credentialsFile=$2
      shift
      ;;
    -c | --concourse-url )
      concourseUrl=$2
      shift
      ;;
    -t | --target )
      concourseTarget=$2
      shift
      ;;
    -n | --team-name )
      teamName=$2
      shift
      ;;
    -u | --username )
      username=$2
      shift
      ;;
    -s | --password )
      password=$2
      shift
      ;;
    * )
      echo "Unrecognized option: $1" 1>&2
      exit 1
      ;;
  esac
  shift
done

set -e

error_and_exit() {
  usage
  echo $1 >&2
  exit 1
}

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )
concourseTarget=${concourseTarget:-lite}
pipelineName=${pipelineName:-`basename $DIR`}

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

usage() {
  me=$(basename ${0})
  echo "USAGE: ${me} [-t <target>] [-p <pipeline-name>] [-n team-name] [-u <username>] [-s <password>]  [-z <credentials-yml>]"
}

loginFlags=
if [ -n "${username}" ]; then
  # only log in if we got a username
  concourseUrl=${concourseUrl:-http://192.168.100.4:8080}
  teamName=${teamName:-main}
  loginFlags="${loginFlags} -c ${concourseUrl} -n ${teamName} -u ${username}"

  if [ -n "${password}" ]; then
    loginFlags="${loginFlags} -p ${password}"
  fi
fi

if [ -z "${credentialsFile}" ]; then
  credentialsFile="${DIR}/credentials.yml"
fi
credentialsFile=$(realpath $credentialsFile)
if [ ! -f ${credentialsFile} ]; then
  usage
fi

pushd $DIR > /dev/null
  if [[ -n "${username}" ]]; then
    # only log in if we got a username
    fly -t ${concourseTarget} login ${loginFlags}
  fi
  fly -t ${concourseTarget} set-pipeline -p ${pipelineName} --config ${DIR}/ci/pipeline.yml --load-vars-from ${DIR}/ci/properties.yml --load-vars-from ${credentialsFile}
  fly -t ${concourseTarget} unpause-pipeline --pipeline ${pipelineName}
popd > /dev/null
