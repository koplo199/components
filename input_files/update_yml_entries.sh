#!/bin/bash

nameprefix="$1"
version="$2"
category="$3"
subcategory="$4"
channel="$5"
commit_sha1="$6"
filename="$7"
repository="$8"

echo $nameprefix
echo $version
echo $category
echo $subcategory
echo $channel
echo $commit_sha1
echo $filename
echo $repository

if ! [ -f "$filename" ]; then
    touch $filename
    git add $filename
    if [ -z "$subcategorie" ]; then
        yq -n -i -y "{\"$nameprefix$version\": {\"Category\":\"$categorie\", \"Channel\": \"$channel\", \"Commit\": \"$commit_sha1\"}}" $filename
    else
        yq -n -i -y "{\"$nameprefix$version\": {\"Category\":\"$categorie\", \"Sub-category\":\"$subcategorie\", \"Channel\": \"$channel\", \"Commit\": \"$commit_sha1\"}}" $filename
    fi
fi

latest=$(yq -r 'path(.[])[0]' $filename | grep -m1 "$nameprefix")

if [ -z "$latest" ]; then
    if [ -z "$subcategorie" ]; then
        yq -i -y "{\"$nameprefix$version\": {\"Category\":\"$categorie\", \"Channel\": \"$channel\", \"Commit\": \"$commit_sha1\"}} + ." $filename
    else
        yq -i -y "{\"$nameprefix$version\": {\"Category\":\"$categorie\", \"Sub-category\":\"$subcategorie\", \"Channel\": \"$channel\", \"Commit\": \"$commit_sha1\"}} + ." $filename
    fi
fi

latest_channel=$(yq -r ".\"$latest\".Channel" $filename)
latest_commit=$(yq -r ".\"$latest\".Commit" $filename)

if [ -z "$latest_commit" ] || [ -z "$latest_channel" ]; then
    echo "Cannot find latest commit or channel. Something is wrong with the input file : $filename"
    exit 1
fi

is_newer() {
    git -C "$repository" merge-base --is-ancestor $1 $2
    new=$?
    if [ $new -eq 1 ]; then
        git -C "$repository" merge-base --is-ancestor $2 $1
        if [ $? -eq 1 ]; then
            echo "The two commits are on separate branch. This should NOT have happened."
            exit 1
        fi
    fi
    return $new
}

# Special case : the build source is done elsewhere and the repository only serves to do releases.
if [ "$latest_commit" != "$commit_sha1" ] && [ is_newer $commit_sha1 $latest_commit -eq 0 ]; then
    echo "Something is wrong : this new release is based on an earlier commit than the previous one."
    exit 1
fi

if [ "$channel" = "stable" ]; then
    if [ "$nameprefix$version" = "$latest" ]; then
        echo "Already latest stable version."
        exit 0
    fi
    if [ "$latest_channel" = "stable" ]; then
        if [ -z "$subcategorie" ]; then
            yq -i -y "{\"$nameprefix$version\": {\"Category\":\"$categorie\", \"Channel\": \"$channel\", \"Commit\": \"$commit_sha1\"}} + ." $filename
        else
            yq -i -y "{\"$nameprefix$version\": {\"Category\":\"$categorie\", \"Sub-category\":\"$subcategorie\", \"Channel\": \"$channel\", \"Commit\": \"$commit_sha1\"}} + ." $filename
        fi
    else
        yq -i -y "with_entries(if .key == \"$latest\" then .key = \"$nameprefix$version\" else . end) | .\"$nameprefix$version\".Channel = \"$channel\" | .\"$nameprefix$version\".Commit = \"$commit_sha1\"" $filename
    fi
else
    if [ "$nameprefix$version-1-${commit_sha1::7}" = "$latest" ]; then
        echo "Already latest unstable version."
        exit 0
    fi
    if [ "$latest_channel" = "stable" ]; then
        if [ -z "$subcategorie" ]; then
            yq -i -y "{\"$nameprefix$version-1-${commit_sha1::7}\": {\"Category\":\"$categorie\", \"Channel\": \"$channel\", \"Commit\": \"$commit_sha1\"}} + ." $filename
        else
            yq -i -y "{\"$nameprefix$version-1-${commit_sha1::7}\": {\"Category\":\"$categorie\", \"Sub-category\":\"$subcategorie\", \"Channel\": \"$channel\", \"Commit\": \"$commit_sha1\"}} + ." $filename
        fi
    else
        yq -i -y "with_entries(if .key == \"$latest\" then .key = \"$nameprefix$version-1-${commit_sha1::7}\" else . end) | .\"$nameprefix$version\".Commit = \"$commit_sha1\"" $filename
    fi
fi
