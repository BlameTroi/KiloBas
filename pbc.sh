#!/bin/zsh

# Initial start on a compiler wrapper for PureBasic. The currently selected
# options are for a command line utility.
#
# pbc inname outname    which is backwards from pbcompiler <opts> outname
# inname.
#
# If outname is empty, it becomes the basename sans extension from inname.
# `$1:r`

# all args        echo $@
# first arg       echo $1
# second arg      echo $2
# number of args  echo $#

if [[ "$#" -eq 0 ]]
then
	echo "needs at least an input filename"
	exit
elif [[ "$#" -eq 1 ]]
then
	ipf="$1"
	opf="$1:r"
elif [[ "$#" -eq 2 ]]
then
	ipf="$1"
	opf="$2"
else
	echo "invalid arguments, should be input.pb output"
	exit
fi

# -c commented c output
# -l enable line numbering for on error
# -cl generate a console based exe
# -o output file
# -d enable debugger
# -ds create debugger symbols
# -z optimizer
# -p purifier
# -t enable threadsafe support
# -dl macOS create dylib file (replaces -o)
# -n icon to put in bundle

pbopts="-cl -o"

echo pbcompiler $pbopts $opf $ipf
pbcompiler ${=pbopts} $opf $ipf
