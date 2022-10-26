#!/bin/bash
# bash script

echo "### Extracting data from Gallica SRU API ###"
python3 ../SRU_types.py -s bnf -f xml
python3 ../SRU_types.py -s integrated -f xml
python3 ../SRU_types.py -s harvested -f xml
python3 ../SRU_types.py -s gallica -f xml

echo "### Creating BaseX databases for each digital collection ###"
python3 create_DB.py -d data/gallica_types_full.xml -n gallica_types_full
python3 create_DB.py -d data/gallica_types_bnf.xml -n gallica_types_bnf
python3 create_DB.py -d data/gallica_types_integrated.xml -n gallica_types_integrated
python3 create_DB.py -d data/gallica_types_harvested.xml -n gallica_types_harvested
python3 create_DB.py -d data/gallica_types_gallica.xml -n gallica_types_gallica
