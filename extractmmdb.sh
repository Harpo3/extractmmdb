#!/bin/bash
#
# Simple utility to extract Songs table from the MM.DB file using sqlite
# Place a copy of the MM.DB file in the home directory before running
# Usage: extractmmdb.sh VERBOSE (1 or 0)
#
showdisplay=$1
mmdb="$HOME/MM.DB"
mmcsv="$HOME/Songs_MM.DB.csv"
if [[ ! -f "$mmdb" ]] # check for existence of MM.DB in $HOME directory
then
    echo "MM.DB -- NOT FOUND in your $HOME directory!"
    read -n 1 -s -r -p "Press any key to exit"
    exit 1
fi
if [[ -z $( type -p sqlite3 ) ]] # check that sqlite3 exists
then 
    echo -e "REQUIRED: sqlite -- NOT INSTALLED !"
    read -n 1 -s -r -p "Press any key to exit"
    exit 1
fi
echo "MM.DB and sqlite found. Starting extract of MM.DB..."
declare -a list_sqlite_tok # define list of string tokens an SQLite file type should contain
list_sqlite_tok+=( "SQLite" )
list_sqlite_tok+=( "database" )
list_files=( $(find . -maxdepth 1 -type f) ) # get a list of only files in current path
for f in ${!list_files[@]}; do # loop the list of files    
    curr_fname=${list_files[$f]} # get current file
    # get file type result
    curr_ftype=$(file -e apptype -e ascii -e encoding -e tokens -e cdf -e compress -e elf -e tar $curr_fname)
    curr_isqlite=0
    # loop through necessary token and if one is not found then skip this file
    for t in ${!list_sqlite_tok[@]}; do
        curr_tok=${list_sqlite_tok[$t]}
        # check if 'curr_ftype' contains 'curr_tok'
        if [[ $curr_ftype =~ $curr_tok ]]; then
            curr_isqlite=1
        else
            curr_isqlite=0
            break
        fi
    done  
    if (( ! $curr_isqlite )); then   # test if curr file was sqlite        
        continue # if not, do not continue executing rest of script
    fi   
    if [ $showdisplay == 1 ]; then echo "Found SQLite file $curr_fname, exporting tables...";fi   
    curr_tables=$(sqlite3 $curr_fname ".tables") # get tables of sqlite file in one line   
    IFS=$' ' list_tables=($curr_tables)  # split tables line into an array  
    for t in ${!list_tables[@]}; do  # loop array to export each table
        curr_table=${list_tables[$t]}      
        curr_table=$(tr '\n' ' ' <<< $curr_table)   # strip unsafe characters as well as newline
        curr_table=$(sed -e 's/[^A-Za-z0-9._-]//g' <<< $curr_table) 
        if [[ "$curr_table" == "Songs" ]]
        then
            if [ $showdisplay == 1 ]; then echo "Songs table found.";fi
            curr_fname=${curr_fname//.\//} # temporarily strip './' from filename
            # build target CSV filename
            printf -v curr_csvfname "%s_%s.csv" $curr_table "$curr_fname"           
            curr_fname="./"$curr_fname # put back './' to filenames
            curr_csvfname="./"$curr_csvfname
            # export current table to target CSV file
            sqlite3 -header -csv -separator '^' $curr_fname "select SongPath,LastTimePlayed from $curr_table;" > $curr_csvfname
            if [ $showdisplay == 1 ]; then echo "Exported table $curr_table in file $curr_csvfname";fi
        fi
    done
done
