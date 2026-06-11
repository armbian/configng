module_options+=(
	["module_redis,author"]="@armbian"
	["module_redis,maintainer"]="@igorpecovnik"
	["module_redis,feature"]="module_redis"
	["module_redis,example"]="install remove purge status help"
	["module_redis,desc"]="Install Redis in a container (in-memory LRU cache)"
	["module_redis,status"]="Active"
	["module_redis,doc_link"]="https://redis.io/docs/"
	["module_redis,group"]="Database"
	["module_redis,port"]="6379"
	["module_redis,arch"]="x86-64 arm64"
	["module_redis,dockerimage"]="redis:latest"
	["module_redis,dockername"]="redis"
	["module_redis,maxmemory"]="64gb"
	["module_redis,maxmemory_policy"]="allkeys-lru"
	["module_redis,maxmemory_samples"]="10"
	["module_redis,nofile"]="100000"
	["module_redis,io_threads"]="4"
	["module_redis,save"]="86400 1"
	["module_redis,stop_timeout"]="300"
)
#
# Module Redis
#
function module_redis () {
	local title="Redis"
	local dockerimage="${module_options["module_redis,dockerimage"]}"
	local dockername="${module_options["module_redis,dockername"]}"
	local port="${module_options["module_redis,port"]}"
	local maxmemory="${module_options["module_redis,maxmemory"]}"
	local maxmemory_policy="${module_options["module_redis,maxmemory_policy"]}"
	local maxmemory_samples="${module_options["module_redis,maxmemory_samples"]}"
	local nofile="${module_options["module_redis,nofile"]}"
	local io_threads="${module_options["module_redis,io_threads"]}"
	local save="${module_options["module_redis,save"]}"
	local stop_timeout="${module_options["module_redis,stop_timeout"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_redis,example"]}"

	# RDB snapshot is written to /data inside the container (the official
	# image's working dir), persisted to the host through this bind-mount so
	# the cache survives restarts.
	local base_dir="${SOFTWARE_FOLDER}/redis"

	case "$1" in
		"${commands[0]}") # install
			# Pull image (handles Docker installation and already-installed check)
			docker_operation_progress pull "$dockerimage"

			# Create base directory for the RDB bind-mount
			docker_manage_base_dir create "$base_dir" || return 1

			# Run as an in-memory LRU cache with RDB persistence: AOF stays off
			# to avoid continuous disk I/O, while a single infrequent save point
			# (module_redis,save) keeps runtime snapshotting minimal. Redis also
			# writes an RDB snapshot on graceful shutdown, so a planned restart /
			# `docker stop` keeps the data. --stop-timeout raises Docker's 10s
			# SIGTERM grace period so a large snapshot can finish before SIGKILL.
			# Eviction keeps memory bounded at maxmemory.
			#
			# Throughput tuning for the ccache remote-storage workload (many
			# runners pushing/pulling large object blobs over a fast link):
			#   - io-threads (+do-reads): parallelize network read/write, the
			#     real bottleneck for big payloads over a fat pipe
			#   - lazyfree-*: evict/free large values on a background thread so
			#     eviction under allkeys-lru never stalls the event loop
			#   - maxmemory-samples: more accurate LRU so hot objects survive
			#   - activedefrag: reclaim fragmentation in a long-running cache
			docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--net=lsio \
				--restart=always \
				-p "${port}:6379" \
				--ulimit "nofile=${nofile}:${nofile}" \
				--stop-timeout "$stop_timeout" \
				-v "${base_dir}/data:/data" \
				"$dockerimage" \
				redis-server \
				--maxmemory "$maxmemory" \
				--maxmemory-policy "$maxmemory_policy" \
				--maxmemory-samples "$maxmemory_samples" \
				--io-threads "$io_threads" \
				--io-threads-do-reads yes \
				--lazyfree-lazy-eviction yes \
				--lazyfree-lazy-expire yes \
				--lazyfree-lazy-server-del yes \
				--activedefrag yes \
				--appendonly no \
				--save "$save"
		;;
		"${commands[1]}") # remove
			# Remove container and image (functions handle existence checks)
			docker_operation_progress rm "$dockername"
			docker_operation_progress rmi "$dockerimage"
		;;
		"${commands[2]}") # purge
			# Remove container and image first
			if ! ${module_options["module_redis,feature"]} ${commands[1]}; then
				return 1
			fi
			# Only remove data directory if container/image removal succeeded
			docker_manage_base_dir remove "$base_dir"
		;;
		"${commands[3]}") # status
			# Return 0 if installed, 1 if not (used by menu system)
			docker_is_installed "$dockername" "$dockerimage"
		;;
		"${commands[4]}") # help
			show_module_help "module_redis" "$title" \
				"In-memory LRU cache with RDB persistence — an RDB snapshot is written on graceful shutdown and reloaded on start, so planned restarts keep the data (a hard crash may lose writes since the last snapshot). Tuned for the ccache remote-storage workload: threaded network I/O, background (lazyfree) eviction and active defragmentation.\n\nPort: ${port}\nDocker Image: ${dockerimage}\nMax memory: ${maxmemory}\nEviction policy: ${maxmemory_policy} (samples ${maxmemory_samples})\nIO threads: ${io_threads}\nOpen files limit: ${nofile}\nSave points: ${save}\nStop timeout: ${stop_timeout}s\nData directory: ${base_dir}/data"
		;;
		*)
			${module_options["module_redis,feature"]} ${commands[4]}
		;;
	esac
}
