#!/bin/dash

#Error code summary#

#1 : Error in argument (wrong entry)#
#2 : Number of arguments is incorrect#


#Print help / error messages#
printHelp() {
    echo "usage : ./find.sh [DIR] [OPTION]...

Search for files in a directory hierarchy DIR.
If DIR is not specified, the search is performed in the current directory.
OPTIONS
    --help              show help and exit
    -name PATTERN       Finding files whose name match the shell pattern PATTERN
                        The pattern must be a nonempty string with no white-space
                        characters
    -type {d|f}         Finding files that are directories (type d)
                        or regular files (type f)
    -size [+|-]SIZE     Finding files whose size is greater than or equal(+), or less
                        than or equal (-), or equal to SIZE
    -exe COMMAND        Run the command COMMAND for each file found instead of
                        displaying its path
                        In the string COMMAND, each pair of braces {} will be replaced
                        by the path to the found file
                        The string COMMAND must contain at least one pair of braces {}"
    exit 0
}


printUsageMessage() {
    echo "usage : ./find.sh [DIR] [OPTION]..."
    echo "Use option --help for more details to use the command"
}

#Memorisations of arguments in variables#

arg1=$1
arg2=$2
arg3=$3
arg4=$4
arg5=$5
arg6=$6
arg7=$7
arg8=$8
arg9=$9

#Memorisation of active options#

name=1
type=1
size=1
exe=1

nameParameter=0
typeParameter=0
sizeParameter=0
exeParameter=0

#Verifying correct argument number#

nbArg=$#

if [ $nbArg -gt 9 ]; then
    echo "Error, number of arguments is incorrect" 2>/dev/null
    printUsageMessage
    exit 2
fi

#Create a set of all files in the specified directory#
makeSet() {
    local I 
    if [ $# -eq 0 ]; then
        for I in *
        do
            set=$set' '$I
        done
    else
        for I in $1/*
            do
                set=$set' '$I
        done
    fi
}



#Create a set of all regular files in the specified directory#
makeSetFiles() {
    local I 
    for I in $1/*
        do
            if [ -d $I ] 2>/dev/null; then
                    makeSetFiles $I
                fi
                if [ -f $I ] 2>/dev/null && ! [ -L $I ] 2>/dev/null; then
                    set=$set' '$I
                fi
        done
}


#Create a set of all directories in the specified directory#
makeSetDirectories() {  
    local I
    for I in $1/*
    do
        if [ -d $I ] 2>/dev/null; then
            set=$set' '$I
            makeSetDirectories $I
        fi        
    done
    
}


#Create a subset with elements that match the correct size specified in options. $1 : size#
makeSubsetSize() {
    iterator=$set
    set=
    eq=0   
    echo $1 | grep -E -q '[+-]'
    if [ $? -eq 0 ]; then
        eq=1
    fi
    for i in $iterator
    do
        if [ $1 -lt 0 ]; then
            size=$(du -k $i | sed 's/\([0-9]*\).*/\1/')
            absValue=$(echo $1 | sed -E 's/-(\d*)/\1/')
            if [ $size -le $absValue ] 2>/dev/null; then
                set=$set' '$i
            fi
        else
            size=$(du -k $i | sed 's/\([0-9]*\).*/\1/')
            if [ $size -ge $1 ] 2>/dev/null && [ $eq -eq 1 ] 2>/dev/null; then
                set=$set' '$i
            else
                if [ $size -eq $1 ] 2>/dev/null; then
                    set=$set' '$i
                fi
            fi
        fi
    done
}

#Create a subset with elements that match the pattern specified in options. $1 : pattern#
makeSubsetName() {
    iterator=$set
    set=
    for i in $iterator
    do
        tmp=${i##*'/'}
        echo $tmp | grep -E -q "$1"
        if [ $? -eq 0 ]; then
            set=$set' '$i
        fi
    done
}


#Print function or execute command#
printResult() {
    #Case no argument entered : displaying all files in the current directory#
    if ! [ $type -eq 0 ]; then
        makeSet $1
    else
        if [ $typeParameter = 'f' ]; then
            makeSetFiles $1
        else
            makeSetDirectories $1
        fi
    fi

    if [ $name -eq 0 ]; then
        makeSubsetName $nameParameter
    fi

    if [ $size -eq 0 ]; then 
        makeSubsetSize $sizeParameter
    fi

    #Case no command entered : displaying files in the computed set#
    if ! [ $exe -eq 0 ]; then
        for i in $set
        do
            echo $i
        done 
    #Case command entered : executing command for all files in the directory#
    else
        execCMD=$(echo $exeParameter | cut -d '{' -f 1)
        for i in $set
        do
            eval $execCMD$i
        done
    fi
    exit 0
}


#Check if parameters passed in options are in the good format#
checkOptionsEntry() {
    if [ $1 = '-name' ]; then
        #check that there is no space inside the pattern#
        echo "$2" | grep -E -q '\s'
        if [ $? -eq 1 ]; then
            name=0
            nameParameter=$2
            return 0
        else
            return 1
        fi
    elif [ $1 = '-type' ]; then
        test $2 = 'f' 2>/dev/null || test $2 = 'd' 2> /dev/null
        if [ $? -eq 0 ] 2> /dev/null; then
            type=0
            typeParameter=$2
            return 0
        else
            return 1
        fi
    elif [ $1 = '-size' ]; then
        #check that the input is a relative number#
        echo "$2" | grep -E -q '^[+-]?[0-9]+$' 
        if [ $? -eq 0 ]; then
            size=0
            sizeParameter=$2
            return 0
        else
            return 1 
        fi 
    else
        cmd=$(echo $2 | cut -d ' ' -f 1)
        which $cmd 2> /dev/null 1> /dev/null
        if [ $? -eq 0 ]; then
            echo $2 | grep -E -q ' {}'
            if [ $? -eq 0 ]; then
                exe=0
                exeParameter=$2
                return 0
            else
                return 1
            fi
        else
            return 1
        fi
    fi
}


#Stop the processus and exit the programm if return code is equal to 1#
verification() {
    if [ $1 -eq 1 ]; then
        echo "Error, in the entry of argument $2." >&2
        printUsageMessage
        exit 2
    fi
    return
}

#Verification that options exists#
if [ $nbArg -eq 0 ]; then
    printResult
fi

#Triggered when a directory is entered in the options#
rep=1
#Contains the list of options in the script#
listOpt=

if [ $nbArg -gt 0 ]; then    
    if  ! [ $1 = '--help' ] && ! [ -d $1 ]; then
        if ! [ -z $1 ]; then
            if ! [ $1 = '-name' ] && ! [ $1 = '-type' ] && ! [ $1 = '-size' ] && ! [ $1 = '-exe' ]; then
                echo "Error, in the entry of the first argument." >&2
                printUsageMessage
                exit 1
            else
                listOpt=$listOpt' '$1
                checkOptionsEntry $1 "$2"
                verification $? 1
            fi  
        fi

        if ! [ -z $3 ]; then
            if ! [ $3 = '-name' ] && ! [ $3 = '-type' ] && ! [ $3 = '-size' ] && ! [ $3 = '-exe' ]; then
                echo "Error, in the entry of the second argument." >&2
                printUsageMessage
                exit 1
            else
                listOpt=$listOpt' '$3
                checkOptionsEntry $3 "$4"
                verification $? 2
            fi  
        fi

        if ! [ -z $5 ]; then
            if ! [ $5 = '-name' ] && ! [ $5 = '-type' ] && ! [ $5 = '-size' ] && ! [ $5 = '-exe' ]; then
                echo "Error, in the entry of the third argument." >&2
                printUsageMessage
                exit 1
            else
                listOpt=$listOpt' '$5 
                checkOptionsEntry $5 "$6"
                verification $? 3
            fi  
        fi

        if ! [ -z $7 ]; then
            if ! [ $7 = '-name' ] && ! [ $7 = '-type' ] && ! [ $6 = '-size' ] && ! [ $7 = '-exe' ]; then
                echo "Error, in the entry of the fourth argument." >&2
                printUsageMessage
                exit 1
            else
                listOpt=$listOpt' '$7
                checkOptionsEntry $7 "$8"
                verification $? 4
            fi  
        fi
    else    
        rep=0
        if ! [ -z $2 ]; then
            if ! [ $2 = '-name' ] && ! [ $2 = '-type' ] && ! [ $2 = '-size' ] && ! [ $2 = '-exe' ]; then
                echo "Error, in the entry of the first argument." >&2
                printUsageMessage
                exit 1
            else
                listOpt=$listOpt' '$2
                checkOptionsEntry $2 "$3"
                verification $? 1
            fi 
        fi

        if ! [ -z $4 ]; then
            if ! [ $4 = '-name' ] && ! [ $4 = '-type' ] && ! [ $4 = '-size' ] && ! [ $4 = '-exe' ]; then
                echo "Error, in the entry of the second argument." >&2
                printUsageMessage
                exit 1
            else
                listOpt=$listOpt' '$4
                checkOptionsEntry $4 "$5"
                verification $? 2
            fi
        fi

        if ! [ -z $6 ]; then
            if ! [ $6 = '-name' ] && ! [ $6 = '-type' ] && ! [ $6 = '-size' ] && ! [ $6 = '-exe' ]; then
                echo "Error, in the entry of the third argument." >&2
                printUsageMessage
                exit 1
            else
                listOpt=$listOpt' '$6
                checkOptionsEntry $6 "$7"
                verification $? 3
            fi
        fi

        if ! [ -z $8 ]; then
            if ! [ $8 = '-name' ] && ! [ $8 = '-type' ] && ! [ $8 = '-size' ] && ! [ $8 = '-exe' ]; then
                echo "Error, in the entry of the fourth argument." >&2
                printUsageMessage
                exit 1
            else
                listOpt=$listOpt' '$8
                checkOptionsEntry $8 "$9"
                verification $? 4
            fi
        fi
    fi
fi

#Check that no multiple occurences of an option can be found#
pb=1
check=$(echo $listOpt | grep -o '\-name' | wc -l)
check=$(echo $check | tr -d ' ')
if [ $check -gt 1 ]; then
    pb=0
fi

check=$(echo $listOpt | grep -o '\-type' | wc -l)
check=$(echo $check | tr -d ' ')
if [ $check -gt 1 ]; then
    pb=0
fi

check=$(echo $listOpt | grep -o '\-size' | wc -l)
check=$(echo $check | tr -d ' ')
if [ $check -gt 1 ]; then
    pb=0
fi

check=$(echo $listOpt | grep -o '\-exe' | wc -l)
check=$(echo $check |tr -d ' ')
if [ $check -gt 1 ]; then
    pb=0
fi

if [ $pb -eq 0 ]; then
    echo "Error, there are mutiple occurence of the same option." >&2
    printUsageMessage
    exit 1
fi

#Testing if help requested and display the files or execute the command#
if [ $nbArg -eq 1 ] && [ $1 = '--help' ]; then
    printHelp
elif [ $nbArg -ge 1 ] && [ -d $1 ]; then
    printResult $1
else
    printResult .
fi