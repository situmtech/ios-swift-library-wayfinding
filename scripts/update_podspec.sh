#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo >&2 "Error: illegal number of parameters"
    echo "Usage: bash updatePodspec.sh [PATH_TO_PROJECT_ROOT] [RELEASE_VERSION]"
    exit 1
fi

path_to_project=$1
sdk_version=$2
version_string=" s.version = \'${sdk_version}\'"
url_string=" s.source = { :http => 'https://repo.situm.es/artifactory/libs-release-local/iOS/SitumWayfinding/${sdk_version}/SitumWayfinding.zip' }"

cd $path_to_project
sed -i 'SitumWayfinding.podspec' -e "s,^ s.version .*$,$version_string," SitumWayfinding.podspec
sed -i 'SitumWayfinding.podspec' -e "s,^ s.source .*$,$url_string," SitumWayfinding.podspec

git pull
git diff --exit-code > /dev/null 2>&1 && git diff --cached --exit-code > /dev/null 2>&1
if [ $? -ne 0 ]; then
    git add SitumWayfinding.podspec
    git commit -am "Updated podspec to version $sdk_version (commited by script)"
    git push
    echo >&2 "Updated podspec to version $sdk_version"
else
    echo >&2 "ERROR: There isn't any changes to commit. Is the podspec correctly updated?"
    exit 1
fi

echo 'Script finished updating podspec.'
