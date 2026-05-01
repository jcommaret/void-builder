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
elif [[ "${OS_NAME}" == "windows" ]]; then
  # system installer
  ASSET_NAME="${APP_NAME}Setup-${VSCODE_ARCH}-${RELEASE_VERSION}.exe"
  VERSION_PATH="${VSCODE_QUALITY}/win32/${RELEASE_VERSION}/system"
  updateLatestVersion

  # user installer
  ASSET_NAME="${APP_NAME}UserSetup-${VSCODE_ARCH}-${RELEASE_VERSION}.exe"
  VERSION_PATH="${VSCODE_QUALITY}/win32/${RELEASE_VERSION}/user"
  updateLatestVersion

  # windows archive
  ASSET_NAME="${APP_NAME}-win32-${VSCODE_ARCH}-${RELEASE_VERSION}.zip"
  VERSION_PATH="${VSCODE_QUALITY}/win32/${RELEASE_VERSION}/archive"
  updateLatestVersion

  if [[ "${VSCODE_ARCH}" == "ia32" || "${VSCODE_ARCH}" == "x64" ]]; then
    # msi
    ASSET_NAME="${APP_NAME}-${VSCODE_ARCH}-${RELEASE_VERSION}.msi"
    VERSION_PATH="${VSCODE_QUALITY}/win32/${RELEASE_VERSION}/msi"
    updateLatestVersion

    # updates-disabled msi
    ASSET_NAME="${APP_NAME}-${VSCODE_ARCH}-updates-disabled-${RELEASE_VERSION}.msi"
    VERSION_PATH="${VSCODE_QUALITY}/win32/${RELEASE_VERSION}/msi-updates-disabled"
    updateLatestVersion
  fi
else # linux
  ASSET_NAME="${APP_NAME}-linux-${VSCODE_ARCH}-${RELEASE_VERSION}.tar.gz"
  VERSION_PATH="${VSCODE_QUALITY}/linux/${RELEASE_VERSION}"
  updateLatestVersion
fi

cd "${REPOSITORY_NAME}" || { echo "'${REPOSITORY_NAME}' dir not found"; exit 1; }

git pull origin main
git add .

CHANGES=$( git status --porcelain )

if [[ -n "${CHANGES}" ]]; then
  echo "Some changes have been found, pushing them"
  dateAndMonth=$( date "+%D %T" )
  git commit -m "CI update: ${dateAndMonth} (Build ${GITHUB_RUN_NUMBER})"
  if ! git push origin main --quiet; then
    git pull origin main
    git push origin main --quiet
  fi
else
  echo "No changes"
fi

cd ..
