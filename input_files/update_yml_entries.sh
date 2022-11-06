#!/bin/bash

nameprefix="$1"
version="$2"
category="$3"
subcategory="$4"
channel="$5"
commit_sha1="$6"
filename="$7"
created_at="$8"

created_at=$(date -d "$created_at" +%s)

echo "mdrrr"
exit 0
if [ "$channel" = "stable" ]; then
    name="$nameprefix$version"
else
    name="$nameprefix$version-1-${commit_sha1::7}"
fi

if ! [ -f "$filename" ]; then
    touch $filename
    if [ -z "$subcategory" ]; then
        yq -n -i -y "{\"$name\": {\"Category\":\"$category\", \"Channel\": \"$channel\", \"Date\": \"$created_at\"}}" $filename
    else
        yq -n -i -y "{\"$name\": {\"Category\":\"$category\", \"Sub-category\":\"$subcategory\", \"Channel\": \"$channel\", \"Date\": \"$created_at\"}}" $filename
    fi
    exit 0
fi

latest=$(yq -r 'path(.[])[0]' $filename | grep -m1 "$nameprefix")

if [ -z "$latest" ]; then
    if [ -z "$subcategory" ]; then
        yq -i -y "{\"$name\": {\"Category\":\"$category\", \"Channel\": \"$channel\", \"Date\": \"$created_at\"}} + ." $filename
    else
        yq -i -y "{\"$name\": {\"Category\":\"$category\", \"Sub-category\":\"$subcategory\", \"Channel\": \"$channel\", \"Date\": \"$created_at\"}} + ." $filename
    fi
    exit 0
fi

latest_channel=$(yq -r ".\"$latest\".Channel" $filename)
latest_date=$(yq -r ".\"$latest\".Date" $filename)

if [ "$latest_date" = "null" ] || [ "$latest_channel" = "null" ]; then
    echo "Cannot find latest commit or channel. Something is wrong with the input file : $filename"
    exit 0
fi

newer=0
if [ "$channel" = "stable" ] && [ "$latest_channel" = "unstable" ]; then
    # Always superseed an unstable build by a stable one
    newer=1
else
    ((time_diff=$created_at - $latest_date))
    # For unstable build, update every week
    if [ $time_diff -lt 0 ] || ([ "$channel" = "unstable" ] && [ $time_diff -lt $((60 * 60 * 24 * 7)) ]); then
        newer=0
    else
        newer=1
    fi
fi

already_exists=$(yq -r 'path(.[])[0]' $filename | grep -m1 "$name")
if [ "$already_exists" != "" ] || ([ "$newer" -eq 0 ] && [ "$channel" = "unstable" ]); then
    echo "Already up to date."
    exit 0
fi

if [ "$newer" -eq 0 ]; then
    echo "Something is wrong : this new entry is older than the previous one."
    exit 0
fi

if [ "$channel" = "stable" ]; then
    if [ "$latest_channel" = "stable" ]; then
        if [ -z "$subcategory" ]; then
            yq -i -y "{\"$name\": {\"Category\":\"$category\", \"Channel\": \"$channel\", \"Date\": \"$created_at\"}} + ." $filename
        else
            yq -i -y "{\"$name\": {\"Category\":\"$category\", \"Sub-category\":\"$subcategory\", \"Channel\": \"$channel\", \"Date\": \"$created_at\"}} + ." $filename
        fi
    else
        yq -i -y "with_entries(if .key == \"$latest\" then .key = \"$name\" else . end) | .\"$name\".Channel = \"$channel\" | .\"$name\".Date = \"$created_at\"" $filename
    fi
else
    if [ "$latest_channel" = "stable" ]; then
        if [ -z "$subcategory" ]; then
            yq -i -y "{\"$name\": {\"Category\":\"$category\", \"Channel\": \"$channel\", \"Date\": \"$created_at\"}} + ." $filename
        else
            yq -i -y "{\"$name\": {\"Category\":\"$category\", \"Sub-category\":\"$subcategory\", \"Channel\": \"$channel\", \"Date\": \"$created_at\"}} + ." $filename
        fi
    else
        yq -i -y "with_entries(if .key == \"$latest\" then .key = \"$name\" else . end) | .\"$name\".Date = \"$created_at\"" $filename
    fi
fi

echo "Updated."
exit 0