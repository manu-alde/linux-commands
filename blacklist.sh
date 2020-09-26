#!/bin/bash

errorS()
{
	echo "Error. La sintaxis del script es la siguiente:"
	echo "Indica el PATH de la blacklist.          Escriba: $0 -b blacklist_path"
	echo "Indica el PATH del archivo salida.       Escriba: $0 -o output_path"
}

errorRead()
{
	echo "Error. $1 El archivo no existe o no posee permisos de lectura."
}

errorWrite()
{
    echo "Error. $1 El archivo no existe o no posee permisos de escritura."
}

check_input_available()
{
    show_commands=false

    if [[ -z "$blacklist_path" ]] ; then
        show_commands=true
    fi

    if $output_exists == false && [[ ! -z "$output_path" ]]; then
        echo >> "$output_path"
    else
        show_commands=true
    fi

    if [ "$show_commands" = true ]; then
        errorS
    fi

    if ! test -r "$blacklist_path"; then
        errorRead "$blacklist_path"
        error=true
    fi
    
    if ! test -w "$output_path"; then
      errorWrite "$output_path"
      error=true
    fi

    if [ "$error" = true ] || [ "$show_commands" = true ]; then
        exit 1
    fi
}

blacklistWork()
{
    declare -a pids
    echo "      date      |       pid        |        process        |      user"
    while true;do
        for process in $blacklist;do
            if pgrep "$process" >/dev/null
            then
                pids=$(pgrep -x "$process")
                for pid in $pids;do
                    user=$(ps -o user= -p "$pid")
                    dateTime=$(date '+%F_%T')
                    echo "$dateTime --- $pid --- $process --- $user" 
                    kill -15 "$pid" >/dev/null
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
output_path="blacklist_{$(date '+%F_%T')}.out"

while [ "$1" != "" ]; do
    case $1 in
        #Sets blacklist path - Mandatory
        -b)             shift
                        blacklist_path="$1"
                        output_exists=true
                        ;;
        #Output moves to somewhere else - Optional
        -o)             shift
                        output_path=`echo $1 | sed -e 's/^[[:space:]]*//'`
                        ;;
        -h | --help )   errorS
                        exit 1
                        ;;
        *)              errorS
                        exit 1
                        ;;
    esac
    shift
done

# Check inputs are not wrong
# Check files availability
check_input_available

blacklist=$(awk -v RS='^$' '{print($0)}' "$blacklist_path")

(trap '' SIGHUP SIGKILL SIGINT
    blacklistWork
) </dev/null 2>&1 1>"$output_path"&