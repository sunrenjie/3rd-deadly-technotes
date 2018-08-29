# This script contains functions written to help maintain docker images among
# consumers (systems running docker), local registries, and remote registries.

# Set this to a local docker registry to pull from or sync to. It shall run at
# port 5000; docker_sync_to_local use that value to filter out local images.
# Note that if localhost:5000 is used, try to define a FQDN in /etc/hosts and
# use that instead. Registry "localhost:5000" won't be accessible by other
# hosts or VMs; the registry name is actually part of the image name so no
# renaming is possible.
if [ -z $DOCKER_LOCAL_REGISTRY ]; then
export DOCKER_LOCAL_REGISTRY=localhost:5000
fi

function docker_pull {
  # Before switching mirror, be sure the hard-wired "google_containers" below is
  # handled properly.
  # Example mirrors:
  # 1) registry.cn-hangzhou.aliyuncs.com
  # 2) localhost:5000
  if [ -z $1 ] ; then
    echo "# Usage: docker_pull host.fqdn/category/component:version [mirror-url]"
    return
  fi
  local mirror=$2
  if [ -z $2 ]; then
    echo "# Info Using DOCKER_LOCAL_REGISTRY=$DOCKER_LOCAL_REGISTRY ; override to change."
    mirror=$DOCKER_LOCAL_REGISTRY
  fi
  local image_full=$1
  local hostname=$(echo $image_full | awk -F '/' '{print $1}' | grep '\.')
  if [ -z $hostname ]; then
    # A bit more flexible: don't force direct pull when hostname is "docker.io".
    echo "# Pull images without FQDN hostname prefix directly from docker.io"
    echo docker pull $image_full
    return
  fi
  # Name for the image within the mirror. K8s images don't have a category
  # component in the names, so a category name "google_containers" is added.
  image_name=$(echo $image_full | awk -F '/' '{
    if ($1 == "k8s.gcr.io") {
      print "google_containers" "/" $2
    } else if ($3 == "") {
      print $2
    } else {
      print $2 "/" $3
    }
  }')
  local image_pull=$mirror/$image_name
  local image_full2=$hostname/$image_name
  echo "# Will pull $image_pull and then rename to $image_full"
  echo docker pull $image_pull
  echo docker tag  $image_pull $image_full
  if [ $image_full != $image_full2 ]; then
    # Additional tag to maintain the additional k8s category name.
    echo "docker tag $image_pull $image_full2"
  fi
  # Do not clean up by default so that re-pull is faster.
  echo "# docker rmi $image_pull  # uncomment to clean up"
}

function docker_pull_yaml {
  local yaml=$1
  local mirror=$2
  for i in $(cat $yaml | grep 'image: "' | awk '{print $2}' | sort | uniq | xargs echo); do
    docker_pull $i $mirror
  done
}

function docker_sync_to_local {
  echo "#Info Using DOCKER_LOCAL_REGISTRY=$DOCKER_LOCAL_REGISTRY ; override to change."
  docker images --format "{{.Repository}}:{{.Tag}}" | grep -v 5000 | grep -v latest | while read l; do
    local n=$(echo $l | awk -v mirror=$DOCKER_LOCAL_REGISTRY -F '/' '{
      OFS = "/"
      $1 = mirror
      print
    }')
    echo docker tag $l $n
    echo docker push $n
  done
}

