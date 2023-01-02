#!/bin/bash
# bash script for provenance data

# Needs a REST connection to BaseX


echo "### Extracting data from Gallica SRU API ###"
python3 ../SRU_prov.py -f xml

echo "### Creating BaseX databases for each digital collection ###"
python3 create_DB.py -d data/gallica_prov_full.xml -n gallica_prov_full
python3 create_DB.py -d data/gallica_prov_bnf.xml -n gallica_prov_bnf
python3 create_DB.py -d data/gallica_prov_integrated.xml -n gallica_prov_integrated
python3 create_DB.py -d data/gallica_prov_harvested.xml -n gallica_prov_harvested
