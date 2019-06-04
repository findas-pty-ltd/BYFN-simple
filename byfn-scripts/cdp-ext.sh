#!/bin/bash
current_version=$(docker ps | grep dev-peer0.org1.example.com-mycc- | awk '{print $2}' | head -n 1 | sed 's/-/ /g' | awk '{print $4}')
new_version=$(echo $current_version | awk -F. -v OFS=. 'NF==1{print ++$NF}; NF>1{if(length($NF+1)>length($NF))$(NF-1)++; $NF=sprintf("%0*d", length($NF), ($NF+1)%(10^length($NF))); print}')


echo "Deploying Chaincode Version $new_version"
function update(){
    version=$1
    echo "Updaing ChainCode"
    docker exec cli scripts/update_chaincode.sh $version 2>&1
    return $?
    echo "Success Updating"
}

function test_cc(){
    echo "Testing ChainCode"
    docker exec cli scripts/test_sc.sh 2>&1
    return $?
    echo "Success Testing"
}
function print_logs() {
    echo "Printing Logs"
    docker logs -t $(docker ps | grep dev-peer | head -n 1 | awk '{print $1}')
    return $?
    echo "Success Printing"
}
function remove_old() {
    echo "Removing Old Version"
    version=$(echo "\-"$version"\-" | sed 's/\./\\\./g')
    old_containers=$(docker ps -a | grep dev-peer | grep -Ev "$version" | awk '{print $1}')
    echo "Removing Containers"
    echo $old_containers
    docker rm -f $old_containers
    old_images=$(docker images | grep dev-peer | grep -Ev "$version" )
    echo "Removing Images"
    echo $old_images
    docker rmi -f $old_images
    echo "Success Removing"
}
function error(){
    echo $1
    exit 1
}


update $new_version || error "error updating"
sleep 2
#test_cc || error "error testing"

print_logs || error "error printing cc logs"
remove_old $new_version
 

echo "Finished Build"
exit 0

