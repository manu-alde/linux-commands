#!/bin/bash

errorS()
{
	echo "Error. La sintaxis del script es la siguiente:"
	echo "Indica el PATH de la blacklist.          Escriba: $0 -b blacklist_path"
	echo "Indica el PATH del archivo salida.       Escriba: $0 -o output_path"
}

errorP()
{
	echo "Error. $1 El archivo no existe o no posee permisos de lectura."
}

blacklistWork()
{
    declare -a pids
    echo "      user      |       date        |        process        |      pid"
    while true;do
        for process in $blacklist;do
            if pgrep "$process" >/dev/null
            then
                pids=$(pgrep "$process")
                for pid in $pids;do
                    user=$(ps -o user= -p "$pid")
                    dateTime=$(date)
                    echo "$user | $dateTime | $process | $pid" 
                    kill -15 "$pid"
                done
            fi
        done
        sleep 5
    done
}

if test $# -lt 1; then
    errorS
    exit 1
fi

output_exists=false

while [ "$1" != "" ]; do
    case $1 in
        #Sets blacklist path - Mandatory
        -b)             shift
                        blacklist_path=$1
                        output_exists=true 
                        ;;
        #Output moves to somewhere else - Optional
        -o)             shift
                        output_path=$1
                        ;;
        -h | --help )   errorS
                        exit 1
                        ;;
    esac
    shift
done

if output_exists==false; then
    output_path="output.out"
fi

if ! test -r "$blacklist_path"; then
	errorP
    echo "blacklist path error"
    exit 1
fi

blacklist=$(awk -v RS='^$' '{print($0)}' "$blacklist_path")

(trap '' SIGHUP SIGKILL SIGINT
    blacklistWork
) </dev/null 2>&1 1>"$output_path"&
