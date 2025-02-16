#!/system/bin/sh
# Do NOT assume where your module will be located.
# ALWAYS use $MODDIR if you need to know where this script
# and module is placed.
# This will make sure your module will still work
# if Magisk change its mount point in the future
# Kzuyoo | Kazuyoo-stuff

# ----------------- GLOBAL VARIABLES -----------------
MODDIR=${0%/*}
SCHED_PERIOD="$((3 * 1000 * 1000))"
SCHED_TASKS="8"

# ----------------- HELPER FUNCTIONS -----------------
log() {
    echo "$1"
}

wait_until_boot_completed() {
    while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 3; done
    while [ ! -d "/sdcard/Android" ]; do sleep 1; done
}

write_val() {
    local file="$1"
    local value="$2"
    if [ -e "$file" ]; then
        chmod +w "$file" 2>/dev/null
        echo "$value" > "$file" && log "Write : $file → $value" || log "Failed to Write : $file"
    fi
}

mask_val() {
    touch /data/local/tmp/mount_mask
    for p in $2; do
        if [ -f "$p" ]; then
            umount "$p"
            chmod 0666 "$p"
            echo "$1" >"$p"
            mount --bind /data/local/tmp/mount_mask "$p"
        fi
    done
}

calculate_mid_freq() {
    local cpu_path="$1"
    local min_freq=$(cat "$cpu_path/cpufreq/cpuinfo_min_freq")
    local max_freq=$(cat "$cpu_path/cpufreq/cpuinfo_max_freq")
    echo $(( (min_freq * 3 + max_freq) / 4 ))
}

send_notification() {
    sleep 5
    su -lp 2000 -c "cmd notification post -S bigtext -t 'Celestial-Tweaks🍃' tag 'Status : Optimization Completed!'" >/dev/null 2>&1
}
wait_until_boot_completed
# ----------------- OPTIMIZATION SECTIONS -----------------
optimize_ged() {
    if [ -d "/sys/module/ged/parameters" ]; then
       for parameter in /sys/module/ged/parameters/*; do
          case "$(basename "$parameter")" in
            gpu_bottom_freq) write_val "$parameter" "900000" ;;
            ged_smart_boost) write_val "$parameter" "2000" ;;
            gx_game_mode) write_val "$parameter" "2" ;;
            boost_amp) write_val "$parameter" "2" ;;
            boost_extra) write_val "$parameter" "2" ;;
            ged_boost_enable) write_val "$parameter" "1" ;;
            boost_gpu_enable) write_val "$parameter" "1" ;;
            enable_gpu_boost) write_val "$parameter" "1" ;;
            ged_dvfs_enable) write_val "$parameter" "0" ;;
            gx_3D_benchmark_on) write_val "$parameter" "1" ;;
            gpu_idle) write_val "$parameter" "0" ;;
            gpu_debug_enable) write_val "$parameter" "0" ;;
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
                enabled) write_val "$parameter" "1" ;;
                policy_status)
                    write_val "$parameter" "0 1"
                    write_val "$parameter" "1 1"
                    write_val "$parameter" "5 1"
                    write_val "$parameter" "6 1"
                    write_val "$parameter" "7 1"
                    write_val "$parameter" "8 1"
                    write_val "$parameter" "9 1"
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
            tcp_wmem) write_val "$parameter" "4096 524288 16777216" ;;
            tcp_rmem) write_val "$parameter" "4096 1048576 16777216" ;;
            netdev_max_backlog) write_val "$parameter" "25000" ;;
            somaxconn) write_val "$parameter" "4096" ;;
            tcp_keepalive_time) write_val "$parameter" "30" ;;
            tcp_fin_timeout) write_val "$parameter" "10" ;;
            tcp_tw_reuse) write_val "$parameter" "1" ;;
            tcp_mtu_probing) write_val "$parameter" "2" ;;
            tcp_tw_recycle) write_val "$parameter" "0" ;;
        esac
    done
}

optimize_kernel() {
    for kernel_params in /proc/sys/kernel/*; do
        case "$(basename "$kernel_params")" in
            sched_boost) write_val "$kernel_params" "1000000" ;;
            sched_min_granularity_ns) write_val "$kernel_params" "$((SCHED_PERIOD / (SCHED_TASKS * 2)))" ;;
            sched_wakeup_granularity_ns) write_val "$kernel_params" "$((SCHED_PERIOD / 3))" ;;
            sched_latency_ns) write_val "$kernel_params" "$SCHED_PERIOD" ;;
            sched_migration_cost_ns) write_val "$kernel_params" "300000" ;;
            sched_rt_period_us) write_val "$kernel_params" "1000000" ;;
            perf_cpu_time_max_percent) write_val "$kernel_params" "10" ;;
        esac
    done
}

optimize_cpu() {
# CPU Governor settings (cpu0-7) (thx to @Bias_khaliq) modified by Kzuyoo
    for cpu in /sys/devices/system/cpu/cpu[0-7]; do
        [ -f "$cpu/cpufreq/cpuinfo_min_freq" ] || continue

        min_freq=$(< "$cpu/cpufreq/cpuinfo_min_freq")
        max_freq=$(< "$cpu/cpufreq/cpuinfo_max_freq")
        mid_freq=$(( (min_freq * 3 + max_freq) / 4 ))

          write_val "$cpu/cpufreq/scaling_min_freq" "$min_freq"
          write_val "$cpu/cpufreq/scaling_max_freq" "$max_freq"
    done

    for cpu in /sys/devices/system/cpu/cpufreq/policy*; do
        [ -f "$cpu/cpuinfo_min_freq" ] || continue

        min_freq=$(< "$cpu/cpuinfo_min_freq")
        max_freq=$(< "$cpu/cpuinfo_max_freq")
        mid_freq=$(( (min_freq * 3 + max_freq) / 4 ))

          write_val "$cpu/scaling_min_freq" "$min_freq"
          write_val "$cpu/scaling_max_freq" "$max_freq"
    done
   
 # Optimize cpufreq (thx to Rᴀʏʜᴀɴ⁷⁷ for source mtkmod nusantara)
   for cpufreq in /proc/cpufreq; do
      write_val "$cpufreq/cpufreq_power_mode" "3"
      write_val "$cpufreq/cpufreq_cci_mode" "1"
      write_val "$cpufreq/cpufreq_imax_enable" "1"
      write_val "$cpufreq/cpufreq_sched_disable" "1"
      write_val "$cpufreq/cpufreq_imax_thermal_protect" "0"
   done
   
   if [ -d "/proc/sys/walt/" ]; then
     # disable WALT CPU Boost
     mask_val "0" /proc/sys/walt/sched_boost
     mask_val "0" /proc/sys/walt/input_boost/*
     # WALT Adjustment
     mask_val "5 70" "/proc/sys/walt/sched_downmigrate"
     mask_val "15 90" "/proc/sys/walt/sched_upmigrate"
   fi
}

optimize_gpu() {
# (thx to Rᴀʏʜᴀɴ⁷⁷ for source mtkmod nusantara)
    if [ -d "/sys/class/kgsl/kgsl-3d0" ]; then
        for gpuset in /sys/class/kgsl/kgsl-3d0/*; do
            case "$(basename "$gpuset")" in
                adreno_idler_active) write_val "$gpuset" "N" ;;
                force_no_nap) write_val "$gpuset" "1" ;;
                max_pwrlevel) write_val "$gpuset" "0" ;;
                throttling) write_val "$gpuset" "0" ;;
                perfcounter) write_val "$gpuset" "0" ;;
                bus_split) write_val "$gpuset" "0" ;;
                thermal_pwrlevel) write_val "$gpuset" "0" ;;
            esac
        done
        sleep 0.0
    else
        log "kgsl directory not found, skipping optimization."
    fi
    
    if [ -d "/proc/gpufreq" ]; then
        for gpufreq in /proc/gpufreq; do
            case "$(basename "$gpufreq")" in
                gpufreq_opp_freq) write_val "$gpufreq/gpufreq_opp_freq" "0" ;;
                gpufreq_opp_stress_test) write_val "$gpufreq/gpufreq_opp_stress_test" "0" ;;
                gpufreq_power_dump) write_val "$gpufreq/gpufreq_power_dump" "0" ;;
                gpufreq_power_limited) write_val "$gpufreq/gpufreq_power_limited" "0" ;;
            esac
        done
        sleep 0.0
    else
        log "GpuFreq directory not found, skipping optimization."
    fi
    
# Additional kernel-ged GPU optimizations
    if [ -d "/sys/kernel/debug/ged/hal/" ]; then
         write_val "/sys/kernel/debug/ged/hal/gpu_boost_level" "2"
    fi
    
# optimize gpu power vr
    if [ -d "/sys/module/pvrsrvkm/parameters" ]; then
      write_val "/sys/module/pvrsrvkm/parameters/gpu_power" "1"
    fi
}

optimize_virtual_memory() {
    for vm in /proc/sys/vm/*; do
        case "$(basename "$vm")" in
            dirty_writeback_centisecs) write_val "$vm" "100" ;;
            dirty_expire_centisecs) write_val "$vm" "200" ;;
            swappiness) write_val "$vm" "80" ;;
            vfs_cache_pressure) write_val "$vm" "50" ;;
            overcommit_ratio) write_val "$vm" "25" ;;
            dirty_ratio) write_val "$vm" "20" ;;
            dirty_background_ratio) write_val "$vm" "5" ;;
            overcommit_memory) write_val "$vm" "1" ;;
            watermark_boost_factor) write_val "$vm" "0" ;;
        esac
    done
}

optimize_io_scheduler() {
    for queue in /sys/block/*/queue; do
        write_val "$queue/read_ahead_kb" "128"
        write_val "$queue/quantum" "64"
        write_val "$queue/rq_affinity" "2"
        write_val "$queue/nomerges" "0"
        write_val "$queue/slice_idle" "0"
        write_val "$queue/group_idle" "0"
        write_val "$queue/add_random" "0"
        write_val "$queue/rotational" "0"
    done
}

optimize_miui() {
    # thx to Minhhai from source MIUI EXTENDED
    miui=false
    [[ "$(getprop ro.miui.ui.version.name)" ]] && miui=true

    nr_cores=$(awk -F "-" '{print $2+1}' /sys/devices/system/cpu/possible)
    [[ -z "$nr_cores" || "$nr_cores" -eq "0" ]] && nr_cores=1

    if [[ "$miui" == "true" ]]; then
        case "$nr_cores" in
            8)
                resetprop -n persist.sys.miui.sf_cores "4-7"
                resetprop -n persist.sys.miui_animator_sched.bigcores "4-7"
                resetprop -n persist.sys.miui_animator_sched.sched_threads "2"
                ;;
            6)
                resetprop -n persist.sys.miui.sf_cores "0-5"
                resetprop -n persist.sys.miui_animator_sched.bigcores "2-5"
                ;;
            4)
                resetprop -n persist.sys.miui.sf_cores "0-3"
                resetprop -n persist.sys.miui_animator_sched.bigcores "0-3"
                ;;
            *)
                echo "There is no suitable configuration for the number of cores: $nr_cores"
                ;;
        esac
    
    # disable miui migt
    if [ -d "/sys/module/migt/" ]; then
        settings put secure speed_mode_enable 1
        stop mimd-service
        mask_val "0" /proc/sys/migt/enable_pkg_monitor
        chmod 000 /sys/module/migt/parameters/*
        chmod 000 /sys/module/migt
        chmod 000 /sys/module/sched_walt/holders/migt/parameters
    fi

  # Enables ZRAM 1:1 if device is Hyper OS 2.0
    if [ "$(getprop ro.mi.os.version.name)" = "OS2.0" ]; then
        resetprop -n persist.miui.extm.dm_opt.enable true
    fi

  # Enables FBO service if HAL and props found, only for UFS
    if [ -d "/sys/block/sda" ] && [ "$(getprop init.svc.vendor.fbo-hal-1-0)" ] && [ "$(getprop persist.sys.stability.miui_fbo_enable)" = "true" ]; then
        resetprop -n persist.sys.stability.fbo_hal_stop false
        resetprop -n persist.sys.fboservice.ctrl true
        resetprop -n persist.sys.stability.miui_fbo_start_count 1
    fi

   pid=$(pgrep -f com.android.commands.input.Input)
   [[ -n "$pid" ]] && chrt -f -p 99 "$pid" && ionice -c 1 -n 3 "$pid" && nice -n 0 "$pid"
   pid=$(pgrep -f com.miui.home)
   [[ -n "$pid" ]] && chrt -f -p 99 "$pid" && ionice -c 1 -n 3 "$pid" && nice -n 0 "$pid"
      else
        echo "Device is not MIUI."
    fi
}


# ----------------- FINALIZATION -----------------
final_optimization() {
    # Off Ramdumps
    if [ -d "/sys/module/subsystem_restart/" ]; then
       write_val "/sys/module/subsystem_restart/parameters/enable_ramdumps" "0"
       write_val "/sys/module/subsystem_restart/parameters/enable_mini_ramdumps" "0"
    fi
  
    # file system tweak (thx to Matt Yang)
    if [ -d "/proc/sys/fs" ]; then 
       write_val "/proc/sys/fs/inotify/max_queued_events" "1048576"
       write_val "/proc/sys/fs/inotify/max_user_watches" "1048576"
       write_val "/proc/sys/fs/inotify/max_user_instances" "1024"
       write_val "/proc/sys/fs/dir-notify-enable" "0"
       write_val "/proc/sys/fs/lease-break-time" "20"
       write_val "/proc/sys/kernel/hung_task_timeout_secs" "0"
    fi
    
    # Disable Fsync
    if [ -d "/sys/module/sync/parameters" ]; then
       write_val "/sys/module/sync/parameters/fsync_enabled" "N"
    fi
  
    # Qualcomm enter C-state level 3 took ~500us
    if [ -d "/sys/module/lpm_levels/" ]; then
       write_val "/sys/module/lpm_levels/parameters/lpm_ipi_prediction" "0"
       write_val "/sys/module/lpm_levels/parameters/lpm_prediction" "0"
       write_val "/sys/module/lpm_levels/parameters/bias_hyst" "2"
    fi
    
    # Touch Boost
    write_val "/sys/module/msm_performance/parameters/touchboost" "1"
    write_val "/sys/power/pnpmgr/touch_boost" "1"
    
    # Cpu Efficient
    write_val "/sys/module/workqueue/parameters/power_efficient" "Y"
    
    # enable power saver adaptive
    cmd power set-adaptive-power-saver-enabled true

    # Perf set-fixed
    cmd power set-fixed-performance-mode-enabled true

    # Release cache on boot (try cleaning)
    write_val "/proc/sys/vm/drop_caches" "3"
    write_val "/proc/sys/vm/compact_memory" "1"
}

# ----------------- MAIN EXECUTION -----------------
main() {
    optimize_ged
    optimize_power_policy_manager
    optimize_connection
    optimize_kernel
    optimize_cpu
    optimize_gpu
    optimize_virtual_memory
    optimize_io_scheduler
    optimize_miui
    final_optimization
    set start vsync 
}

# Main Execution & Exit script successfully
sync && main && send_notification && DisLog && exit 0
  
# This script will be executed in late_start service mode