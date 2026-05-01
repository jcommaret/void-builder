#!/usr/bin/env bash
# shellcheck disable=SC1091

set -e

if [[ "${SHOULD_BUILD}" != "yes" && "${FORCE_UPDATE}" != "true" ]]; then
  echo "Will not update version JSON because we did not build"
  exit 0
fi

if [[ -z "${GH_TOKEN}" ]] && [[ -z "${GITHUB_TOKEN}" ]] && [[ -z "${GH_ENTERPRISE_TOKEN}" ]] && [[ -z "${GITHUB_ENTERPRISE_TOKEN}" ]]; then
  echo "Will not update version JSON because no GITHUB_TOKEN defined"
  exit 0
else
  GITHUB_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-${GH_ENTERPRISE_TOKEN:-${GITHUB_ENTERPRISE_TOKEN}}}}"
fi

# Support for GitHub Enterprise
GH_HOST="${GH_HOST:-github.com}"

if [[ "${FORCE_UPDATE}" == "true" ]]; then
  . version.sh
fi

if [[ -z "${BUILD_SOURCEVERSION}" ]]; then
  echo "Will not update version JSON because no BUILD_SOURCEVERSION defined"
  exit 0
fi

# init versions repo for later commiting + pushing the json file to it
# thank you https://www.vinaygopinath.me/blog/tech/commit-to-master-branch-on-github-using-travis-ci/
git clone "https://${GH_HOST}/${VERSIONS_REPOSITORY}.git"
cd "${REPOSITORY_NAME}" || { echo "'${REPOSITORY_NAME}' dir not found"; exit 1; }
git config user.email "$( echo "${GITHUB_USERNAME}" | awk '{print tolower($0)}' )-ci@not-real.com"
git config user.name "${GITHUB_USERNAME} CI"
git remote rm origin
git remote add origin "https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@${GH_HOST}/${VERSIONS_REPOSITORY}.git" &> /dev/null
cd ..

if [[ "${OS_NAME}" == "osx" ]]; then
  ASSET_NAME="${APP_NAME}-${RELEASE_VERSION}.dmg"
  VERSION_PATH="${VSCODE_QUALITY}/darwin/${RELEASE_VERSION}"
  updateLatestVersion
