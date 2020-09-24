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
    while :
    do
        for process in $blacklist;do
            if pgrep "$process" >/dev/null
            then
                PID=$(pgrep "$process")
                ps -aux | cat "$PID" >> output_path
                kill -9 "$PID"
                echo "$process eliminado"
            fi
        done
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

if ! output_exists==true; then
    output_path="output.out"
fi

if test -r "$blacklist_path"; then
	errorP
    echo "blacklist path error"
    exit 1
fi

blacklist=$(awk -v RS='^$' '{print($0)}' "$blacklist_path")

(trap '' HUP INT
    blacklistWork
) </dev/null 2>&1 1>nohup.out&
