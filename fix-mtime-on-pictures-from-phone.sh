#!/bin/sh
#
# Written by Martin Toft Bay <mt@martintoft.dk> on 2025-01-06.
#
# Set mtime based on timestamp in file name for a picture taken on a phone
# using CEST/CET time zones. Beware that all files in the current directory,
# without recursion into sub-directories, are processed. Read the script before
# use. It works on Ubuntu 24.04.
#
# Demo:
#
# $ stat -c %y 'IMG_20130501_223942(0).jpg'
# 2025-01-06 19:56:58.358993781 +0100
# $ ~/fix-mtime-on-pictures-from-phone.sh
# IMG_20130501_223942(0).jpg --> 2013-05-01 22:39:42 CEST
# $ stat -c %y 'IMG_20130501_223942(0).jpg'
# 2013-05-01 22:39:42.000000000 +0200
#
# The trick to get the pictures into a new phone, while keeping the fixed mtime
# values, is to make a number of tarballs (they may typically not exceed 4 GiB,
# depending on transfer method), transfer them to the phone via e.g. MTP, and
# untar them using e.g. the RAR app by RARLAB.

last_sunday() {
  year=$1 # yyyy
  month=$2 # mm
  day=31
  while true; do
    weekday=$(date --utc -d "$year-$month-$day 12:00:00 UTC" +%a)
    if [ "$weekday" = "Sun" ]; then
      echo ${year}${month}${day}
      return
    fi
    day=$((day - 1))
  done
}

time_zone() {
  timestamp=$1 # yyyymmddHHMMSS
  year=$(echo $timestamp | egrep -o '^.{4}')
  winter_time_end=$(last_sunday $year 03)020000
  winter_time_start=$(last_sunday $year 10)020000 # As good as it can be.
  if [ $timestamp -lt $winter_time_end -o $timestamp -ge $winter_time_start ]; then
    echo 'CET'
  else
    echo 'CEST'
  fi
}

find . -mindepth 1 -maxdepth 1 -type f | sort | while read f; do
  f=$(echo "$f" | sed 's/^\.\///')
  remaining=$(echo "$f" | sed -r 's/^([A-Z]+|Resized|Screenshot)[-_]//')
  echo "$remaining" | egrep -q '^20(1[0-9]|2[0-4])(0[1-9]|1[0-2])([0-2][0-9]|3[01])[-_]([01][0-9]|2[0-3])[0-5][0-9][0-5][0-9]'
  if [ $? -ne 0 ]; then
    echo "Skipping $f"
    continue
  fi
  timestamp=$(echo "$remaining" | egrep -o '^[0-9]{8}[-_][0-9]{6}' | sed 's/[-_]//')
  tz=$(time_zone $timestamp)
  proper_timestamp=$(echo $timestamp | sed -r 's/^(.{4})(.{2})(.{2})(.{2})(.{2})(.{2})/\1-\2-\3 \4:\5:\6/')
  echo "$f --> $proper_timestamp $tz"
  touch -d "$proper_timestamp $tz" "$f"
done
