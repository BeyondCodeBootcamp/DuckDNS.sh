#!/bin/sh
set -e
set -u

dep_check() {
    if ! command -v dig > /dev/null; then
        echo "command 'dig' not found: please install 'dig' (part of 'dnsutils')"
        return 1
    fi

    if ! command -v curl > /dev/null; then
        echo "command 'curl' not found: please install 'curl'"
        return 1
    fi
}

update_ip() {
    my_domain_ipv4="$(
        dig +short A beyondfoo.duckdns.org
    )"
    my_domain_ipv6="$(
        dig +short AAAA beyondfoo.duckdns.org
    )"
    echo "A ${my_domain_ipv4}"
    echo "AAAA ${my_domain_ipv6}"

    my_current_ipv4="$(
        curl -fsSL 'https://api.ipify.org?format=text'
    )"
    my_current_ipv6="$(
        curl -fsSL 'https://api64.ipify.org?format=text'
    )"
    if [ "${my_current_ipv4}" = "${my_current_ipv6}" ]; then
        my_current_ipv6=""
    fi
    echo "ipv4 ${my_current_ipv4}"
    echo "ipv6 ${my_current_ipv6}"
}

main() {
    dep_check
    update_ip
}

main
