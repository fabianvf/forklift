#!/bin/bash -x

version=$1

if [ ! -d environment ];then
  lago -l debug init --template-repo-path=repo.json environment-${version} foreman-${version}.json
fi

pushd environment-${version}/
lago status | grep down

if [ $? == 0 ];then
  lago start
fi

popd
