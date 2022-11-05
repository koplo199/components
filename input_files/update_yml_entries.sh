#!/bin/bash

nameprefix="$1"
version="$2"
category="$3"
subcategory="$4"
channel="$5"
commit_sha1="$6"
filename="$7"
repository="$8"

if ! [ -f "$filename" ]; then
    touch $filename
    if [ -z "$subcategory" ]; then
        yq -n -i -y "{\"$nameprefix$version\": {\"Category\":\"$category\", \"Channel\": \"$channel\", \"Commit\": \"$commit_sha1\"}}" $filename
    else
        yq -n -i -y "{\"$nameprefix$version\": {\"Category\":\"$category\", \"Sub-category\":\"$subcategory\", \"Channel\": \"$channel\", \"Commit\": \"$commit_sha1\"}}" $filename
    fi
fi

latest=$(yq -r 'path(.[])[0]' $filename | grep -m1 "$nameprefix")

if [ -z "$latest" ]; then
    if [ -z "$subcategory" ]; then
        yq -i -y "{\"$nameprefix$version\": {\"Category\":\"$category\", \"Channel\": \"$channel\", \"Commit\": \"$commit_sha1\"}} + ." $filename
    else
        yq -i -y "{\"$nameprefix$version\": {\"Category\":\"$category\", \"Sub-category\":\"$subcategory\", \"Channel\": \"$channel\", \"Commit\": \"$commit_sha1\"}} + ." $filename
    fi
fi

latest_channel=$(yq -r ".\"$latest\".Channel" $filename)
latest_commit=$(yq -r ".\"$latest\".Commit" $filename)

if [ "$latest_commit" = "null" ] || [ "$latest_channel" = "null" ]; then
    echo "Cannot find latest commit or channel. Something is wrong with the input file : $filename"
    exit 1
fi

is_newer() {
    git -C "$repository" merge-base --is-ancestor $1 $2
    res=$?
    if [ $res -eq 1 ]; then
        git -C "$repository" merge-base --is-ancestor $2 $1
        if [ $? -eq 1 ]; then
            echo "The two commits are on separate branch. This should NOT have happened."
            exit 1
        fi
    fi
    $newer=$res
}

newer=0
is_newer "$commit_sha1" "$latest_commit"
# Special case : the build source is done elsewhere and the repository only serves to do releases.
if [ "$latest_commit" != "$commit_sha1" ] && [ "$newer" -eq 0 ]; then
    echo "Something is wrong : this new release is based on an earlier commit than the previous one."
    exit 1
fi

if [ "$channel" = "stable" ]; then
    already_exists=$(yq -r 'path(.[])[0]' $filename | grep -m1 "$nameprefix$version")
    echo "ALREADY_EXISTS: $already_exists"
    if [ "$already_exists" != "null" ]; then
        echo "Already up to date."
        exit 0
    fi
    if [ "$latest_channel" = "stable" ]; then
        if [ -z "$subcategory" ]; then
            yq -i -y "{\"$nameprefix$version\": {\"Category\":\"$category\", \"Channel\": \"$channel\", \"Commit\": \"$commit_sha1\"}} + ." $filename
        else
            yq -i -y "{\"$nameprefix$version\": {\"Category\":\"$category\", \"Sub-category\":\"$subcategory\", \"Channel\": \"$channel\", \"Commit\": \"$commit_sha1\"}} + ." $filename
        fi
    else
        yq -i -y "with_entries(if .key == \"$latest\" then .key = \"$nameprefix$version\" else . end) | .\"$nameprefix$version\".Channel = \"$channel\" | .\"$nameprefix$version\".Commit = \"$commit_sha1\"" $filename
    fi
else
    already_exists=$(yq -r 'path(.[])[0]' $filename | grep -m1 "$nameprefix$version-1-${commit_sha1::7}")
    echo "ALREADY_EXISTS: $already_exists"
    if [ "$already_exists" != "null" ]; then
        echo "Already up to date."
        exit 0
    fi
    if [ "$latest_channel" = "stable" ]; then
        if [ -z "$subcategory" ]; then
            yq -i -y "{\"$nameprefix$version-1-${commit_sha1::7}\": {\"Category\":\"$category\", \"Channel\": \"$channel\", \"Commit\": \"$commit_sha1\"}} + ." $filename
        else
            yq -i -y "{\"$nameprefix$version-1-${commit_sha1::7}\": {\"Category\":\"$category\", \"Sub-category\":\"$subcategory\", \"Channel\": \"$channel\", \"Commit\": \"$commit_sha1\"}} + ." $filename
        fi
    else
        yq -i -y "with_entries(if .key == \"$latest\" then .key = \"$nameprefix$version-1-${commit_sha1::7}\" else . end) | .\"$nameprefix$version\".Commit = \"$commit_sha1\"" $filename
    fi
fi
