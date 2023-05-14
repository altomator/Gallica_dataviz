#!/bin/bash
# bash script

# Needs a REST connection to BaseX

collections="bnf partners integrated harvested bnf_and_integrated"

echo "### Extracting data from Gallica SRU API for TYPES ###"

for c in $collections; do
 python3 ../SRU_types.py -s $c -f xml
 returnValue=$?
 if [ $returnValue -ne 0 ]
 then
   echo "### ########################################################## ###"
   echo "### Aborting: no update of the TYPE databases! (check the API) ###"
   echo "### ########################################################## ###"
   exit $returnValue
 fi
done

databases="full bnf partners integrated harvested bnf_and_integrated"
echo "### Creating BaseX databases for each digital collection ###"
for db in $databases; do
 python3 ../../create_DB.py -d data/gallica_types_$db.xml -n gallica_types_$db
 returnValue=$?
 if [ $returnValue -ne 0 ]
 then
   echo "### ######################################################## ###"
   echo "### Aborting: no update of the TYPE databases! (check BaseX) ###"
   echo "### ######################################################## ###"
   exit $returnValue
 fi
done

exit 0
