#!/system/bin/sh
#Original author: Alcolawl
#!/system/bin/sh
#Original script By: RogerF81 + adanteon
#Settings By: RogerF81
#Device: OnePlus 5
#Codename: SoilWork UNIFIED
#SoC: Snapdragon 835
#Last Updated: 16/01/2018
#Credits: @Alcolawl @soniCron @Asiier @Freak07 @Mostafa Wael @Senthil360 @TotallyAnxious @RenderBroken @ZeroInfinity @Kyuubi10 @ivicask @RogerF81 @joshuous @boyd95 @ZeroKool76 @adanteon

codename=Soilwork
stype=battery
version=V3.0
cdate=$(date)
DLL=/storage/emulated/0/soilwork_battery_log.txt

#Initializing log
echo "$cdate" > $DLL
echo "$codename $stype" >> $DLL
echo "*Searching CPU frequencies" >> $DLL

#Disable BCL
if [ -e "/sys/devices/soc/soc:qcom,bcl/mode" ]; then
	echo "*Disabling BCL" >> $DLL
	chmod 644 /sys/devices/soc/soc:qcom,bcl/mode
	echo -n disable > /sys/devices/soc/soc:qcom,bcl/mode
fi

#Stopping perfd
if [ -e "/data/system/perfd" ]; then
	echo "*Stopping perfd" >> $DLL
	stop perfd
fi

#Turn off core_control
echo "	+Disabling core_control temporarily" >> $DLL
echo 0 > /sys/module/msm_thermal/core_control/enabled

##Configuring stune & cpuset
if [ -d "/dev/stune" ]; then
	echo "Configuring stune" >> $DLL
	echo 1 > /dev/stune/top-app/schedtune.boost
	echo 0 > /dev/stune/background/schedtune.boost
	echo 0 > /dev/stune/foreground/schedtune.boost
	echo 0 > /dev/stune/schedtune.prefer_idle
	echo 0 > /proc/sys/kernel/sched_child_runs_first
	#echo 0 > /proc/sys/kernel/sched_cfs_boost
	echo 0 > /dev/stune/background/schedtune.prefer_idle
	echo 0 > /dev/stune/foreground/schedtune.prefer_idle
	echo 1 > /dev/stune/top-app/schedtune.prefer_idle
	if [ -e "/proc/sys/kernel/sched_autogroup_enabled" ]; then
		echo 0 > /proc/sys/kernel/sched_autogroup_enabled
	fi
	if [ -e "/proc/sys/kernel/sched_is_big_little" ]; then
		echo 1 > /proc/sys/kernel/sched_is_big_little
	fi
	if [ -e "/proc/sys/kernel/sched_boost" ]; then
		echo 0 > /proc/sys/kernel/sched_boost
	fi
fi
echo 32 > /proc/sys/kernel/sched_nr_migrate

if [ -d "/dev/cpuset" ]; then
	echo "Configuring cpuset" >> $DLL
	echo 0 > /dev/cpuset/background/cpus
	echo 1 > /dev/cpuset/system-background/cpus
fi

sleep 1

big_max_value=0
little_max_value=0
big_min_value=0
little_min_value=0

little_max_value=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq);
big_max_value=$(cat /sys/devices/system/cpu/cpu4/cpufreq/cpuinfo_max_freq);
little_min_value=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq);
big_min_value=$(cat /sys/devices/system/cpu/cpu4/cpufreq/cpuinfo_min_freq);

#Turn on all cores
echo "*Turning on cores" >> $DLL
chmod 644 /sys/devices/system/cpu/online
echo 0-7 > /sys/devices/system/cpu/online
chmod 444 /sys/devices/system/cpu/online
echo 1 > /sys/devices/system/cpu/cpu0/online
echo 1 > /sys/devices/system/cpu/cpu1/online
echo 1 > /sys/devices/system/cpu/cpu2/online
echo 1 > /sys/devices/system/cpu/cpu3/online
echo 1 > /sys/devices/system/cpu/cpu4/online
echo 1 > /sys/devices/system/cpu/cpu5/online
echo 1 > /sys/devices/system/cpu/cpu6/online
echo 1 > /sys/devices/system/cpu/cpu7/online

#Apply settings to LITTLE cluster
echo "*Applying LITTLE settings" >> $DLL
echo "	+Searching available governors" >> $DLL

if [ -d /sys/devices/system/cpu/cpufreq/policy0 ]; then
	if [ -e /sys/devices/system/cpu/cpufreq/policy0 ]; then
		LGP=/sys/devices/system/cpu/cpufreq/policy0
	fi

	AGL=/sys/devices/system/cpu/cpufreq/policy0/scaling_available_governors;

	if grep 'pwrutilx' $AGL; then
		if [ -e $AGL ]; then
			echo "	+Applying & tuning pwrutilx" >> $DLL
			chmod 644 /sys/devices/system/cpu/cpu0/cpufreq/pwrutilx/*
			chmod 644 $LGP/pwrutilx/*
			echo pwrutilx > $LGP/scaling_governor
			sleep 1
			echo 2000 > $LGP/pwrutilx/up_rate_limit_us
			echo 6000 > $LGP/pwrutilx/down_rate_limit_us
			echo 7 > /sys/module/cpu_boost/parameters/dynamic_stune_boost
			echo 1 > $LGP/pwrutilx/iowait_boost_enable
			echo 1 > /proc/sys/kernel/sched_cstate_aware
			echo 0 > /proc/sys/kernel/sched_initial_task_util
			if [ -e "/proc/sys/kernel/sched_use_walt_task_util" ]; then
				echo 1 > /proc/sys/kernel/sched_use_walt_task_util
				echo 1 > /proc/sys/kernel/sched_use_walt_cpu_util
				echo 0 > /proc/sys/kernel/sched_walt_init_task_load_pct
				echo 10000000 > /proc/sys/kernel/sched_walt_cpu_high_irqload
			fi
			chmod 444 /sys/devices/system/cpu/cpu0/cpufreq/pwrutilx/*
			chmod 444 $LGP/pwrutilx/*
		fi
		echo "	+Tuning finished for pwrutilx" >> $DLL
	
	elif grep 'schedutil' $AGL; then
		if [ -e $AGL ]; then
			echo "	+Applying & tuning schedutil" >> $DLL
			chmod 644 /sys/devices/system/cpu/cpu0/cpufreq/schedutil/*
			chmod 644 $LGP/schedutil/*
			echo schedutil > $LGP/scaling_governor
			sleep 1
			echo 2000 > $LGP/schedutil/up_rate_limit_us
			echo 5000 > $LGP/schedutil/down_rate_limit_us
			if [ -e "$LGP/schedutil/iowait_boost_enable" ]; then
				echo 0 > $LGP/schedutil/iowait_boost_enable
			fi
			echo 5 > /sys/module/cpu_boost/parameters/dynamic_stune_boost
			echo 1 > /proc/sys/kernel/sched_cstate_aware
			echo 0 > /proc/sys/kernel/sched_initial_task_util
			if [ -e "/proc/sys/kernel/sched_use_walt_task_util" ]; then
				echo 1 > /proc/sys/kernel/sched_use_walt_task_util
				echo 1 > /proc/sys/kernel/sched_use_walt_cpu_util
				echo 0 > /proc/sys/kernel/sched_walt_init_task_load_pct
				echo 10000000 > /proc/sys/kernel/sched_walt_cpu_high_irqload
			fi
			chmod 444 /sys/devices/system/cpu/cpu0/cpufreq/schedutil/*
			chmod 444 $LGP/schedutil/*
		fi
		echo "	+Tuning finished for schedutil" >> $DLL
	
	elif grep 'interactive' $AGL; then
		if [ -e $AGL ]; then
			echo 95 > /proc/sys/kernel/sched_upmigrate
			echo 100 > /proc/sys/kernel/sched_group_upmigrate
			echo 85 > /proc/sys/kernel/sched_downmigrate
			echo 95 > /proc/sys/kernel/sched_group_downmigrate
			echo 5 > /proc/sys/kernel/sched_small_wakee_task_load
			echo 5 > /proc/sys/kernel/sched_init_task_load
			echo 0 > /proc/sys/kernel/sched_init_task_util
			if [ -e /proc/sys/kernel/sched_enable_power_aware ]; then
				echo 1 > /proc/sys/kernel/sched_enable_power_aware
			fi
			echo 1 > /proc/sys/kernel/sched_enable_thread_grouping
			echo 35 > /proc/sys/kernel/sched_big_waker_task_load
			echo 3 > /proc/sys/kernel/sched_window_stats_policy
			echo 5 > /proc/sys/kernel/sched_ravg_hist_size
			if [ -e /proc/sys/kernel/sched_upmigrate_min_nice ]; then
				echo 0 > /proc/sys/kernel/sched_upmigrate_min_nice
			fi
			echo 5 > /proc/sys/kernel/sched_spill_nr_run
			echo 99 > /proc/sys/kernel/sched_spill_load
			echo 1 > /proc/sys/kernel/sched_enable_thread_grouping
			echo 1 > /proc/sys/kernel/sched_restrict_cluster_spill
			if [ -e /proc/sys/kernel/sched_wakeup_load_threshold ]; then
				echo 110 > /proc/sys/kernel/sched_wakeup_load_threshold
			fi
			echo 10 > /proc/sys/kernel/sched_rr_timeslice_ms
			if [ -e "/proc/sys/kernel/sched_enable_power_aware" ]; then
				echo 1 > /proc/sys/kernel/sched_enable_power_aware
			fi
			if [ -e "/proc/sys/kernel/sched_migration_fixup" ]; then
				echo 1 > /proc/sys/kernel/sched_migration_fixup
			fi
			if [ -e "/sys/devices/system/cpu/cpu0/cpufreq/interactive/screen_off_maxfreq" ]; then
				echo 518400 > $LGP/interactive/screen_off_maxfreq
			fi
			if [ -e "/sys/devices/system/cpu/cpu0/cpufreq/interactive/powersave_bias" ]; then
				echo 1 > $LGP/interactive/powersave_bias
			fi
			echo "	+Applying & tuning interactive" >> $DLL
			echo interactive > $LGP/scaling_governor
			sleep 1
			chmod 644 /sys/devices/system/cpu/cpu0/cpufreq/interactive/*
			chmod 644 $LGP/interactive/*
			echo 80 883200:83 1324800:90 1555200:95 > $LGP/interactive/target_loads
			chmod 444 /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
			echo 90000 > $LGP/interactive/timer_slack
			chmod 644 $LGP/interactive/timer_rate
			echo 60000 > $LGP/interactive/timer_rate
			echo 825600 > $LGP/interactive/hispeed_freq
			echo 15000 883200:50000 1401600:100000 > $LGP/interactive/above_hispeed_delay
			echo 400 > $LGP/interactive/go_hispeed_load
			echo 0 > $LGP/interactive/min_sample_time
			chmod 444 /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time
			chmod 444 $LGP/interactive/hispeed_freq
			echo 1 > $LGP/interactive/fast_ramp_down
			echo 0 > $LGP/interactive/use_sched_load
			chmod 444 /sys/devices/system/cpu/cpu0/cpufreq/interactive/*
			chmod 444 $LGP/interactive/*
			echo "	+Tuning finished for interactive" >> $DLL
		fi
	else
		echo "	-The governor's path is wrong or mod is incompatible" >> $DLL
		echo "	-Error Code #01" >> $DLL
	fi
fi

echo "	*LITTLE settings finished" >> $DLL

#Apply settings to big cluster
echo "*Applying big settings" >> $DLL
echo "	+Searching available governors" >> $DLL

if [ -d /sys/devices/system/cpu/cpufreq/policy4 ]; then
	if [ -e /sys/devices/system/cpu/cpufreq/policy4 ]; then
		BGP=/sys/devices/system/cpu/cpufreq/policy4
	fi

	AGB=/sys/devices/system/cpu/cpufreq/policy4/scaling_available_governors;

	if grep 'pwrutilx' $AGB; then
		if [ -e $AGB ]; then
			echo "	+Applying pwrutilx" >> $DLL
			chmod 644 /sys/devices/system/cpu/cpu4/cpufreq/pwrutilx/*
			chmod 644 $BGP/pwrutilx/*
			echo pwrutilx > $BGP/scaling_governor
			sleep 1
			echo 2000 > $BGP/pwrutilx/up_rate_limit_us
			echo 6000 > $BGP/pwrutilx/down_rate_limit_us
			echo 0 > $BGP/pwrutilx/iowait_boost_enable
			chmod 444 /sys/devices/system/cpu/cpu4/cpufreq/pwrutilx/*
			chmod 444 $BGP/pwrutilx/*
		fi
		echo "	+Tuning finished for pwrutilx" >> $DLL
	
	elif grep 'schedutil' $AGB; then
		if [ -e $AGB ]; then
			echo "	+Applying schedutil" >> $DLL
			chmod 644 /sys/devices/system/cpu/cpu4/cpufreq/schedutil/*
			chmod 644 $BGP/schedutil/*
			echo schedutil > $BGP/scaling_governor
			sleep 1
			echo 2000 > $BGP/schedutil/up_rate_limit_us
			echo 5000 > $BGP/schedutil/down_rate_limit_us
			if [ -e "$BGP/schedutil/iowait_boost_enable" ]; then
				echo 0 > $BGP/schedutil/iowait_boost_enable
			fi
			chmod 444 /sys/devices/system/cpu/cpu4/cpufreq/schedutil/*
			chmod 444 $BGP/schedutil/*
		fi
		echo "	+Tuning finished for schedutil" >> $DLL
		
	elif grep 'interactive' $AGB; then
		if [ -e $AGB ]; then
			echo "	Applying & tuning interactive" >> $DLL
			echo interactive > $BGP/scaling_governor
			sleep 1
			chmod 644 /sys/devices/system/cpu/cpu4/cpufreq/interactive/*
			chmod 644 $BGP/interactive/*
			echo 83 1132800:86 1881600:91 2265600:95 > $BGP/interactive/target_loads
			chmod 444 /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
			echo 120000 > $BGP/interactive/timer_slack
			echo 1056000 > $BGP/interactive/hispeed_freq
			chmod 644 $BGP/interactive/timer_rate
			echo 60000 > $BGP/interactive/timer_rate
			echo 25000 902400:50000 1132800:75000 2208000:100000 > $BGP/interactive/above_hispeed_delay
			echo 400 > $BGP/interactive/go_hispeed_load
			echo 0 > $BGP/interactive/min_sample_time
			echo 1 > $BGP/interactive/fast_ramp_down
			echo 0 > $BGP/interactive/use_sched_load
			chmod 444 /sys/devices/system/cpu/cpu4/cpufreq/interactive/*
			chmod 444 $BGP/interactive/*
			echo "	+Tuning finished for interactive" >> $DLL
		fi
	else
		echo "	-The governor's path is wrong or mod is incompatible" >> $DLL
		echo "	-Error Code #02" >> $DLL
	fi
fi

echo "	*big settings finished" >> $DLL

sleep 1

#Enable work queue to be power efficient
if [ -e /sys/module/workqueue/parameters/power_efficient ]; then
	echo "*Enabling power saving work queue" >> $DLL
	chmod 644 /sys/module/workqueue/parameters/power_efficient
	echo Y > /sys/module/workqueue/parameters/power_efficient
	chmod 444 /sys/module/workqueue/parameters/power_efficient
fi

# #Tweak VoxPopuli -- Only on EAS kernels
# if [ -d /dev/voxpopuli/ ]; then
	# echo "*Tweaking Vox Populi PowerHal" >> $DLL
	# VOX_P=/dev/voxpopuli/
	# echo 1 > $VOX_P/enable_interaction_boost	#Main switch
	# echo 0 > $VOX_P/fling_min_boost_duration
	# echo 2500 > $VOX_P/fling_max_boost_duration
	# echo 10 > $VOX_P/fling_boost_topapp
	# echo 940 > $VOX_P/fling_min_freq_big	
	# echo 960 > $VOX_P/fling_min_freq_little
	# echo 200 > $VOX_P/touch_boost_duration
	# echo 5 > $VOX_P/touch_boost_topapp
	# echo 806 > $VOX_P/touch_min_freq_big
	# echo 960 > $VOX_P/touch_min_freq_little
# fi

# #Tweak input boost -- Only Sultanized ROMs
# if [ -e "/sys/kernel/cpu_input_boost" ]; then
	# echo "*Tweaking input boost" >> $dll
	# chmod 644 /sys/kernel/cpu_input_boost/*
	# echo 1 > /sys/kernel/cpu_input_boost/enable
	# echo 66 > /sys/kernel/cpu_input_boost/ib_duration_ms
	# echo 537600 537600 > /sys/kernel/cpu_input_boost/ib_freqs
	# chmod 444 /sys/kernel/cpu_input_boost/*
# fi

# #Tweak cpu boost
if [ -e "/sys/module/cpu_boost" ]; then
	echo "*Tweaking CPU Boost" >> $DLL
	if [ -e "/sys/module/cpu_boost/parameters/input_boost_enabled" ]; then
		chmod 644 /sys/module/cpu_boost/parameters/input_boost_enabled
		echo 1 > /sys/module/cpu_boost/parameters/input_boost_enabled
	fi
	chmod 644 /sys/module/cpu_boost/parameters/input_boost_freq
	echo 0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0 > /sys/module/cpu_boost/parameters/input_boost_freq
	chmod 644 /sys/module/cpu_boost/parameters/input_boost_ms
	echo 230 > /sys/module/cpu_boost/parameters/input_boost_ms
	if [ -e "/sys/module/msm_performance/parameters/touchboost/sched_boost_on_input " ]; then
		echo N > /sys/module/msm_performance/parameters/touchboost/sched_boost_on_input
	fi
fi

sleep 1

#I/0 Tweaks
if [ -d "/sys/block/sda/queue" ]; then
	echo "*Applying I/O tweaks" >> $DLL
	Q_PATH=/sys/block/sda/queue/
	if grep 'maple' $Q_PATH/scheduler; then
		echo "maple" > $Q_PATH/scheduler
		sleep 1
		echo 16 > $Q_PATH/iosched/fifo_batch
		echo 4 > $Q_PATH/iosched/writes_starved
		echo 10 > $Q_PATH/iosched/sleep_latency_multiple
		#echo 200 > $Q_PATH/iosched/async_read_expire   ##default values
		#echo 500 > $Q_PATH/iosched/async_write_expire   ##default values
		#echo 100 > $Q_PATH/iosched/sync_read_expire   ##default values
		#echo 350 > $Q_PATH/iosched/sync_write_expire   ##default values
		#echo 5 * HZ > $Q_PATH/iosched/async_read_expire  ##if CONFIG_HZ=1000
		#echo 5 * HZ > $Q_PATH/iosched/async_write_expire  ##if CONFIG_HZ=1000
		#echo HZ / 2 > $Q_PATH/iosched/sync_read_expire  ##if CONFIG_HZ=1000
		#echo HZ / 2 > $Q_PATH/iosched/sync_write_expire  ##if CONFIG_HZ=1000
		#echo 250 > $Q_PATH/iosched/async_read_expire  ##previously used values
		#echo 450 > $Q_PATH/iosched/async_write_expire  ##previously used values
		#echo 350 > $Q_PATH/iosched/sync_read_expire  ##previously used values
		#echo 550 > $Q_PATH/iosched/sync_write_expire  ##previously used values
		echo 1500 > $Q_PATH/iosched/async_read_expire
		echo 1500 > $Q_PATH/iosched/async_write_expire
		echo 150 > $Q_PATH/iosched/sync_read_expire
		echo 150 > $Q_PATH/iosched/sync_write_expire
	elif grep 'cfq' $Q_PATH/scheduler; then
		echo "cfq" > $Q_PATH/scheduler
		sleep 1
		# echo 1 > $Q_PATH/iosched/back_seek_penalty
		# echo 16384 > $Q_PATH/iosched/back_seek_max
		# echo 120 > $Q_PATH/iosched/fifo_expire_sync
		# echo 250 > $Q_PATH/iosched/fifo_expire_async
		# echo 0 > $Q_PATH/iosched/slice_idle
		# echo 8 > $Q_PATH/iosched/group_idle
		# echo 1 > $Q_PATH/iosched/low_latency
		# echo 10 > $Q_PATH/iosched/quantum
		# echo 40 > $Q_PATH/iosched/slice_async
		# echo 2 > $Q_PATH/iosched/slice_async_rq
		# echo 100 > $Q_PATH/iosched/slice_sync
		# echo 300 > $Q_PATH/iosched/target_latency
		echo "	+Using cfq with tuned values" >> $DLL
	else
		echo "	-Something went wrong while changing I/O Scheduler." >> $DLL
		echo "	-Error Code #03"
	fi
	echo 512 > $Q_PATH/read_ahead_kb
	echo 96 > $Q_PATH/nr_requests
	echo 0 > $Q_PATH/add_random
	echo 0 > $Q_PATH/iostats
	echo 1 > $Q_PATH/nomerges
	echo 0 > $Q_PATH/rotational
	echo 1 > $Q_PATH/rq_affinity
fi

echo "	*Finished tuning I/O scheduler" >> $DLL

#TCP tweaks
echo "*Tuning TCP" >> $DLL
if grep 'westwood' /proc/sys/net/ipv4/tcp_available_congestion_control; then
	echo "	+Applying westwood" >> $DLL
	echo westwood > /proc/sys/net/ipv4/tcp_congestion_control
else 
	echo "	+Applying cubic" >> $DLL
	echo cubic > /proc/sys/net/ipv4/tcp_congestion_control
fi
echo 1 > /proc/sys/net/ipv4/tcp_low_latency

echo "	*Finished tuning TCP" >> $DLL

# #Wakelocks
# echo "*Blocking wakelocks" >> $DLL
# if [ -e "/sys/module/bcmdhd/parameters/wlrx_divide" ]; then
	# echo 10 > /sys/module/bcmdhd/parameters/wlrx_divide
# fi
# if [ -e "/sys/module/bcmdhd/parameters/wlctrl_divide" ]; then
	# echo 10 > /sys/module/bcmdhd/parameters/wlctrl_divide
# fi
# if [ -e "/sys/module/wakeup/parameters/enable_bluetooth_timer" ]; then
	# echo Y > /sys/module/wakeup/parameters/enable_bluetooth_timer
# fi
# if [ -e "/sys/module/wakeup/parameters/enable_ipa_ws" ]; then 
	# echo N > /sys/module/wakeup/parameters/enable_ipa_ws
# fi
# if [ -e "/sys/module/wakeup/parameters/enable_netlink_ws" ]; then
	# echo N > /sys/module/wakeup/parameters/enable_netlink_ws
# fi
# if [ -e "/sys/module/wakeup/parameters/enable_netmgr_wl_ws" ]; then
	# echo N > /sys/module/wakeup/parameters/enable_netmgr_wl_ws
# fi
# if [ -e "/sys/module/wakeup/parameters/enable_qcom_rx_wakelock_ws" ]; then 
	# echo N > /sys/module/wakeup/parameters/enable_qcom_rx_wakelock_ws
# fi
# if [ -e "/sys/module/wakeup/parameters/enable_timerfd_ws" ]; then
	# echo N > /sys/module/wakeup/parameters/enable_timerfd_ws
# fi
# if [ -e "/sys/module/wakeup/parameters/enable_wlan_extscan_wl_ws" ]; then 
	# echo N > /sys/module/wakeup/parameters/enable_wlan_extscan_wl_ws
# fi
# if [ -e "/sys/module/wakeup/parameters/enable_wlan_wow_wl_ws" ]; then 
	# echo N > /sys/module/wakeup/parameters/enable_wlan_wow_wl_ws
# fi
# if [ -e "/sys/module/wakeup/parameters/enable_wlan_ws" ]; then
	# echo N > /sys/module/wakeup/parameters/enable_wlan_ws
# fi
# if [ -e "/sys/module/wakeup/parameters/enable_netmgr_wl_ws" ]; then
	# echo N > /sys/module/wakeup/parameters/enable_netmgr_wl_ws
# fi
# if [ -e "/sys/module/wakeup/parameters/enable_wlan_wow_wl_ws" ]; then
	# echo N > /sys/module/wakeup/parameters/enable_wlan_wow_wl_ws
# fi
# if [ -e "/sys/module/wakeup/parameters/enable_wlan_ipa_ws" ]; then
	# echo N > /sys/module/wakeup/parameters/enable_wlan_ipa_ws
# fi
# if [ -e "/sys/module/wakeup/parameters/enable_wlan_pno_wl_ws" ]; then
	# echo N > /sys/module/wakeup/parameters/enable_wlan_pno_wl_ws
# fi
# if [ -e "/sys/module/wakeup/parameters/enable_wcnss_filter_lock_ws" ]; then
	# echo N > /sys/module/wakeup/parameters/enable_wcnss_filter_lock_ws
# fi

# #GPU
echo "simple_ondemand" > /sys/devices/soc/5000000.qcom,kgsl-3d0/devfreq/5000000.qcom,kgsl-3d0/governor
GPU_FREQ=/sys/devices/soc/5000000.qcom,kgsl-3d0/devfreq/5000000.qcom,kgsl-3d0/max_freq
av_freq=/sys/devices/soc/5000000.qcom,kgsl-3d0/devfreq/5000000.qcom,kgsl-3d0/available_frequencies
if [ -e $GPU_FREQ ]; then
	echo "*Applying GPU tweaks" >> $DLL
	if grep '710000000' $av_freq; then
		chmod 644 /sys/devices/soc/5000000.qcom,kgsl-3d0/devfreq/5000000.qcom,kgsl-3d0/max_freq
		echo 670000000 > /sys/devices/soc/5000000.qcom,kgsl-3d0/devfreq/5000000.qcom,kgsl-3d0/max_freq
		chmod 444 /sys/devices/soc/5000000.qcom,kgsl-3d0/devfreq/5000000.qcom,kgsl-3d0/max_freq
	else
		echo "Patoka! - Banana?" >> $DLL
	fi
	if grep '180000000' $av_freq; then
		chmod 644 /sys/devices/soc/5000000.qcom,kgsl-3d0/devfreq/5000000.qcom,kgsl-3d0/target_freq
		echo 257000000 > /sys/devices/soc/5000000.qcom,kgsl-3d0/devfreq/5000000.qcom,kgsl-3d0/target_freq
		echo 180000000 > /sys/devices/soc/5000000.qcom,kgsl-3d0/devfreq/5000000.qcom,kgsl-3d0/min_freq
		chmod 444 /sys/devices/soc/5000000.qcom,kgsl-3d0/devfreq/5000000.qcom,kgsl-3d0/target_freq
	else
		chmod 644 /sys/devices/soc/5000000.qcom,kgsl-3d0/devfreq/5000000.qcom,kgsl-3d0/target_freq
		echo 257000000 > /sys/devices/soc/5000000.qcom,kgsl-3d0/devfreq/5000000.qcom,kgsl-3d0/target_freq
		echo 257000000 > /sys/devices/soc/5000000.qcom,kgsl-3d0/devfreq/5000000.qcom,kgsl-3d0/min_freq
		chmod 444 /sys/devices/soc/5000000.qcom,kgsl-3d0/devfreq/5000000.qcom,kgsl-3d0/target_freq
	fi
	if [ -e "/sys/devices/soc/5000000.qcom,kgsl-3d0/devfreq/5000000.qcom,kgsl-3d0/adrenoboost" ]; then
		chmod 644 /sys/devices/soc/5000000.qcom,kgsl-3d0/devfreq/5000000.qcom,kgsl-3d0/adrenoboost
		echo 1 > /sys/devices/soc/5000000.qcom,kgsl-3d0/devfreq/5000000.qcom,kgsl-3d0/adrenoboost
	fi
	echo "	+GPU tuned" >> $DLL
fi

echo "	*GPU tweaks finished" >> $DLL

echo "*Applying minor tweaks" >> $DLL

## Vibration
if [ -d "/sys/class/timed_output/vibrator/vtg_level" ]; then
	chmod 644 /sys/class/timed_output/vibrator/vtg_level
	echo 812 > /sys/class/timed_output/vibrator/vtg_level
fi

# # #File system
# echo "	+File system tweaks" >> $DLL
# echo 25 > /proc/sys/fs/lease-break-time

#LMK
if [ -e "/sys/module/lowmemorykiller/parameters/enable_adaptive_lmk" ]; then 
	chmod 664 /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
	chown root /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
	echo 1 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
	chmod 444 /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
fi
if [ -e "/sys/module/lowmemorykiller/parameters/minfree" ]; then
	echo "18432,23040,27648,51256,150296,200640" > /sys/module/lowmemorykiller/parameters/minfree
fi
chmod 644 /sys/module/lowmemorykiller/parameters/debug_level
echo 0 > /sys/module/lowmemorykiller/parameters/debug_level
chmod 444 /sys/module/lowmemorykiller/parameters/debug_level

# Low Power Modes ## EXPERIMENTAL
echo N > /sys/module/lpm_levels/parameters/sleep_disabled
# On debuggable builds, enable console_suspend if uart is enabled to save power
# Otherwise, disable console_suspend to get better logging for kernel crashes
if [[ $(getprop ro.debuggable) == "1" && ! -e /sys/class/tty/ttyHS0 ]]
then
    echo Y > /sys/module/printk/parameters/console_suspend
fi

# Enable bus-dcvs
for cpubw in /sys/class/devfreq/*qcom,cpubw* ; do
    echo "bw_hwmon" > $cpubw/governor
    echo 50 > $cpubw/polling_interval
    echo 1144 > $cpubw/min_freq
	echo "1525 5195 11863 13763" > $cpubw/bw_hwmon/mbps_zones
    echo 4 > $cpubw/bw_hwmon/sample_ms
    echo 34 > $cpubw/bw_hwmon/io_percent
    echo 20 > $cpubw/bw_hwmon/hist_memory
    echo 10 > $cpubw/bw_hwmon/hyst_length
    echo 0 > $cpubw/bw_hwmon/low_power_ceil_mbps
    echo 34 > $cpubw/bw_hwmon/low_power_io_percent
    echo 20 > $cpubw/bw_hwmon/low_power_delay
    echo 0 > $cpubw/bw_hwmon/guard_band_mbps
    echo 250 > $cpubw/bw_hwmon/up_scale
    echo 1600 > $cpubw/bw_hwmon/idle_mbps
done
for memlat in /sys/class/devfreq/*qcom,memlat-cpu* ; do
    echo "mem_latency" > $memlat/governor
    echo 20 > $memlat/polling_interval
done
echo "cpufreq" > /sys/class/devfreq/soc:qcom,mincpubw/governor

# Disable Gentle Fair Sleepers ##EXPERIMENTAL
if [ -e "/sys/kernel/debug/sched_features" ]; then
	echo "NO_GENTLE_FAIR_SLEEPERS" > /sys/kernel/debug/sched_features
	echo NO_NEW_FAIR_SLEEPERS > /sys/kernel/debug/sched_features
	echo NO_NORMALIZED_SLEEPER> /sys/kernel/debug/sched_features
fi

#Virtual Memory
echo "	+Virtual memory tweaks" >> $DLL
echo 800 > /proc/sys/vm/dirty_expire_centisecs
echo 2000 > /proc/sys/vm/dirty_writeback_centisecs
echo 1 > /proc/sys/vm/oom_kill_allocating_task
echo 2 > /proc/sys/vm/page-cluster
echo 20 > /proc/sys/vm/swappiness
echo 100 > /proc/sys/vm/vfs_cache_pressure
echo 20 > /proc/sys/vm/dirty_ratio
echo 5 > /proc/sys/vm/dirty_background_ratio
echo 2 > /proc/sys/vm/overcommit_memory
echo 0 > /proc/sys/vm/overcommit_ratio
echo 11093 > /proc/sys/vm/min_free_kbytes
echo 32 > /proc/sys/kernel/random/read_wakeup_threshold
echo 896 > /proc/sys/kernel/random/write_wakeup_threshold

#Turn off some cores for battery listed apps
echo "*Turning off cores for battery listed apps" >> $DLL
if grep 'schedutil' $AGL; then
	chmod 664 /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
	chmod 664 /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
	chmod 664 /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
	chmod 664 /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
	echo $little_max_value > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
	echo $little_min_value > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
	echo 1881600 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
	echo $big_min_value > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
	chmod 644 /sys/devices/system/cpu/online
	echo "0-7" > /sys/devices/system/cpu/online
	chmod 444 /sys/devices/system/cpu/online
	chmod 644 /sys/devices/system/cpu/offline
	echo "" > /sys/devices/system/cpu/offline
	chmod 444 /sys/devices/system/cpu/offline
	chmod 644 /sys/devices/system/cpu/cpufreq/policy0/affected_cpus
	echo "0 1 2 3" > /sys/devices/system/cpu/cpufreq/policy0/affected_cpus
	chmod 444 /sys/devices/system/cpu/cpufreq/policy0/affected_cpus
	chmod 644 /sys/devices/system/cpu/cpufreq/policy4/affected_cpus
	echo "4 5 6 7" > /sys/devices/system/cpu/cpufreq/policy4/affected_cpus
	chmod 444 /sys/devices/system/cpu/cpufreq/policy4/affected_cpus
	echo 1 > /sys/devices/system/cpu/cpu0/online
	echo 1 > /sys/devices/system/cpu/cpu1/online
	echo 1 > /sys/devices/system/cpu/cpu2/online
	echo 1 > /sys/devices/system/cpu/cpu3/online
	echo 1 > /sys/devices/system/cpu/cpu4/online
	echo 1 > /sys/devices/system/cpu/cpu5/online
	echo 1 > /sys/devices/system/cpu/cpu6/online
	echo 1 > /sys/devices/system/cpu/cpu7/online
else
	chmod 664 /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
	chmod 664 /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
	chmod 664 /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
	chmod 664 /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
	echo $little_max_value > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
	echo $little_min_value > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
	echo 1881600 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
	echo $big_min_value > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
	chmod 644 /sys/devices/system/cpu/online
	echo "0-5" > /sys/devices/system/cpu/online
	chmod 444 /sys/devices/system/cpu/online
	chmod 644 /sys/devices/system/cpu/offline
	echo "6-7" > /sys/devices/system/cpu/offline
	chmod 444 /sys/devices/system/cpu/offline
	chmod 644 /sys/devices/system/cpu/cpufreq/policy0/affected_cpus
	echo "0 1 2 3" > /sys/devices/system/cpu/cpufreq/policy0/affected_cpus
	chmod 444 /sys/devices/system/cpu/cpufreq/policy0/affected_cpus
	chmod 644 /sys/devices/system/cpu/cpufreq/policy4/affected_cpus
	echo "4 5" > /sys/devices/system/cpu/cpufreq/policy4/affected_cpus
	chmod 444 /sys/devices/system/cpu/cpufreq/policy4/affected_cpus
	echo 1 > /sys/devices/system/cpu/cpu0/online
	echo 1 > /sys/devices/system/cpu/cpu1/online
	echo 1 > /sys/devices/system/cpu/cpu2/online
	echo 1 > /sys/devices/system/cpu/cpu3/online
	echo 1 > /sys/devices/system/cpu/cpu4/online
	echo 1 > /sys/devices/system/cpu/cpu5/online
	echo 0 > /sys/devices/system/cpu/cpu6/online
	echo 0 > /sys/devices/system/cpu/cpu7/online
fi

#Enable Core Control and Disable MSM Thermal Throttling allowing for longer sustained performance
echo "	+Re-enable core_control and disable msm_thermal" >> $DLL
if [ -e "/sys/module/msm_thermal/core_control/enabled" ]; then
# re-enable thermal hotplug
	# re-enable thermal and BCL hotplug
	if [ -e "/sys/devices/soc/soc:qcom,bcl/mode" ]; then
		echo -n disable > /sys/devices/soc/soc:qcom,bcl/mode
		echo $bcl_hotplug_mask > /sys/devices/soc/soc:qcom,bcl/hotplug_mask
		echo $bcl_soc_hotplug_mask > /sys/devices/soc/soc:qcom,bcl/hotplug_soc_mask
		echo -n enable > /sys/devices/soc/soc:qcom,bcl/mode
	fi
	echo N > /sys/module/msm_thermal/parameters/enabled
	echo 0 > /sys/module/msm_thermal/vdd_restriction/enabled
	echo 1 > /sys/module/msm_thermal/core_control/enabled
fi

#Starting perfd
if [ -e "/data/system/perfd" ]; then
	echo "*Starting perfd" >> $DLL
	start perfd
fi

echo "	*Minor tweaks applied" >> $DLL

echo "#####   COMPLETED    #####" >> $DLL

cdate=$(date)
echo "$cdate" >> $DLL
