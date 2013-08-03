#!/bin/sh

#GROUP_ID=$2
#ARTIFACT_ID=$3
#ARTIFACT_TYPE=$4
#ARTIFACT_EXTENSION=$5
#MODE=$6
#DEBUG=$7

DO_NOT_OUTPUT_VERSION=false
usage(){
   echo "Usage"
   echo "-d to debug"
   echo "-g <groupId> to set group id of dependence"
   echo "-i <artifactId> to set artifact id"
   echo "-t <artifactType> to set artifcat type"
   echo "-e <extension> to set artifact extension"
   echo "-r remove the version of the retrieved file, will save file as <artifactId>.<extension>"
   echo "-m <mode> to set mode (releases/snapshots)"
   echo "-u <nexus url> to set the nexus url"
}

log(){
   echo $1
}

while getopts "u:g:i:t:e:m:dr" Option ; do
   case $Option in
       r)
           DO_NOT_OUTPUT_VERSION=true;
           log "Not appending version";
       ;;
       u)
           NEXUS_URL=$OPTARG;
           log "Using nexus url $OPTARG";
       ;;
       d)
           log "Use debug";
           DEBUG=true;
       ;;
       g)
           GROUP_ID=${OPTARG};
           log "Using group id ${GROUP_ID}";
       ;;
       i)
           ARTIFACT_ID=${OPTARG};
           log "Using artifact id ${OPTARG}";
       ;;
       t)    ARTIFACT_TYPE=${OPTARG};
           log "Using artificat type ${OPTARG}";
       ;;
       e)    ARTIFACT_EXTENSION=${OPTARG};
           log "Using artifact extension ${OPTARG}";
       ;;
       m)    MODE=${OPTARG}
           log "Using mode $MODE"
       ;;
       *)
           log "Unimplemented option chosen";
           usage;
           exit 1;
       ;;
   esac
done

if [ "x${DEBUG}" = "x" ]; then
   echo "No debug settings, defaulted to false"
   DEBUG=false
elif [ "${DEBUG}" = "true" ]; then
   echo "debug is true"
   DEBUG=true
elif [ "${DEBUG}" = "false" ]; then
   echo "debug is false"
   DEBUG=false
fi

if [ "w${MODE}" = "w" ]; then
   [ "$DEBUG" = "true" ] && echo "Defaulting mode to snapshots.";
   MODE=snapshots
fi

if [ "$MODE" = "snapshots" ]; then
   VERSION_FILTER=baseVersion
elif [ "$MODE" = "releases" ]; then
   VERSION_FILTER=version
fi

if [ "$DEBUG" = "true" ] ; then
   echo "Using ${MODE}"

   NEXUS_URL=$(echo $NEXUS_URL | sed 's/ //g')
   MODE=$(echo $MODE | sed 's/ //g')
   GROUP_ID=$(echo $GROUP_ID | sed 's/ //g')
   ARTIFACT_ID=$(echo $ARTIFACT_ID | sed 's/ //g')
   ARTIFACT_TYPE=$(echo $ARTIFACT_TYPE | sed 's/ //g')
   ARTIFACT_EXTENSION=$(echo $ARTIFACT_EXTENSION | sed 's/ //g')

   echo "Retrieving version using command: curl --silent ${NEXUS_URL}/service/local/artifact/maven/resolve?r=${MODE}&g=$GROUP_ID&a=$ARTIFACT_ID&v=LATEST&c=$ARTIFACT_TYPE&e=$ARTIFACT_EXTENSION" 
   echo "Result is `curl --silent "${NEXUS_URL}/service/local/artifact/maven/resolve?r=${MODE}&g=${GROUP_ID}&a=${ARTIFACT_ID}&v=LATEST&c=${ARTIFACT_TYPE}&e=${ARTIFACT_EXTENSION}"`"
fi

CURL_ARGS=
[ "$DEBUG" != "true" ] && CURL_ARGS="--silent";

[ "$DEBUG" = "true" ] && echo "Using curl args $CURL_ARGS";

if [ "$MODE" = "snapshots" ]; then
   ARTIFACT_LAST_VERSION=$(curl $CURL_ARGS "${NEXUS_URL}/service/local/artifact/maven/resolve?r=${MODE}&g=${GROUP_ID}&a=${ARTIFACT_ID}&v=LATEST&c=${ARTIFACT_TYPE}&e=${ARTIFACT_EXTENSION}" | sed -n 's|<baseVersion>\(.*\)</baseVersion>|\1|p')
elif [ "$MODE" = "releases" ]; then
   ARTIFACT_LAST_VERSION=$(curl $CURL_ARGS "${NEXUS_URL}/service/local/artifact/maven/resolve?r=${MODE}&g=${GROUP_ID}&a=${ARTIFACT_ID}&v=LATEST&c=${ARTIFACT_TYPE}&e=${ARTIFACT_EXTENSION}" | sed -n 's|<version>\(.*\)</version>|\1|p')

fi

if [ -z ${ARTIFACT_LAST_VERSION} ]; then
   echo "ERROR: $ARTIFACT_ID, no version found"
   return
fi

ARTIFACT_LAST_VERSION=`echo "$ARTIFACT_LAST_VERSION" | tr -d ' '`

echo "$ARTIFACT_ID version is $ARTIFACT_LAST_VERSION"

WGET_ARGS=
[ "$DEBUG" != "true" ] && WGET_ARGS="--quiet";
[ "$DEBUG" = "true" ] && echo "Using wget args $WGET_ARGS";
[ "$DO_NOT_OUTPUT_VERSION" = "true" ] && FILE_NAME=$ARTIFACT_ID.$ARTIFACT_EXTENSION;
[ "$DO_NOT_OUTPUT_VERSION" = "false" ] && FILE_NAME=$ARTIFACT_ID-$ARTIFACT_LAST_VERSION.$ARTIFACT_EXTENSION;

wget -O $FILE_NAME $WGET_ARGS "${NEXUS_URL}/service/local/artifact/maven/redirect?r=$MODE&g=$GROUP_ID&a=$ARTIFACT_ID&e=$ARTIFACT_EXTENSION&c=$ARTIFACT_TYPE&v=LATEST" 