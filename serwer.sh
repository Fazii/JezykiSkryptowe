#!/bin/bash

ncTraditional=true;
ncOpenBsd=true;
awk=true;
fuser=true;


nc.traditional -h 2> /dev/null || ncTraditional=flase
nc.openbsd -h 2> /dev/null || ncOpenBsd=false
awk 2> /dev/null || ncOpenBsd=false


function is_port_free {

    if ! lsof -i:$1 > /dev/null
        then
            port=$1
        else
            echo "Port $1 jest zajety"
            echo "Podaj inny port: "
            read port
            is_port_free $port
    fi

}

is_port_free 8888

if [ "$#" -eq 0 ] || [ "$1" == '-h' ] || [ "$1" == '--help' ]; then
    echo "To jest skrypt pomocniczy, ktory nie powinien byc wywolywany osobno, wywolaj: generator.pl -h aby otrzymac wiecej informacji"
    echo "Jesli jednak wygenerowales juz plik output.html to podaj ścieżkę do pliku jako pierwszy argument"
    echo "Jesli chcesz wygenerowac sparsowany plik txt zawierajacy najwazniejsze informacje z pliku output.html, jako drugi argument podaj -p"
    exit
fi

path="$1"
html="/output.html"
fullpath=$path$html

if  [ ! -f $fullpath ]; then
    echo "Podaj poprawną sciezke do pliku zrodlowego 'output.html'"
    exit 1
fi

if [ "$ncTraditional" = "false" ] && [ "$ncOpenBsd" = "false" ]; then
    echo "netcat jest wymagany do dzialania programu"
    exit 1
fi

if [ "$awk" = "false" ] ; then
    echo "awk jest wymagany do dzialania programu"
    exit 1
fi

if [ "$#" -eq 2 ] && [ "$2" == '-p' ]; then

awk -F'<TD[^>]*>|</TD>' '$2{print $2}' $fullpath > parsed.txt

    index="Index: "
    fileName="File Name: "
    size="Size(in bytes): "
    timeOfLastAccess="Time of last access: "
    timeOfLastModification="Time of last modification: "
    timeOfLastMetadataChange="Time of last metadata change: "
    duplicate1="Duplicate1: "
    duplicate2="Duplicate2: "
    file="parsed.txt"
    iterator=1
    indexLine=0
    duplicated=false
    while read -r line
    do
        if [ "$duplicated" = "true" ] ; then
            if [ "$iterator" -eq 1 ]; then
                echo "${index}$line"
            elif [ "$iterator" -eq 2 ]; then
                echo "${duplicate1}$line"
            elif [ "$iterator" -eq 3 ]; then
                echo "${duplicate2}$line"
            fi

            iterator=$((iterator+1))
            if [ "$iterator" -eq 4 ]; then
                echo ""
                iterator=1
            fi
        else
            if [ "$iterator" -eq 1 ]; then
                if (( $indexLine != line - 1 )); then
                    duplicated=true
                fi
            indexLine=$line
                echo "${index}$line"
            elif [ "$iterator" -eq 2 ]; then
                echo "${fileName}$line"
            elif [ "$iterator" -eq 3 ]; then
                echo "${size}$line"
            elif [ "$iterator" -eq 4 ]; then
                echo "${timeOfLastAccess}$line"
            elif [ "$iterator" -eq 5 ]; then
                echo "${timeOfLastModification}$line"
            elif [ "$iterator" -eq 6 ]; then
                echo "${timeOfLastMetadataChange}$line"
            fi
                iterator=$((iterator+1))
            if [ "$iterator" -eq 7 ]; then
                echo ""
                iterator=1
            fi
        fi

    done <$file > newfile
    mv newfile $file
echo "Wygenerowano plik parsed.txt"
fi

if [ "$ncOpenBsd" = "true" ]; then
    echo "Uruchamiam serwer localhost na porcie $port przy pomocy nc.openbsd"
    echo "ctrl + c, aby zakonczyc dzialanie serwera"
    while true; do
        echo -e "HTTP/1.1 200 OK\n\n $(<$fullpath)" | > /dev/null nc.openbsd -l -p $port -q 1 || break
    done
    fuser -k $port/tcp
else
    echo "Uruchamiam serwer localhost na porcie $port przy pomocy nc.traditional"
    echo "ctrl + c, aby zakonczyc dzialanie serwera"
    while true; do
        echo -e "HTTP/1.1 200 OK\n\n $(<$fullpath)" | > /dev/null nc.traditional -l -p $port -q 1 || break
    done
    fuser -k $port/tcp
fi