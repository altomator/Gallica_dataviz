#!/bin/bash
# bash script for programs data

# Needs a REST connection to BaseX

types="monograph periodical"

echo "### Extracting data from Gallica SRU API for PROGRAMS ###"
for t in $types; do
 python3 ../SRU_prog.py -t $t -f xml
 returnValue=$?
 if [ $returnValue -ne 0 ]
 then
   echo "### ############################################################# ###"
   echo "### Aborting: no update of the PROGRAM databases! (check the API) ###"
   echo "### ############################################################# ###"
   exit $returnValue
 fi
done

echo "### Creating BaseX databases for each digital collection ###"
for t in $types; do
 python3 ../../create_DB.py -d data/gallica_programs_bnf_and_integrated_$t.xml -n gallica_programs_bnf_and_integrated_$t
 python3 ../../create_DB.py -d data/gallica_programs_bnf_and_integrated_ocr_$t.xml -n gallica_programs_bnf_and_integrated_ocr_$t
 returnValue=$?
 if [ $returnValue -ne 0 ]
 then
   echo "### ########################################################### ###"
   echo "### Aborting: no update of the PROGRAM databases! (check BaseX) ###"
   echo "### ########################################################### ###"
   exit $returnValue
 fi
done

exit 0
