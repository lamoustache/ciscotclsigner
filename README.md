Cisco Tcl Signer
================

Cisco IOS Software 12.4(15)T includes support for the cryptographic signing of Tcl scripts. Cryptographic signing makes it possible to ensure that an IOS device will only execute Tcl scripts that have been signed with a certificate for which the device has been explicitly configured. This feature may also be used to prevent the execution of scripts in situations where the signature verification fails due to modification of the script post-signing or the complete lack of a signature.

Cisco Tcl Signer has three modes of operation:

    SIGN <sign>: Sign a Tcl script and verify the signature is valid.
    VERIFY <verify>: Verify the signature of a Tcl script.
    GENCRT <gencrt>: Generate a x509 certificate and private key to sign a script. 

To use Cisco Tcl Signer you must specify the mode of operation.

    [ moustache@antil0p ] ~/code/ciscotclsigner > ./ciscotclsigner.sh
    ciscotclsigner.sh Version 0.1 2013

    ciscotclsigner.sh [-m <Mode> ] [-f <File> ][-c <Cert>] [-k <Private Key> ] [[-d] [-h]]
    -m Mode          specify operation mode sign | verify | gencrt
    -f file          specify file to sign or verify
    -c Cert          specify certificate path
    -k Private Key   specify private key path
    -d               debug
    -h               this so helpful and beautiful output

To sign a Tcl script

    ./ciscotclsigner.sh -m sign -c example/cert.pem -k example/key.pem -f example/helloworld.tcl

To verify the signature of a Tcl script

    ./ciscotclsigner.sh -m verify -c example/cert.pem -f example/helloworld.tcl

To generate a certificate and a private key withh debug enabled

    ./ciscotclsigner.sh -m gencrt -c example/cert.pem -k example/key.pem -d
