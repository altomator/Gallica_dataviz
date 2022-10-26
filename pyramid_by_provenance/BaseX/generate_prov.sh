#!/bin/bash
# bash script

echo "### Extracting data from Gallica SRU API ###"
python3 ../SRU_prov.py -f xml


echo "### Creating BaseX databases for each digital collection ###"
python3 create_DB.py -d data/gallica_prov.xml -n gallica_prov
