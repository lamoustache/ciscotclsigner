#!/bin/sh

INFO="\033[32m"
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


gen_cert(){
_log "\n$TRACE DEBUG:$CLEAR Issuing OpenSSL command"
openssl req -x509 -newkey rsa:2048 -days 1095 -nodes -keyout $PRIVATE_KEY -out \
    $CERT -subj /C=UK/O=IT/CN=IT > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "$INFO INFO:$CLEAR Generated $PRIVATE_KEY private key and $CERT certificate\n"
else
    echo "\n$ERROR ERROR:$CLEAR  certificate not created\n"
    exit 1
fi
}

sign(){
echo "\n$INFO >>>>> SIGN mode enabled <<<<< \n$CLEAR"

_log "\n$TRACE DEBUG:$CLEAR Issuing OpenSSL command"

openssl smime -sign -in $FILE -out $FILE.pk7 -signer $CERT -inkey \
    $PRIVATE_KEY -outform DER -binary >/dev/null 2>&1

if [ $? -eq 0 ]; then
    _log "$TRACE DEBUG:$CLEAR $FILE signed as PKCS7 binary file"
    _log "$TRACE DEBUG:$CLEAR Processing Cisco header, converting binary to hex $FILE.pk7"
    xxd -ps $FILE.pk7 > $FILE.hex
    if [ $? -ne 0 ]; then
        echo "$ERROR ERROR:$CLEAR Cisco header not processed, error during hex convertion"
        exit 1
    else
        awk 'NR==1{print "#Cisco Tcl Signature V1.0"}1 {printf "#"; print}' \
        $FILE.hex > $FILE.hex_sig
        if [ $? -ne 0 ]; then
            echo "$ERROR ERROR:$CLEAR Cisco header not processed, couldn't append Cisco header to signed file"
            exit 1
        else
            echo "$INFO INFO:$CLEAR Cisco header append to sign Tcl file"
            cat $FILE $FILE.hex_sig > $FILE'_signed.tcl'
            if [ $? -ne 0 ]; then
                echo "$ERROR ERROR:$CLEAR Couldn't create signed Tcl file"
                exit 1
            else
                echo "$INFO INFO:$CLEAR Create signed Tcl file $FILE"
                return 0
            fi
        fi
    fi
else
    echo "\n$ERROR ERROR:$CLEAR file not signed\n"
    if [ -z $FILE ]; then
        rm "$FILE.pk7"
        exit 1
    else
        exit 1
    fi
fi
}

verify(){
echo "\n$INFO >>>>> VERIFY mode enabled <<<<< \n$CLEAR"

_log "\n$TRACE DEBUG:$CLEAR Issuing OpenSSL command"

openssl smime -verify -in $FILE.pk7 -CAfile $CERT -inform DER -content \
    $FILE >/dev/null 2>&1

if [ "$?" -eq 0 ]; then
    echo "$INFO INFO:$CLEAR $FILE has been succesfully signed\n"
else
    echo "$ERROR ERROR:$CLEAR $FILE not signed\n"
fi
}

# check the options passed in parametre of the command.
# If no mode selected we quit

if [ -z "$MODE" ]; then
    echo "$ERROR ERROR:$CLEAR Select an operation mode\n"
    usage
    exit 1

# if selected mode is "sign" we want path to certificate and private key
elif [ "$MODE" = "sign" ]; then
    # if we don't have a file, a cert and a private key we exit and display the help
    if [ -z $FILE ] || [ -z $CERT ] || [ -z $PRIVATE_KEY ]; then
        echo "\n$ERROR ERROR:$CLEAR  Specify a file to sign, the certificate and private key\n"
        usage
        exit 1
    # otherwise we sign the file and verify the signature is correct
    else
        sign
        if [ $? -eq 0 ]; then
            verify
        else
            "$ERROR ERROR:$CLEAR Tcl file not signed"
            exit 1
        fi
    fi

elif [ "$MODE" = "verify" ]; then
    # if we don't have a cert we exit and display the help
    if [ -z $FILE ] || [ -z $CERT ]; then
        echo "\n$ERROR ERROR:$CLEAR Specify a file to verify and the certificate\n"
        usage 
        exit 1
    # otherwise we verify the signature is correct
    else
        verify
    fi
         
# if selected mode is "genkey" we generate keys and Ca cert        
elif [ "$MODE" = "gencrt" ]; then
    if [ -z $CERT ] || [ -z $PRIVATE_KEY ]; then
        echo "\n$ERROR ERROR:$CLEAR Specify certificate and private key name\n"
        usage
        exit 1
    else
        gen_cert
    fi

else
    echo "$ERROR ERROR:$CLEAR Specify the operation mode <sign> | <verify> | <gencrt>\n"
    usage
    exit 1
fi
