#!/bin/sh

usage()
{
	cat <<EOF 
`basename ${0}` [OPTION] TEST_FILE

--builddir DIR  specify where tools can be found
--srcdir DIR    specify where the source tree resides
--husk PROG     use husk around tool, e.g. 'valgrind -v'

-h, --help      print a short help screen
EOF
}

for arg; do
	case "${arg}" in
	"-h"|"--help")
		usage
		exit 0
		;;
	"--builddir")
		builddir="${2}"
		shift 2
		;;
	"--srcdir")
		srcdir="${2}"
		shift 2
		;;
	"--hash")
		hash="${2}"
		shift 2
		;;
	"--husk")
		HUSK="${2}"
		shift 2
		;;
	--)
		shift
		testfile="${1}"
		break
		;;
	"-"*)
		echo "`basename ${0}`: unknown option '${arg}'" >&2
		exit 1
		;;
	*)
		testfile="${1}"
		;;
	esac
done


## now in ${1} should be the test file
testfile="${1}"

## some helper funs
xrealpath()
{
	readlink -f "${1}" 2>/dev/null || \
	realpath "${1}" 2>/dev/null || \
	( cd "`dirname "${1}"`" || exit 1
		tmp_target="`basename "${1}"`"
		# Iterate down a (possible) chain of symlinks
		while test -L "${tmp_target}"; do
			tmp_target="`readlink "${tmp_target}"`"
			cd "`dirname "${tmp_target}"`" || exit 1
			tmp_target="`basename "${tmp_target}"`"
		done
		echo "`pwd -P || pwd`/${tmp_target}"
	) 2>/dev/null
}


tsp_create_env()
{
	TS_TMPDIR="`mktemp -d "test_suite.XXXX"`" || return 1

	TS_STDIN="${TS_TMPDIR}/stdin"
	TS_EXP_STDOUT="${TS_TMPDIR}/exp_stdout"
	TS_EXP_STDERR="${TS_TMPDIR}/exp_stderr"
	OUTFILE="${TS_TMPDIR}/tool_outfile"
	TS_EXP_EXIT_CODE="0"
	TS_DIFF_OPTS=""

	tool_stdout="${TS_TMPDIR}/tool_stdout"
	tool_stderr="${TS_TMPDIR}/tool_sterr"
}

myexit()
{
	rm -rf "${TS_TMPDIR}"
	exit ${1:-1}
}

## setup
fail=0
tsp_create_env || myexit 1

## also set srcdir in case the testfile needs it
if test -z "${srcdir}"; then
	srcdir=`xrealpath \`dirname "${0}"\``
else
	srcdir=`xrealpath "${srcdir}"`
fi

## source the check
. "${testfile}" || myexit 1

eval_echo()
{
	local ret
	local tmpf

	echo -n ${@} >&3
	if test "/dev/stdin" -ef "/dev/null"; then
		echo >&3
	else
		echo "<<EOF" >&3
		tmpf=`mktemp "/tmp/tmp.XXXXXXXXXX"`
		tee "${tmpf}" >&3
		echo "EOF" >&3
	fi

	eval ${@} < "${tmpf:-/dev/null}"
	ret=${?}
	rm -f -- "${tmpf}"
	return ${ret}
}

## check if everything's set
if test -z "${TOOL}"; then
	echo "variable \${TOOL} not set" >&2
	myexit 1
fi

## set finals
if test -x "${builddir}/${TOOL}"; then
	TOOL=`xrealpath "${builddir}/${TOOL}"`
fi

stdin=""
if test -r "${TS_STDIN}"; then
	stdin="${TS_STDIN}"
fi
stdout="${TS_EXP_STDOUT}"
stderr="${TS_EXP_STDERR}"

eval_echo "${HUSK}" "${TOOL}" "${CMDLINE}" \
	< "${stdin:-/dev/null}" \
	3>&2 \
	> "${tool_stdout}" 2> "${tool_stderr}"
tool_exit_code=${?}

echo
if test "${TS_EXP_EXIT_CODE}" != "${tool_exit_code}"; then
	echo "test exit code was ${tool_exit_code} (expected: ${TS_EXP_EXIT_CODE})"
	fail=1
	echo
fi

if test -r "${stdout}"; then
	eval diff -u "${TS_DIFF_OPTS}" "${stdout}" "${tool_stdout}" || fail=1
elif test -s "${tool_stdout}"; then
	echo
	echo "test stdout was:"
	cat "${tool_stdout}" >&2
	echo
fi
if test -r "${stderr}"; then
	eval diff -u "${TS_DIFF_OPTS}" "${stderr}" "${tool_stderr}" || fail=1
elif test -s "${tool_stderr}"; then
	echo
	echo "test stderr was:"
	cat "${tool_stderr}" >&2
	echo
fi

## check if we need to hash stuff
if test -r "${OUTFILE}"; then
	if test -n "${OUTFILE_SHA1}"; then
		sha1sum "${OUTFILE}" |
		while read sum rest; do
			if test "${sum}" != "${OUTFILE_SHA1}"; then
				cat <<EOF >&2
outfile (${OUTFILE}) hashes do not match:
SHOULD BE: ${OUTFILE_SHA1}
ACTUAL:    ${sum}
EOF
				exit 1
			fi
		done || fail=1
	fi
fi

myexit ${fail}

