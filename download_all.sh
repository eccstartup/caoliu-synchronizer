#!/bin/bash

mkdir -p torrents; cd torrents

database="/run/shm/caoliu.db"
while IFS=":" read hash title; do
    ../rmdown.pl "$hash" "$title".torrent
done < <(echo 'select url || ":" || title from page;' | sqlite3 -batch "$database")
