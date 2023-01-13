#!/bin/sh

set -e
set -u

# ipify API docs: https://ipify.org
# duckdns API docs: https://duckdns.org/spec.jsp

my_subdomain="${2-}"
if [ -z "${my_subdomain}" ]; then
    echo "Usage: duckdns.sh run <subdomain>"
    exit 1
fi

if [ -z "${DUCKDNS_TOKEN-}" ]; then
    if ! [ -e ~/.config/duckdns.sh/"${my_subdomain}.env" ]; then
        echo "Missing '~/.config/duckdns.sh/${my_subdomain}.env'"
        exit 1
    fi

    # shellcheck disable=SC1090
    . ~/.config/duckdns.sh/"${my_subdomain}.env"
    if [ -z "${DUCKDNS_TOKEN-}" ]; then
        echo "Missing 'DUCKDNS_TOKEN=<uuid>' from '~/.config/duckdns.sh/${my_subdomain}.env'"
        exit 1
    fi
fi

dep_check() { (
    if ! command -v dig > /dev/null; then
        echo "command 'dig' not found: please install 'dig' (part of 'dnsutils')"
        return 1
    fi

    if ! command -v curl > /dev/null; then
        echo "command 'curl' not found: please install 'curl'"
        return 1
    fi
); }

update_ips() { (
    my_domain_ipv4="$(
        dig +short A "${my_subdomain}.duckdns.org"
    )"
    my_domain_ipv6="$(
        dig +short AAAA "${my_subdomain}.duckdns.org"
    )"
    echo "${my_subdomain}.duckdns.org A ${my_domain_ipv4:-(NONE)}"
    echo "${my_subdomain}.duckdns.org AAAA ${my_domain_ipv6:-(NONE)}"

    my_current_ipv4="$(
        curl -fsSL 'https://api.ipify.org?format=text'
    )"
    my_current_ipv6="$(
        curl -fsSL 'https://api64.ipify.org?format=text'
    )"
    if [ "${my_current_ipv4}" = "${my_current_ipv6}" ]; then
        my_current_ipv6=""
    fi
    echo "IPv4 ${my_current_ipv4:-(NONE)}"
    echo "IPv6 ${my_current_ipv6:-(NONE)}"

    # if either ip changed to be empty, clear both
    if [ "${my_current_ipv4}" != "${my_domain_ipv4}" ]; then
        if [ -z "${my_current_ipv4}" ]; then
            duckdns_clear
            my_domain_ipv4=""
            my_domain_ipv6=""
        fi
    fi
    if [ "${my_current_ipv6}" != "${my_domain_ipv6}" ]; then
        if [ -z "${my_current_ipv6}" ]; then
            duckdns_clear
            my_domain_ipv4=""
            my_domain_ipv6=""
        fi
    fi

    # Note: at least one of the IPv4 or IPv6 *must* exist
    # (otherwise we wouldn't even be able to get a empty response)
    if [ "${my_current_ipv4}" != "${my_domain_ipv4}" ]; then
        if [ "${my_current_ipv6}" != "${my_domain_ipv6}" ]; then
            duckdns_update "${my_current_ipv4}" "${my_current_ipv6}"
        else
            duckdns_update "${my_current_ipv4}" ""
        fi
    else
        if [ "${my_current_ipv6}" != "${my_domain_ipv6}" ]; then
            duckdns_update "" "${my_current_ipv6}"
        else
            echo "No change detected."
        fi
    fi
); }

duckdns_clear() { (
    printf "Unsetting IP address(es)... "

    curl "https://www.duckdns.org/update?domains=${my_subdomain}&token=${DUCKDNS_TOKEN}&clear=true"
    # &verbose=true

    echo ""
); }

duckdns_update() { (
    my_ipv4="${1}"
    my_ipv6="${2}"

    my_ipv4_param=""
    my_ipv6_param=""
    if [ -n "${my_ipv6}" ]; then
        if [ -n "${my_ipv4}" ]; then
            my_ipv4_param="&ip=${my_ipv4}"
            my_ipv6_param="&ipv6=${my_ipv6}"
            printf "Updating IPv4 and IPv6... "
        else
            my_ipv4_param="&ip=${my_ipv6}"
            printf "Updating IPv6... "
        fi
    else
        if [ -n "${my_ipv4}" ]; then
            my_ipv4_param="&ip=${my_ipv4}"
            printf "Updating IPv4... "
        else
            echo >&2 "duckdns_update must receive at least one of ipv4 or ipv6"
            return 1
        fi
    fi

    curl "https://www.duckdns.org/update?domains=${my_subdomain}&token=${DUCKDNS_TOKEN}${my_ipv4_param}${my_ipv6_param}"
    # &verbose=true

    # duckdns.org will respond with "OK", but we still need a newline
    echo ""
); }

main() { (
    dep_check

    my_minutes=1
    my_wait="$((my_minutes * 60))"
    while true; do
        update_ips
        echo "Waiting ${my_minutes}m to try again..."
        sleep "${my_wait}"
        echo ""
    done
); }

main
