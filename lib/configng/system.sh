

# @description Return policy as int based on original armbian-config logic.
#
# @example
#   system::see_7ZipBench
#   echo $?
#   #Output
#   0
#
# @exitcode 0  If successful.
#
# @stdout tobd.
system::see_7ZipBench() {
	echo -e "Preparing benchmark. Be patient please..."
	# Do a quick 7-zip benchmark, check whether binary is there. If not install it
	MyTool=$(which 7za || which 7zr)
	[ -z "${MyTool}" ] && apt-get -f -qq -y install p7zip && MyTool=/usr/bin/7zr
	[ -z "${MyTool}" ] && (echo "No 7-zip binary found and could not be installed. Aborting" >&2 ; exit 1)
	# Send CLI monitoring to the background to be able to spot throttling and other problems
	MonitoringOutput="$(mktemp /tmp/${0##*/}.XXXXXX)"
	trap "rm \"${MonitoringOutput}\" ; exit 0" 0 1 2 3 15
	armbianmonitor -m >${MonitoringOutput} &
	MonitoringPID=$!
	# run 7-zip benchmarks after waiting 10 seconds to spot whether the system was idle before.
	# We run the benchmark a single time by default unless otherwise specified on the command line
	RunHowManyTimes=${runs:-1}
	sleep 10
	for ((i=1;i<=RunHowManyTimes;i++)); do
		"${MyTool}" b
	done
	# report CLI monitoring results as well
	kill ${MonitoringPID}
	echo -e "\nMonitoring output recorded while running the benchmark:\n"
	sed -e '/^\s*$/d' -e '/^Stop/d' <${MonitoringOutput}
	echo -e "\n"
} 