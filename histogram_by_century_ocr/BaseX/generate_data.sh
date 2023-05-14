#!/bin/bash
# bash script

# WARNING: Needs a REST connection to BaseX


#types="monograph periodical music manuscript image map  object sound video"
types="periodical monograph music_score manuscript image map object sound video"
types_ocr="periodical monograph music_score"

collections="full bnf partners integrated bnf_and_integrated harvested"
#collections="full"

echo "### Extracting data from the Gallica SRU API for CENTURY ###"
for t in $types; do
 echo $t
 for c in $collections; do
   echo $c
   python3 ../SRU_century_ocr.py -s $c -t $t -f xml
   returnValue=$?
   if [ $returnValue -ne 0 ]
   then
     echo "### ############################################################# ###"
     echo "### Aborting: no update of the CENTURY databases! (check the API) ###"
     echo "### ############################################################# ###"
     exit $returnValue
   fi
 done
done

echo "### Creating BaseX databases for each digital collection ###"
for t in $types; do
 echo "-----------------"
 echo $t
 for c in $collections; do
   echo " source: "$c
   in="data/gallica_century_$c-$t.xml"
   echo $in
   out="gallica_century_$c-$t"
   echo $out
   python3 create_DB.py -d $in -n $out
   returnValue=$?
   if [ $returnValue -ne 0 ]
   then
     echo "### ########################################################### ###"
     echo "### Aborting: no update of the CENTURY databases! (check BaseX) ###"
     echo "### ########################################################### ###"
     exit $returnValue
   fi
   if [[ "$types_ocr" == *"$t"* ]]; then
     inOCR="data/gallica_century_$c-$t-ocr.xml"
     echo $inOCR
     outOCR="gallica_century_$c-$t-ocr"
     echo $outOCR
     python3 create_DB.py -d $inOCR -n $outOCR
     returnValue=$?
     if [ $returnValue -ne 0 ]
     then
       echo "### ########################################################### ###"
       echo "### Aborting: no update of the CENTURY databases! (check BaseX) ###"
       echo "### ########################################################### ###"
       exit $returnValue
     fi
   fi
 done
done
