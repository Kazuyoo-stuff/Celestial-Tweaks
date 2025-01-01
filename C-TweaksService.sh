#!/system/bin/sh
# made by @kzuyoo | Kazuyoo-stuff
# Do NOT assume where your module will be located.
# ALWAYS use $MODDIR if you need to know where this script
# and module is placed.
# This will make sure your module will still work
# if Magisk change its mount point in the future

# ----------------- GLOBAL VARIABLES -----------------
MODDIR=${0%/*}
DROPBOX_STATE=dropbox
PRIORITY_STATE=high_priority

# ----------------- HELPER FUNCTIONS -----------------
log() {
    echo "$1"
}

wait_until_boot_completed() {
    while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 3; done
    while [ ! -d "/sdcard/Android" ]; do sleep 1; done
}

write_value() {
    local file="$1"
    local value="$2"
    if [ -e "$file" ]; then
        chmod +w "$file" 2>/dev/null
        echo "$value" > "$file" && log "Write : $file → $value" || log "Failed to Write : $file"
    fi
}

calculate_mid_freq() {
    local cpu_path="$1"
    local min_freq=$(cat "$cpu_path/cpufreq/cpuinfo_min_freq")
    local max_freq=$(cat "$cpu_path/cpufreq/cpuinfo_max_freq")
    echo $(( (min_freq + max_freq) / 2 ))
}

send_notification() {
    su -lp 2000 -c "cmd notification post -S bigtext -t 'Celestial-Tweaks🍃' tag 'Status : Optimization Completed!'" >/dev/null 2>&1
}

# ----------------- OPTIMIZATION SECTIONS -----------------
optimize_dropbox() {
    if ( settings list global | grep "$DROPBOX_STATE" ); then
        settings put global dropbox null
        settings put global dropbox:event_data null
        settings put global dropbox:event_log null
        settings put global dropbox:dumpsys:batterystats null
        settings put global dropbox:dumpsys:diskstats null
        settings put global dropbox:dumpsys:procstats null
        settings put global dropbox:dumpsys:usagestats null
        settings put global dropbox:netstats_error null
        settings put global dropbox:_STR_HASH null
        settings put global dropbox:storage_trim null
        settings put global dropbox:SYSTEM_AUDIT null
        settings put global dropbox:SYSTEM_BOOT null
        settings put global dropbox:SYSTEM_FSCK null
        settings put global dropbox:SYSTEM_RESTART null
        settings put global dropbox:system_server_lowmem null
        settings put global dropbox:dumpsys:account null
        settings put global dropbox:dumpsys:user null
        settings put global dropbox:dumpsys:package null
        settings put global dropbox:BATTERY_DISCHARGE_INFO null
    else
        log "Dropbox is already configured."
    fi
}

optimize_priority () {
    if ( settings list secure | grep "$PRIORITY_STATE" ); then
        settings put secure high_priority 1
        settings put secure low_priority 0
    else
        log "Priority is already configured."
    fi
}

optimize_ged() {
    if [ -d "/sys/module/ged/parameters" ]; then
       for parameter in /sys/module/ged/parameters/*; do
          case "$(basename "$parameter")" in
            target_t_cpu_remained) write_value "$parameter" "5000000" ;;
            gpu_cust_boost_freq) write_value "$parameter" "1500000" ;;
            gpu_cust_upbound_freq) write_value "$parameter" "1800000" ;;
            gpu_bottom_freq) write_value "$parameter" "600000" ;;
            ged_smart_boost) write_value "$parameter" "500" ;;
            boost_upper_bound) write_value "$parameter" "80" ;;
            gx_game_mode) write_value "$parameter" "1" ;;
            enable_game_self_frc_detect) write_value "$parameter" "1" ;;
            cpu_boost_policy) write_value "$parameter" "1" ;;
            ged_boost_enable) write_value "$parameter" "1" ;;
            gx_boost_on) write_value "$parameter" "1" ;;
            boost_gpu_enable) write_value "$parameter" "1" ;;
            enable_gpu_boost) write_value "$parameter" "1" ;;
            ged_dvfs_enable) write_value "$parameter" "1" ;;
            boost_amp) write_value "$parameter" "1" ;;
            boost_extra) write_value "$parameter" "0" ;;
            gx_3D_benchmark_on) write_value "$parameter" "0" ;;
            gpu_idle) write_value "$parameter" "0" ;;
          esac
       done
        sleep 0.0
    else
        log "GED directory not found, skipping optimization."
    fi
}

optimize_power_policy_manager() {
    if [ -d "/proc/ppm" ]; then
        for parameter in /proc/ppm/*; do
            case "$(basename "$parameter")" in
                enabled) write_value "$parameter" "1" ;;
                policy_status)
                    write_value "$parameter" "0 1"
                    write_value "$parameter" "1 1"
                    write_value "$parameter" "2 1"
                    write_value "$parameter" "3 0"
                    write_value "$parameter" "4 0"
                    write_value "$parameter" "5 0"
                    write_value "$parameter" "6 1"
                    write_value "$parameter" "7 0"
                    write_value "$parameter" "8 0"
                    write_value "$parameter" "9 0"
                    ;;
            esac
        done
        sleep 0.0
    else
        log "PPM directory not found, skipping optimization."
    fi
}

optimize_connection() {
    for parameter in /proc/sys/net/ipv4/* /proc/sys/net/core/*; do
        case "$(basename "$parameter")" in
            tcp_wmem) write_value "$parameter" "4096 131072 8388608" ;;
            tcp_rmem) write_value "$parameter" "4096 262144 8388608" ;;
            netdev_max_backlog) write_value "$parameter" "10000" ;;
            somaxconn) write_value "$parameter" "1024" ;;
            tcp_keepalive_time) write_value "$parameter" "60" ;;
            tcp_fin_timeout) write_value "$parameter" "15" ;;
            tcp_tw_reuse) write_value "$parameter" "1" ;;
            tcp_mtu_probing) write_value "$parameter" "1" ;;
            tcp_tw_recycle) write_value "$parameter" "0" ;;
        esac
    done
}

optimize_gpu_freq() {
    if [ -d "/proc/gpufreq" ]; then
        for gpufreq in /proc/gpufreq; do
            case "$(basename "$gpufreq")" in
                gpufreq_limited_thermal_ignore) write_value "$gpufreq/gpufreq_limited_thermal_ignore" "1" ;;
                gpufreq_limited_oc_ignore) write_value "$gpufreq/gpufreq_limited_oc_ignore" "1" ;;
                gpufreq_limited_low_batt_volume_ignore) write_value "$gpufreq/gpufreq_limited_low_batt_volume_ignore" "1" ;;
                gpufreq_limited_low_batt_volt_ignore) write_value "$gpufreq/gpufreq_limited_low_batt_volt_ignore" "1" ;;
                gpufreq_opp_freq) write_value "$gpufreq/gpufreq_opp_freq" "0" ;;
                gpufreq_fixed_freq_volt) write_value "$gpufreq/gpufreq_fixed_freq_volt" "0" ;;
                gpufreq_opp_stress_test) write_value "$gpufreq/gpufreq_opp_stress_test" "0" ;;
                gpufreq_power_dump) write_value "$gpufreq/gpufreq_power_dump" "0" ;;
                gpufreq_power_limited) write_value "$gpufreq/gpufreq_power_limited" "0" ;;
            esac
        done
        sleep 0.0
    else
        log "GpuFreq directory not found, skipping optimization."
    fi
}

optimize_kernel() {
    for kernel_params in /proc/sys/kernel/*; do
        case "$(basename "$kernel_params")" in
            sched_migration_cost_ns) write_value "$kernel_params" "500000" ;;
            sched_latency_ns) write_value "$kernel_params" "1000000" ;;
            sched_min_granularity_ns) write_value "$kernel_params" "200000" ;;
            sched_wakeup_granularity_ns) write_value "$kernel_params" "750000" ;;
            sched_nr_migrate) write_value "$kernel_params" "2" ;;
            perf_cpu_time_max_percent) write_value "$kernel_params" "5" ;;
            sched_autogroup_enabled) write_value "$kernel_params" "1" ;;
            sched_child_runs_first) write_value "$kernel_params" "1" ;;
            sched_cstate_aware) write_value "$kernel_params" "1" ;;
            sched_energy_aware) write_value "$kernel_params" "0" ;;
            sched_rr_timeslice_ms) write_value "$kernel_params" "10" ;;
            sched_rt_period_us) write_value "$kernel_params" "1000000" ;;
            sched_rt_runtime_us) write_value "$kernel_params" "950000" ;;
            sched_sync_hint_enable) write_value "$kernel_params" "1" ;;
            sched_tunable_scaling) write_value "$kernel_params" "1" ;;
        esac
    done
}

optimize_cpu() {
# CPU Governor settings for big cores (cpu4-7) (thx to @Bias_khaliq)
    for cpu in /sys/devices/system/cpu/cpu[4-7]; do
        min_freq=$(cat $cpu/cpufreq/cpuinfo_min_freq)
        max_freq=$(cat $cpu/cpufreq/cpuinfo_max_freq)
        mid_freq=$(calculate_mid_freq $cpu)
  
           write_value "$cpu/cpufreq/schedutil/hispeed_load" "75"
           write_value "$cpu/cpufreq/schedutil/iowait_boost_enable" "0"
           write_value "$cpu/cpufreq/schedutil/up_rate_limit_us" "300"
           write_value "$cpu/cpufreq/schedutil/down_rate_limit_us" "2500"
           write_value "$cpu/cpufreq/scaling_min_freq" "$mid_freq"
           write_value "$cpu/cpufreq/scaling_max_freq" "$max_freq"
    done

# CPU Governor settings for LITTLE cores (cpu0-3) (thx to @Bias_khaliq)
    for cpu in /sys/devices/system/cpu/cpu[0-3]; do
        min_freq=$(cat $cpu/cpufreq/cpuinfo_min_freq)
        max_freq=$(cat $cpu/cpufreq/cpuinfo_max_freq)
        mid_freq=$(calculate_mid_freq $cpu)
  
            write_value "$cpu/cpufreq/schedutil/hispeed_load" "75"
            write_value "$cpu/cpufreq/schedutil/iowait_boost_enable" "0"
            write_value "$cpu/cpufreq/schedutil/up_rate_limit_us" "300"
            write_value "$cpu/cpufreq/schedutil/down_rate_limit_us" "2500"
            write_value "$cpu/cpufreq/scaling_min_freq" "$mid_freq"
            write_value "$cpu/cpufreq/scaling_max_freq" "$max_freq"
    done
}

optimze_cpu_boost() {
# (thx to pedrozzz0 @ GitHub for source cpu_boost)
    if [ -d "/sys/module/cpu_boost" ]; then
        for cpu_boost in /sys/module/cpu_boost/parameters/*; do
            case "$(basename "$cpu_boost")" in
                dynamic_stune_boost_ms) write_value "$cpu_boost" "500" ;;
                powerkey_input_boost_ms) write_value "$cpu_boost" "400" ;;
                input_boost_ms) write_value "$cpu_boost" "88" ;;
                dynamic_stune_boost) write_value "$cpu_boost" "20" ;;
                input_boost_enabled) write_value "$cpu_boost" "1" ;;
                sched_boost_on_powerkey_input) write_value "$cpu_boost" "1" ;;
                sched_boost_on_input) write_value "$cpu_boost" "0" ;;
            esac
        done
        sleep 0.0
    else
        log "Cpu_Boost directory not found, skipping optimization."
    fi
}

optimize_gpu() {
# (thx to Rᴀʏʜᴀɴ⁷⁷ for source mtkmod nusantara)
    if [ -d "/sys/class/kgsl/kgsl-3d0" ]; then
        for gpuset in /sys/class/kgsl/kgsl-3d0/*; do
            case "$(basename "$gpuset")" in
                pmqos_active_latency) write_value "$gpuset" "1000" ;;
                idle_timer) write_value "$gpuset" "80" ;;
                adreno_idler_active) write_value "$gpuset" "N" ;;
                force_no_nap) write_value "$gpuset" "1" ;;
                max_pwrlevel) write_value "$gpuset" "0" ;;
                adrenoboost) write_value "$gpuset" "0" ;;
                throttling) write_value "$gpuset" "0" ;;
                perfcounter) write_value "$gpuset" "0" ;;
                bus_split) write_value "$gpuset" "0" ;;
                thermal_pwrlevel) write_value "$gpuset" "0" ;;
                force_clk_on) write_value "$gpuset" "0" ;;
                force_bus_on) write_value "$gpuset" "0" ;;
                force_rail_on) write_value "$gpuset" "0" ;;
            esac
        done
        sleep 0.0
    else
        log "kgsl directory not found, skipping optimization."
    fi
}

optimize_memory() {
    for vm in /proc/sys/vm/*; do
        case "$(basename "$vm")" in
            dirty_writeback_centisecs) write_value "$vm" "1000" ;;
            dirty_expire_centisecs) write_value "$vm" "500" ;;
            vfs_cache_pressure) write_value "$vm" "50" ;;
            overcommit_ratio) write_value "$vm" "50" ;;
            swappiness) write_value "$vm" "60" ;;
            dirty_ratio) write_value "$vm" "15" ;;
            dirty_background_ratio) write_value "$vm" "5" ;;
            overcommit_memory) write_value "$vm" "0" ;;
            watermark_boost_factor) write_value "$vm" "0" ;;
        esac
    done
}

optimize_io_scheduler() {
    for queue in /sys/block/*/queue; do
        write_value "$queue/read_ahead_kb" "128"
        write_value "$queue/quantum" "64"
        write_value "$queue/nomerges" "2"
        write_value "$queue/rq_affinity" "2"
        write_value "$queue/slice_idle" "1"
        write_value "$queue/group_idle" "0"
        write_value "$queue/add_random" "0"
        write_value "$queue/rotational" "0"
    done
}

disable_debugging_features() {
# (source KTSR modified by @Kzyoo)
    for property in 'gpu_debug_enable' 'gPVRDebugLevel' 'oom_kill_allocating_task' 'oom_dump_tasks' 'block_dump' 'iostats' 'audit' 'sched_schedstats' 'ftrace_enabled' 'debug_pagealloc' 'kptr_restrict' 'debug_kprobes' 'debug_exception_trace' 'sysrq' 'debug_mask' 'log_level*' 'debug_level*' '*debug_mode' 'edac_mc_log*' 'enable_event_log' '*log_level*' '*log_ue*' '*log_ce*' 'log_ecn_error' 'snapshot_crashdumper' 'seclog*' 'compat-log' '*log_enabled' 'tracing_on' 'mballoc_debug'; do
        find /sys/ /proc/ \
            -path '/proc/[0-9]*' -prune -o \
            -type f -name "$property" -print 2>/dev/null | while read -r debugging; do
            write_value "$debugging" "0"
        done
    done
}

optimize_gpu_powervr() {
    if [ -d "/sys/module/pvrsrvkm/parameters" ]; then
      write_value "/sys/module/pvrsrvkm/parameters/EmuMaxFreq" "2"
      write_value "/sys/module/pvrsrvkm/parameters/EnableFWContextSwitch" "1"
      write_value "/sys/module/pvrsrvkm/parameters/gpu_power" "1"
      write_value "/sys/module/pvrsrvkm/parameters/DisableClockGating" "0"
    fi
}

disable_kernel_panic() {
    write_value "/sys/module/kernel/parameters/panic" "0"
    write_value "/sys/module/kernel/parameters/panic_on_warn" "0"
    write_value "/sys/module/kernel/parameters/panic_on_oops" "0"
    write_value "/sys/vm/panic_on_oom" "0"
    write_value "/proc/sys/kernel/panic" "0"
    write_value "/proc/sys/kernel/panic_on_rcu_stall" "0"
    sysctl -w kernel.panic=0
    sysctl -w vm.panic_on_oom=0
    sysctl -w kernel.panic_on_oops=0
    sysctl -w kernel.softlockup_panic=0
}

disable_printk() {
# (thx to KNTD-reborn for kernel panic)
    write_value "/proc/sys/kernel/printk" "0 0 0 0"
    write_value "/proc/sys/kernel/printk_devkmsg" "off"
    write_value "/sys/module/printk/parameters/ignore_loglevel" "1"
    write_value "/sys/module/printk/parameters/console_suspend" "1"
    write_value "/sys/module/printk/parameters/cpu" "0"
    write_value "/sys/kernel/printk_mode/printk_mode" "0"
    write_value "/sys/module/printk/parameters/pid" "0"
    write_value "/sys/module/printk/parameters/time" "0"
    write_value "/sys/module/printk/parameters/printk_ratelimit" "0"
}

optimize_kernel_entropy() {
    write_value "/proc/sys/kernel/random/write_wakeup_threshold" "1792"
    write_value "/proc/sys/kernel/random/read_wakeup_threshold" "192"
}

# ----------------- FINALIZATION -----------------
final_optimization() {
     cmd device_config put activity_manager max_phantom_processes 2147483647
     cmd device_config put activity_manager max_cached_processes 256
     cmd device_config put activity_manager max_empty_time_millis 43200000
     settings put global activity_manager_constants max_cached_processes=64
  
# Add GMS to battery optimization
     dumpsys deviceidle whitelist -com.google.android.gms

# // enable power saver adaptive
     cmd power set-adaptive-power-saver-enabled true

# // Perf set-fixed
     cmd power set-fixed-performance-mode-enabled true
   
# // Disable hardware overlays
     service call SurfaceFlinger 1008 i32 1
   
# // Google Service Config Reduce Drain
     su -c 'pm enable com.google.android.gms'
     su -c 'pm enable com.google.android.gsf'
     su -c 'pm enable com.google.android.gms/.update.SystemUpdateActivity'
     su -c 'pm enable com.google.android.gms/.update.SystemUpdateService'
     su -c 'pm enable com.google.android.gms/.update.SystemUpdateServiceActiveReceiver'
     su -c 'pm enable com.google.android.gms/.update.SystemUpdateServiceReceiver'
     su -c 'pm enable com.google.android.gms/.update.SystemUpdateServiceSecretCodeReceiver'
     su -c 'pm enable com.google.android.gsf/.update.SystemUpdateActivity'
     su -c 'pm enable com.google.android.gsf/.update.SystemUpdatePanoActivity'
     su -c 'pm enable com.google.android.gsf/.update.SystemUpdateService'
     su -c 'pm enable com.google.android.gsf/.update.SystemUpdateServiceReceiver'
     su -c 'pm enable com.google.android.gsf/.update.SystemUpdateServiceSecretCodeReceiver'

# // Google Analityc
    googleanalytics='com.google.android.gms.analytics.AnalyticsJobService '\
    'com.google.android.gms.analytics.CampaignTrackingService '\
    'com.google.android.gms.measurement.AppMeasurementService '\
    'com.google.android.gms.measurement.AppMeasurementJobService '\
    'com.google.android.gms.analytics.AnalyticsReceiver '\
    'com.google.android.gms.analytics.CampaignTrackingReceiver '\
    'com.google.android.gms.measurement.AppMeasurementInstallReferrerReceiver '\
    'com.google.android.gms.measurement.AppMeasurementReceiver '\
    'com.google.android.gms.measurement.AppMeasurementContentProvider '\
    'com.crashlytics.android.CrashlyticsInitProvider '\
    'com.google.android.gms.ads.AdActivity '\
    'com.google.firebase.iid.FirebaseInstanceIdService'

    for apk in $(pm list packages -3 | sed 's/package://g' | sort); do	
        for i in $googleanalytics; do 
           pm disable "$apk/$i" &> /dev/null
        done		
    done
   
# clear stune & uclamp
    for stune in /dev/stune/*/; do
       write_value "$stune/schedtune.boost" "0"
       write_value "$stune/schedtune.prefer_idle" "0"
    done
    for cpuctl in /dev/cpuctl/*/; do
       write_value "$cpuctl/cpu.uclamp.min" "0"
       write_value "$cpuctl/cpu.uclamp.latency_sensitive" "0"
    done
  
# // Better Battery Efficient
    for parameters in /sys/module/workqueue/parameters; do
       if [ -d "/sys/module/workqueue/parameters" ]; then
          chmod 664 "$parameters/power_efficient"
          write_value "$parameters/power_efficient" "Y"
       fi
    done
  
# file system tweak (thx to AkiraSuper)
  if [ -d "/proc/sys/fs" ]; then 
    write_value "/proc/sys/fs/dir-notify-enable" "0"
    write_value "/proc/sys/fs/lease-break-time" "25"
    write_value "/proc/sys/fs/aio-max-nr" "131072"
  fi
    
# Power Saving
  if [ -d "/sys/power" ]; then
    write_value "/sys/power/autosleep" "mem"
    write_value "/sys/power/mem_sleep" "deep"
  fi
    
# Disable Fsync
  if [ -d "/sys/module/sync/parameters" ]; then
    write_value "/sys/module/sync/parameters/fsync_enabled" "N"
  fi
   
# Change kernel mode to HMP Mode
  if [ -d "/sys/devices/system/cpu/eas" ]; then
    write_value "/sys/devices/system/cpu/eas/enable" "0"
  fi
	
# // additional settings in kernel
  if [ -d "/sys/kernel/ged/hal" ]; then
    write_value "/sys/kernel/ged/hal/gpu_boost_level" "2"
  fi
  
# Touch Boost
    write_value "/sys/module/msm_performance/parameters/touchboost" "0"
    write_value "/sys/power/pnpmgr/touch_boost" "0"

# // Release cache on boot (try cleaning)
    write_value "/proc/sys/vm/drop_caches" "3"
    write_value "/proc/sys/vm/compact_memory" "1"
}

# ----------------- MAIN EXECUTION -----------------
main() {
    wait_until_boot_completed
    optimize_dropbox
    optimize_priority
    optimize_ged
    optimize_power_policy_manager
    optimize_connection
    optimize_gpu_freq
    optimize_kernel
    optimize_cpu
    optimze_cpu_boost
    optimize_gpu
    optimize_memory
    optimize_io_scheduler
    disable_debugging_features
    optimize_gpu_powervr
    disable_kernel_panic
    disable_printk
    optimize_kernel_entropy
    final_optimization
}

# Main Execution & Exit script successfully
sync && main && send_notification && exit 0
  
# This script will be executed in late_start service mode
