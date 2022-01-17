#!/usr/bin/env bash

usage() {
	local old_xtrace
	old_xtrace="$(shopt -po xtrace || :)"
	set +o xtrace

	{
		echo "Usage: ${script_name} [flags]"
		echo "Option flags:"
		echo "  -b --dob       - Date of Birth. Default: '${dob_full}'."
		echo "  -m --monthly   - Monthly amount. Default: '${monthly}'."
		echo "  -s --age-start - Age to start. Default: '${age_start}'."
		echo "  -e --age-end   - Age to end. Default: '${age_end}'."
		echo "  -c --config    - Configuration file. Default: '${config_file}'."
		echo "  -h --help      - Show this help and exit."
		echo "  -v --verbose   - Verbose execution. Default: '${verbose}'."
		echo "  -g --debug     - Extra verbose execution. Default: '${debug}'."
		echo "Info:"
		echo "  ${script_name} - Version: @PACKAGE_VERSION@"
		echo "  Project Home: @PACKAGE_URL@"
	} >&2
	eval "${old_xtrace}"
}

process_opts() {
	local short_opts="b:m:s:e:c:hvg"
	local long_opts="dob:,monthly:,age-start:,age-end:,config:help,verbose,debug"

	local opts
	opts=$(getopt --options ${short_opts} --long ${long_opts} -n "${script_name}" -- "$@")

	eval set -- "${opts}"

	while true ; do
		# echo "${FUNCNAME[0]}: (${#}) '${*}'"
		case "${1}" in
		-b | --dob)
			dob_full="${2}"
			shift 2
			;;
		-m | --monthly)
			monthly="${2}"
			shift 2
			;;
		-s | --age-start)
			age_start="${2}"
			shift 2
			;;
		-e | --age-end)
			age_end="${2}"
			shift 2
			;;
		-c | --config)
			config_file="${2}"
			shift 2
			;;
		-h | --help)
			usage=1
			shift
			;;
		-v | --verbose)
			verbose=1
			shift
			;;
		-g | --debug)
			debug=1
			set -x
			shift
			;;
		--)
			shift
			extra_args="${*}"
			break
			;;
		*)
			echo "${script_name}: ERROR: Internal opts: '${*}'" >&2
			exit 1
			;;
		esac
	done
}

on_exit() {
	local result=${1}
	local sec="${SECONDS}"

	echo "${script_name}: Done: ${result}, ${sec} sec." >&2
}

on_err() {
	local f_name=${1}
	local line_no=${2}
	local err_no=${3}

	echo "${script_name}: ERROR: function=${f_name}, line=${line_no}, result=${err_no}"
	exit "${err_no}"
}

check_file() {
	local src="${1}"
	local msg="${2}"
	local usage="${3}"

	if [[ ! -f "${src}" ]]; then
		echo -e "${script_name}: ERROR: File not found${msg}: '${src}'" >&2
		if [[ ${usage} ]]; then
			usage
		fi
		exit 1
	fi
}

fill_date() {
	local date="${1}"
	local -n _fill_date__array="${2}"

	local regex="^([0-9]{4})\.([0-9]{2})\.([0-9]{2})$"

	if [[ ! "${date}" =~ ${regex} ]]; then
		echo "${FUNCNAME[0]}: ERROR: No match '${date}'" >&2
		exit 1
	fi

	_fill_date__array[full]="${date}"
	_fill_date__array[year]="${BASH_REMATCH[1]}"
	_fill_date__array[month]="${BASH_REMATCH[2]}"
	_fill_date__array[day]="${BASH_REMATCH[3]}"
}

print_date() {
	local str="${1}"
	local -n _print_date__array="${2}"
	
	echo "${str}full:  ${_print_date__array[full]}"
	echo "${str}year:  ${_print_date__array[year]}"
	echo "${str}month: ${_print_date__array[month]}"
	echo "${str}day:   ${_print_date__array[day]}"
}

months_diff() {
	local -n _months_diff__start="${1}"
	local -n _months_diff__end="${2}"

	local years
	local months
	years="$(( _months_diff__end[year] - _months_diff__start[year] ))"
	months="$(( _months_diff__end[month] - _months_diff__start[month] ))"

	echo "$(( 12 * years + months ))"
}

#===============================================================================
export PS4='\[\e[0;33m\]+ ${BASH_SOURCE##*/}:${LINENO}:(${FUNCNAME[0]:-main}):\[\e[0m\] '

script_name="${0##*/}"

SECONDS=0
start_time="$(date +%Y.%m.%d-%H.%M.%S)"

real_source="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_TOP="$(realpath "${SCRIPT_TOP:-${real_source%/*}}")"

trap "on_exit 'Failed'" EXIT
trap 'on_err ${FUNCNAME[0]:-main} ${LINENO} ${?}' ERR
trap 'on_err SIGUSR1 ? 3' SIGUSR1

set -eE
set -o pipefail
set -o nounset

dob_full=''
monthly=''
age_start=''
age_end=''
config_file_default="${HOME}/${script_name%.sh}.conf"
config_file="${config_file_default}"
usage=''
verbose=''
debug=''

process_opts "${@}"

if [[ "${config_file}" != "${config_file_default}" || -f "${config_file}" ]]; then
	check_file "${config_file}" ' config file' 'usage'
	config_dir="${config_file%/*}"
	source "${config_file}"
fi

if [[ ${usage} ]]; then
	usage
	trap - EXIT
	exit 0
fi

if [[ ${extra_args} ]]; then
	set +o xtrace
	echo "${script_name}: ERROR: Got extra args: '${extra_args}'" >&2
	usage
	exit 1
fi

declare -A dob
declare -A today
declare -A pay_start
declare -A pay_end

fill_date "${dob_full}" dob
fill_date "$(date +%Y.%m.%d)" today

pay_start[year]="$(( dob[year] + age_start ))"
pay_start[month]="${dob[month]}"
pay_start[day]="${dob[day]}"
pay_start[full]="${pay_start[year]}.${pay_start[month]}.${pay_start[day]}"

pay_end[year]="$(( dob[year] + age_end + 1 ))"
pay_end[month]="${dob[month]}"
pay_end[day]="${dob[day]}"
pay_end[full]="${pay_end[year]}.${pay_end[month]}.${pay_end[day]}"

months_to_start="$(months_diff today pay_start)"
months_to_end="$(months_diff today pay_end)"
months_of_pay="$(months_diff pay_start pay_end)"

echo "SS Payout -- ${start_time}"
echo
echo "dob:              ${dob[full]}"
echo "today:            ${today[full]}"
echo
echo "payout start age: ${age_start}"
echo "payout start:     ${pay_start[full]}"
echo "payout start:     ${months_to_start} months"
echo
echo "payout end age:   ${age_end}"
echo "payout end:       ${pay_end[full]}"
echo "payout end:       ${months_to_end} months"
echo
echo "payout duration:  ${months_of_pay} months"
echo "payout amount:    \$${monthly} per month"
echo

year="$(( pay_start[year] ))"
month="$(( pay_start[month] ))"

for ((i = 1; i < months_of_pay; i++)); do
	if [[ ${verbose} ]]; then
		echo -e "month ${i}:\t${year}.${month}\t= \$$(( i * monthly ))"
	fi

	month=$(( month + 1 ))
	if (( month == 13 )); then
		month=1
		year=$(( year + 1 ))
	fi
done

echo -e "month ${i}:\t${year}.${month}\t= \$$(( i * monthly ))"
echo

trap "on_exit 'Success'" EXIT
exit 0
