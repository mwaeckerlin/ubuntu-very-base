#!/usr/bin/env bash
# Config contract: the build-only base works for build stages.
#
# A build stage needs a shell and the package manager, runs as root to install
# packages, and inherits the users and variables of mwaeckerlin/ubuntu-scratch
# so its artefacts can be handed to the unprivileged runtime user.
# `--pull=never` keeps docker from silently pulling a stale image when the
# local build is missing.
#
# Usage: tests/config-contract.sh IMAGE

set -uo pipefail

IMAGE="${1:?usage: tests/config-contract.sh IMAGE}"

PASS=0
FAIL=0
declare -a FAILED_NAMES

_pass() { PASS=$((PASS + 1)); echo "  PASS  $1"; }
_fail() { FAIL=$((FAIL + 1)); FAILED_NAMES+=("$1"); echo "  FAIL  $1: $2"; }

_env_is() {
    local name="$1" expected="$2"
    local value
    value=$(docker image inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "${IMAGE}" | sed -n "s/^${name}=//p")
    if [[ "${value}" == "${expected}" ]]; then
        _pass "env_${name}"
    else
        _fail "env_${name}" "expected '${expected}', got '${value}'"
    fi
}

echo "==> Config contract: build-only Ubuntu base"

if ! docker image inspect "${IMAGE}" > /dev/null 2>&1; then
    _fail "${IMAGE}_image_exists" "image not built — run 'npm run build' first"
else
    if docker run --rm --pull=never "${IMAGE}" sh -c '$PKG_SEARCH musl' 2>/dev/null | grep -q '^musl '; then
        _pass "package_manager_works"
    else
        _fail "package_manager_works" "\$PKG_SEARCH does not find the Ubuntu package lists"
    fi

    # apt keeps no index of its own per call: $PKG_INSTALL works only because
    # the image ships the package lists
    INSTALL=$(docker run --rm --pull=never "${IMAGE}" sh -c '$PKG_INSTALL musl && dpkg-query -W musl' 2>&1)
    if [[ $? -eq 0 ]]; then
        _pass "package_install_works"
    else
        _fail "package_install_works" "\$PKG_INSTALL cannot install a package: ${INSTALL}"
    fi
    # a missing locale or a debconf frontend looking for a terminal warns on
    # every install of every build stage
    WARNINGS=$(echo "${INSTALL}" | grep -iE 'warning|debconf: unable')
    if [[ -z "${WARNINGS}" ]]; then
        _pass "package_install_silent"
    else
        _fail "package_install_silent" "${WARNINGS}"
    fi

    WHO=$(docker run --rm --pull=never "${IMAGE}" id -u 2>&1)
    if [[ "${WHO}" == "0" ]]; then
        _pass "runs_as_root"
    else
        _fail "runs_as_root" "build stages run as uid '${WHO}'"
    fi

    for user in somebody coder; do
        if docker run --rm --pull=never "${IMAGE}" id "${user}" > /dev/null 2>&1; then
            _pass "user_${user}"
        else
            _fail "user_${user}" "user missing"
        fi
    done
    # the same ids as mwaeckerlin/scratch, so files a build stage hands over
    # keep their owner in the runtime base
    for entry in somebody:100:1000 coder:101:1001; do
        IFS=: read -r user uid gid <<< "${entry}"
        IDS=$(docker run --rm --pull=never "${IMAGE}" sh -c "id -u ${user}; id -g ${user}" 2>&1 | tr '\n' ':')
        if [[ "${IDS}" == "${uid}:${gid}:" ]]; then
            _pass "ids_${user}"
        else
            _fail "ids_${user}" "expected uid:gid ${uid}:${gid}, got '${IDS}'"
        fi
    done
    if docker run --rm --pull=never "${IMAGE}" sh -c '! id ubuntu && test ! -e /home/ubuntu' > /dev/null 2>&1; then
        _pass "no_user_ubuntu"
    else
        _fail "no_user_ubuntu" "the default user ubuntu or its home is still present"
    fi
    if docker run --rm --pull=never "${IMAGE}" sh -c 'test -d "$RUN_HOME" && $ALLOW_USER /tmp' > /dev/null 2>&1; then
        _pass "run_home_and_allow_user"
    else
        _fail "run_home_and_allow_user" "\$RUN_HOME missing or \$ALLOW_USER fails"
    fi

    _env_is CONTAINERNAME ubuntu-very-base
    _env_is RUN_USER somebody
    _env_is BUILD_USER coder
    _env_is PKG_INSTALL "apt-get install --no-install-recommends --no-install-suggests -y"
    _env_is LANG en_US.UTF-8
    if docker run --rm --pull=never "${IMAGE}" locale -a 2>&1 | grep -qx 'en_US.utf8'; then
        _pass "locale_generated"
    else
        _fail "locale_generated" "the locale of LANG is not generated"
    fi

    CHILD="${IMAGE%%:*}-config-contract-child"
    if printf 'FROM %s\n' "${IMAGE}" | docker build --quiet --build-arg lang=de_CH.UTF-8 -t "${CHILD}" - > /dev/null 2>&1; then
        CHILD_LANG=$(docker image inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "${CHILD}" | sed -n 's/^LANG=//p')
        CHILD_LOCALES=$(docker run --rm --pull=never "${CHILD}" locale -a 2>&1)
        docker image rm "${CHILD}" > /dev/null
        if [[ "${CHILD_LANG}" == "de_CH.UTF-8" ]]; then
            _pass "child_lang_build_arg"
        else
            _fail "child_lang_build_arg" "child LANG is '${CHILD_LANG}'"
        fi
        if echo "${CHILD_LOCALES}" | grep -qx 'de_CH.utf8'; then
            _pass "child_locale_generated"
        else
            _fail "child_locale_generated" "locale -a in the child: ${CHILD_LOCALES}"
        fi
    else
        _fail "child_lang_build_arg" "child image does not build"
    fi
fi

echo ""
echo "==> Config contract results: ${PASS} passed, ${FAIL} failed"
if [[ ${FAIL} -gt 0 ]]; then
    echo "==> Failed contracts: ${FAILED_NAMES[*]}"
    exit 1
fi
