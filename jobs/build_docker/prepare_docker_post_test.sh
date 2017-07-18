#!/bin/bash 
set -x
set -e

# Stop host mongo and rabbitmq service
# otherwise mongo and rabbitmq service won't run normally
# use host mongo and rabbitmq is a chioce but the coverage may be decreased.
# services will be restart in cleanup.sh, which script will always be executed.
if [ "$(service mongodb status|grep  start )" != "" ]; then
    echo $SUDO_PASSWORD |sudo -S service mongodb stop # "service mongodb stop" will return non 0 if service already stop,  while rabbitmq is fine
fi
echo $SUDO_PASSWORD |sudo -S service rabbitmq-server stop

rackhd_docker_images=`ls ${DOCKER_PATH}`
# load docker images
docker load -i $rackhd_docker_images | tee ${WORKSPACE}/docker_load_output

if [ ${USE_PREBUILT_IMAGES} == true ] ; then
    # This path is followed when using the prebuilt images to get image tag
    while IFS=:  read -r load imagename tag 
    do
       echo $tag
       break
    done < "${WORKSPACE}/docker_load_output"
    repo_list=$(echo "rackhd/files:${tag} rackhd/on-core:${tag} rackhd/on-syslog:${tag} rackhd/on-dhcp-proxy:${tag} \
                          rackhd/on-tftp:${tag} rackhd/on-wss:${tag} rackhd/on-statsd:${tag} rackhd/on-tasks:${tag} rackhd/on-taskgraph:${tag} \
                          rackhd/on-http:${tag} rackhd/ucs-service:${tag}")
    echo $repo_list >> ${WORKSPACE}/build_record
    DOCKER_RECORD_PATH=${WORKSPACE}/build_record
fi
build_record=`ls ${DOCKER_RECORD_PATH}`

image_list=`head -n 1 $build_record`

pushd $BUILD_CONFIG_DIR
find ./ -type f -exec sed -i -e "s/172.31.128.1/$DOCKER_RACKHD_IP/g" {} \;
popd

pushd $RackHD_DIR/test
# in vagrant or ova， rackhd ip are all default  172.31.128.1
# but for docker containers it‘s hard to virtualize such a IP
# so replace it with DOCKER_RACKHD_IP which is usually the eth1 IP of vmslave
find ./ -type f -exec sed -i -e "s/172.31.128.1/$DOCKER_RACKHD_IP/g" {} \;
popd

# this step must behind sed replace
pushd $RackHD_DIR/docker
# replace default config json with the one which is for test.
cp -f ${WORKSPACE}/build-config/vagrant/config/mongo/config.json ./monorail/config.json
#if clone file name is not repo name, this scirpt should be edited.
for repo_tag in $image_list; do
    repo=${repo_tag%:*}
    sed -i "s#${repo}.*#${repo_tag}#g" docker-compose-mini.yml
done

mkdir -p $WORKSPACE/build-log
set +e
docker pull mongo:latest
docker pull rabbitmq:management
set -e

docker-compose -f docker-compose-mini.yml up > $WORKSPACE/build-log/vagrant.log &
popd

#common folder is the most deep folder mounted from docker
#make sure all folder is created (all mount opreation is done),then change the authority
#check the most deep folder in docker-compose-mini.yml
mountpath="$WORKSPACE/RackHD/docker/files/mount/common"
retrytimes=20
while [ ! -d "$mountpath" ]
do
    echo "mount is not finished"
    retrytimes=$(($retrytimes-1))
    echo "retry : $retrytimes times"
    sleep 10
    if [ $retrytimes -eq 0 ]; then
        break
    fi
done

if [ -d "$mounthpath" ]

    echo "change the authority of RackHD"
    echo $SUDO_PASSWORD |sudo -S chown -R $USER:$USER $WORKSPACE/RackHD
fi
