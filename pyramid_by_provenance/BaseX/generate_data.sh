#!/bin/bash
# bash script for provenance data

# Needs a REST connection to BaseX


echo "### Extracting data from Gallica SRU API for PROVENANCE ###"
python3 ../SRU_prov.py -f xml
returnValue=$?
if [ $returnValue -ne 0 ]
then
  echo "### ################################################################ ###"
  echo "### Aborting: no update of the PROVENANCE databases! (check the API) ###"
  echo "### ################################################################ ###"
  exit $returnValue
fi

databases="full bnf integrated harvested"

echo "### Creating BaseX databases for each digital collection ###"
for db in $databases; do
  python3 ../../create_DB.py -d data/gallica_prov_$db.xml -n gallica_prov_$db
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
