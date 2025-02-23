#!/bin/sh
# shellcheck disable=SC2317
. "${srcdir:-.}/lib.sh"

export MSG="no-openlog-apitest"

#
# Test steps
#

verify_basic_syslog()
{
    ./api
    grep "api: ${MSG}" "${LOG}"
}

verify_basic_openlog()
{
    cat <<-EOF >"${CONFD}/console.conf"
	console.*	-${LOGCONS}
	EOF
    reload

    ./api -i foo
    tenacious 2 grep "foo: ${MSG}" "${LOGCONS}"
}

verify_setlogmask_all()
{
    ./api -i xyzzy
    tenacious 2 grep "xyzzy: ${MSG}" "${LOGCONS}"
}

# Expected to fail, logs with LOG_INFO
verify_setlogmask_notice()
{
    ./api -i bar -l
    sleep 1			# Account for any possible delays
    grep "bar: ${MSG}" "${LOGCONS}" || return 0
}

verify_syslogp()
{
    cat <<-EOF >"${CONFD}/v1.conf"
	ftp.*		-${LOGV1}	;RFC5424
	EOF
    reload

    ./api -i troglobit -p
    tenacious 2 grep "troglobit - MSGID - ${MSG}" "${LOGV1}"
}

verify_rfc5424()
{
    ../src/logger -p ftp.notice -u "${SOCK}" -m "MSDSD" -d '[exampleSDID@32473 iut="3" eventSource="Application" eventID="1011"]' "waldo"
    tenacious 2 grep "exampleSDID@32473" "${LOGV1}"
}

verify_fqdn()
{
    ../src/logger -p ftp.notice -u "${SOCK}" -m "MSDSD" -H "baz.example.com" "Xyzzy"
    tenacious 2 grep "baz.example.com" "${LOGV1}"
}

verify_localN_notice()
{
    cat <<-EOF >"${CONFD}/notice.conf"
	*.notice	-${LOG2}
	EOF
    reload

    ../src/logger -p local7.notice -u "${SOCK}" "aye matey"
    grep "aye matey" "${LOG2}"
}

# Expected to fail
verify_localN_info()
{
    ../src/logger -p local7.info -u "${SOCK}" "nopenope"
    sleep 1			# Account for any possible delays
    grep "nopenope" "${LOG2}" 2>/dev/null || return 0
}

#
# Run test steps
#

run_step "Set up local syslog daemon"             setup -m0
run_step "Verify syslog(), no openlog()"          verify_basic_syslog
run_step "Verify openlog() with custom facility"  verify_basic_openlog
run_step "Verify setlogmask() default behavior"   verify_setlogmask_all
run_step "Verify setlogmask() LOG_NOTICE"         verify_setlogmask_notice
run_step "Verify RFC5424 API with syslogp()"      verify_syslogp
run_step "Verify RFC5424 API with logger(1)"      verify_rfc5424
run_step "Verify RFC5424 FQDN with logger(1)"     verify_fqdn
run_step "Verify localN notice with logger(1)"    verify_localN_notice
run_step "Verify localN info leak with logger(1)" verify_localN_info
