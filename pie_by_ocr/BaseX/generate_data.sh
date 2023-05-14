#!/bin/bash
# bash script for provenance data

# Needs a REST connection to BaseX


echo "### Extracting data from Gallica SRU API for OCR ###"

databases="full bnf partners integrated harvested bnf_and_integrated"

for db in $databases; do
  python3 ../SRU_ocr.py -s $db -f xml
  returnValue=$?
  if [ $returnValue -ne 0 ]
  then
    echo "### ######################################################## ###"
    echo "### Aborting: no update of the OCR databases! (check API)    ###"
    echo "### ######################################################## ###"
    exit $returnValue
  fi
done

echo "\n### Creating BaseX databases for each digital collection ###"
for db in $databases; do
 python3 ../../create_DB.py -d data/gallica_ocr_$db.xml -n gallica_ocr_$db
 python3 ../../create_DB.py -d data/gallica_ocr_$db-ocr.xml -n gallica_ocr_$db-ocr
 returnValue=$?
 if [ $returnValue -ne 0 ]
 then
   echo "### ######################################################## ###"
   echo "### Aborting: no update of the OCR databases! (check BaseX) ###"
   echo "### ######################################################## ###"
   exit $returnValue
 fi
done

exit 0
