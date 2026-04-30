#!/usr/bin/env bash

set -ex

GH_ARCH="amd64"
api_url="https://api.github.com/repos/cli/cli/releases/latest"

curl_opts=(
  -sS
  --retry 5
  --retry-delay 10
  -H "Accept: application/vnd.github+json"
)
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  curl_opts+=( -H "Authorization: Bearer ${GITHUB_TOKEN}" )
fi

TAG="$( curl "${curl_opts[@]}" "$api_url" | jq --raw-output '.tag_name // empty' )"

if [[ -z "${TAG}" || "${TAG}" == "null" ]]; then
  echo "Impossible d'obtenir cli/cli latest via l'API (rate limit ou erreur) ; repli sur une version pinnée." >&2
  # Mise à jour manuelle occasionnelle si ce tarball disparaît des releases.
  TAG="v2.74.0"
fi

VERSION="${TAG#v}"

curl --retry 12 --retry-delay 120 -sSL -f \
  "https://github.com/cli/cli/releases/download/${TAG}/gh_${VERSION}_linux_${GH_ARCH}.tar.gz" \
  -o "gh_${VERSION}_linux_${GH_ARCH}.tar.gz"

tar xf "gh_${VERSION}_linux_${GH_ARCH}.tar.gz"

cp "gh_${VERSION}_linux_${GH_ARCH}/bin/gh" /usr/local/bin/

gh --version
