#!/bin/bash

version=$1

cd environment-$version/
lago cleanup
cd ../
rm -rf environment-$version/
