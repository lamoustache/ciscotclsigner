#!/bin/sh

MSG="\033[32m"
ERROR="\033[31m"
TRACE="\033[33m"
CLEAR="\033[0m"

PROGNAME=$(basename $0)
VERSION="Version 0.1"
AUTHOR="2013, Moustache"

MODE=""
FILE=""
CERT=""
PRIVATE_KEY=""
DEBUG=0

_log(){
    if [ "$DEBUG" -eq 1 ]; then
        echo 1>&2 "$@"
    fi
}


print_version() {
    echo "$PROGNAME $VERSION $AUTHOR"
}


usage(){
    print_version
    echo 
    echo " tclsigner.sh [-m <Mode> ] [-f <File> ][-c <Cert>] [-k <Private Key> ] [ [-d [-v]] [-h]  "
    echo " -m Mode          specify operation mode sign | verify | gencrt   "
    echo " -f file          specify file to sign or verify                  "
    echo " -c Cert          specify certificate path                        "
    echo " -k Private Key   specify private key path                        "
    echo " -d               debug                                           "
    echo " -h               this so helpful and beautiful output            "
    echo
}

while getopts "hm:f:c:k:d" opt;
do
    case $opt in
        h)
            usage
            exit 1
	    ;;
        m)  
            MODE="$OPTARG"
            ;;
        f)
            FILE="$OPTARG"
            ;;
        c)
            CERT=$OPTARG
            ;;
        k)
            PRIVATE_KEY=$OPTARG
            ;;
        d)  
            DEBUG=1
            ;;
        ?)
            usage
            exit 1
            ;;
    esac
done


create_ca(){
_log "\n$TRACE DEBUG: Issuing OpenSSL command $CLEAR"
openssl req -x509 -newkey rsa:2048 -days 1095 -nodes -keyout $PRIVATE_KEY -out \
    $CERT -subj /C=UK/O=IT/CN=IT

_log "\n$TRACE DEBUG: Checking error code from OpenSSL command $CLEAR\n"
if [ $? -eq 0 ]; then
    echo "$MSG Generated $PRIVATE_KEY private key and $CERT certificate\n"
else
    echo "\n$ERROR ERROR: generating certificate\n"
    exit 1
fi
}

sign(){
echo "\n$MSG SIGN mode enabled $CLEAR"
_log "\n$TRACE DEBUG: Issuing OpenSSL command $CLEAR"
openssl smime -sign -in $FILE -out $FILE.pk7 -signer $CERT -inkey \
    $PRIVATE_KEY -outform DER -binary > /dev/null

_log "$TRACE DEBUG: Checking error code from OpenSSL command $CLEAR"
if [ $? -eq 0 ]
then
    _log "$TRACE DEBUG: $FILE signed as PKCS7 binary file $CLEAR"
    _log "$TRACE DEBUG: Processing Cisco header in $FILE.pk7 $CLEAR"
    xxd -ps $FILE.pk7 > $FILE.hex
    awk 'NR==1{print "#Cisco Tcl Signature V1.0"}1 {printf "#"; print}' \
    $FILE.hex > $FILE.hex_sig
    echo "\n$MSG Create signed Tcl file $CLEAR\n"
    cat $FILE $FILE.hex_sig > $FILE'_signed.tcl'
else
    echo "$ERROR: Error signing files"
    rm "$FILE.pk7"
    exit 1
fi
}

verify(){
echo "\n$MSG VERIFY mode enabled $CLEAR"

_log "\n$TRACE DEBUG: Issuing OpenSSL command $CLEAR"

openssl smime -verify -in $FILE.pk7 -CAfile $CERT -inform DER -content \
    $FILE > /dev/null

_log "$TRACE DEBUG: Checking error code from OpenSSL command $CLEAR"
if [ $? -eq 0 ]
then
    echo "$MSG $FILE has been succesfully signed $CLEAR\n"
else
    echo "$ERROR $FILE is not correctly signed $CLEAR\n"
fi
}

# check the options passed in parametre of the command.
# If no mode selected we quit

if [ -z "$MODE" ] 
then
    usage
    echo "$ERROR Please select an operation mode\n"
    exit 1

# if selected mode is "sign" we want path to certificate and private key
elif [ "$MODE" = "sign" ]
then
    # if we don't have a file, a cert and a private key we exit and display the help
    if [ -z $FILE ] || [ -z $CERT ] || [ -z $PRIVATE_KEY ]
    then
        echo "$ERROR Please specify a file to sign, the certificate and private key"
        usage
        exit 1
    # otherwise we sign the file and verify the signature is correct
    else
        sign
        verify
    fi

elif [ "$MODE" = "verify" ]
then
    # if we don't have a cert we exit and display the help
    if [ -z $FILE ] || [ -z $CERT ]
    then
        usage
        echo "$ERROR Please specify a file to verify and the certificate\n"
        exit 1
    # otherwise we verify the signature is correct
    else
        verify
    fi
         
# if selected mode is "genkey" we generate keys and Ca cert        
elif [ "$MODE" = "gencrt" ]
then
    if [ -z $CERT ] || [ -z $PRIVATE_KEY ]
    then
        usage
        echo "$ERROR Specify certificate and private key name\n"
        exit 1
    else
        create_ca
    fi

else
    usage
    echo "$ERROR Specify a mode <sign> | <verify> | <gencrt>\n"
    exit 1
fi
