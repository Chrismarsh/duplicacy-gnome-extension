#!/usr/bin/env bash

PAUSED=false

# File to hold paused state
pausedfile="/home/chris/.config/argos/duplicacy.paused"

#location of Duplicacy's backup log file
backuplog="/home/chris/duplicacy.backup.log"

#Check for paused file
if [[ -f "$pausedfile" ]]; then
    PAUSED=true

    #kill any running duplicacy processes
    if pidof -o %PPID -x "duplicacy">/dev/null; then
    	killall duplicacy
    fi
    echo "Duplicacy (paused)"
# if duplicacy is running
elif pidof -o %PPID -x "duplicacy">/dev/null; then\
	#check percent uploaded + upload rate from the log file
	PERCENT=$(tail -n1 $backuplog | egrep -o '[0-9]+\.[0-9]+%')
	RATE=$(tail -n1 $backuplog | egrep -o '[0-9]+\.?[0-9]+?[MK]B/s')

	# at the start of the run, there is no % in the log file as it enuerates, so just show 'running'
	if [[ -z $PERCENT ]]; then

		# might be starting, but might also be running a prune
		PRUNE=$(pgrep -f  'duplicacy prune')
		if [[ -z $PRUNE ]]; then
			echo "Duplicacy (running)"
		else
			echo "Duplicacy (prune)"
		fi
	else
   		echo "Duplicacy $PERCENT ($RATE)"
   	fi
else
	#use this python script to get the time of next run
	NEXT_RUN=$(python -c 'import humanfriendly; from croniter import croniter; from datetime import datetime; iter = croniter("*/30 * * * *", datetime.now()); dt= iter.get_next(datetime)-datetime.now(); print(humanfriendly.format_timespan(dt,max_units=1))')

	echo "Duplicacy ($NEXT_RUN)"
fi


echo "---"

# Show the tail end of the output log
OUTPUT=$(tail -n7 $backuplog)
echo "$OUTPUT | font=monospace"

# if [[ -z $PRUNE ]]; then
# 	echo "---"
# 	OUTPUT=$(tail -n7 ~/duplicacy.prune.backup.log)
# 	echo "$OUTPUT | font=monospace"
# fi

echo "---"
echo "Run now | bash='rm $pausedfile;~/run_backup.sh;' terminal=false"

if [[ "$PAUSED" = true ]]; then
	echo "Resume | bash='rm $pausedfile' terminal=false"
else
	echo "Pause | bash='touch $pausedfile' terminal=false"
fi

echo "View log | bash='cat $backuplog'"
