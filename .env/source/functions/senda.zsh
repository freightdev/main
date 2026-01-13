senda() {
    rsync -avz -e "ssh" "$1" "$2"@"$box":"$3"
}
