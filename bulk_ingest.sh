#!/bin/bash

#############
## This script takes a start and end number as arguments and will ingest XKCD comics
## from that number range
#############

start=$1
end=$2
code_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${code_dir}/xkcd_config

status=$(/usr/bin/systemctl status mariadb | grep "Active:" | awk '{print $2}')
if [ "${status}" != "active" ]; then
	echo "Aborted Run due to mariadb offline"
	exit 1
fi

cd /tmp
for i in $(seq $start $end); do 
	wget "https://xkcd.com/${i}" -O /tmp/xkcd
	return_c=$?
	count=0
	if [ ${return_c} -ne 0 ]; then
		while [ ${count} -lt 5 ]; do
			wget "https://xkcd.com/${i}" -O /tmp/xkcd
			return_cc=$?
			if [ ${return_cc} -eq 0 ]; then
				count=5
			fi
			sleep 2
			count=$((count+1))
		done
	 fi
	link=$(cat /tmp/xkcd | grep "Image URL (for hotlinking/embedding)" | cut -d':' -f 2- | awk '{$1=$1};1')
	file=$(echo $link | sed 's:.*/::')
	full_path=${archive_dir}/${file}
	title=$(cat /tmp/xkcd | grep "id=\"ctitle\">" | cut -d'>' -f 2 | cut -d'<' -f 1 | sed "s/'//g" | sed 's/\\//g')
	description=$(cat /tmp/xkcd | grep "img src=" | grep title | cut -d'=' -f 3 | sed 's/.\{4\}$//' | sed "s/'//g" | sed 's/\\//g')
	wget "${link}" -O /tmp/xkcd_${i}_${file}
	return_c=$?
	count=0
	if [ $return_c -ne 0 ]; then
		while [ ${count} -lt 5 ]; do
			wget "${link}" -O /tmp/xkcd_${i}_${file}
			return_cc=$?
			if [ ${return_cc} -eq 0 ]; then
				count=5
			fi
			sleep 2
			count=$((count+1))
		done
	fi
	size=$(ls -lh /tmp/xkcd_${i}_${file} | awk '{print $5}')
	if [ ${size} == "0" ]; then
		not_image=1
	else
		not_image=0
	fi
	rm -rf /tmp/xkcd
	mysql --user=$user --password=$password xkcd << EOF
	INSERT INTO comics (comic_id, title, description, permalink, file_path, not_image) VALUES ("$i", '$title', '$description', "$link", "$full_path", "$not_image");
EOF
	return_c=$?
	if [ ${return_c} -eq 0 ]; then
		mv /tmp/xkcd_${i}_${file} ${archive_dir}
		rm -rf /tmp/xkcd_${i}_${file}
		echo "Success ${i}"
	else
		echo "Error Ingesting ${i}"
	fi
	sleep 1
done
