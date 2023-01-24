#!/bin/bash
# bash script for provenance data

# Needs a REST connection to BaseX


echo "### Extracting data from Gallica SRU API ###"
python3 ../SRU_ocr.py -s full -f xml
python3 ../SRU_ocr.py -s bnf -f xml
python3 ../SRU_ocr.py -s partners -f xml
python3 ../SRU_ocr.py -s integrated -f xml
python3 ../SRU_ocr.py -s harvested -f xml
python3 ../SRU_ocr.py -s bnf_and_integrated -f xml

echo "### Creating BaseX databases for each digital collection ###"
python3 create_DB.py -d data/gallica_ocr_full.xml -n gallica_ocr_full
python3 create_DB.py -d data/gallica_ocr_full_ocr.xml -n gallica_ocr_full_ocr

python3 create_DB.py -d data/gallica_ocr_bnf.xml -n gallica_ocr_bnf
python3 create_DB.py -d data/gallica_ocr_bnf_ocr.xml -n gallica_ocr_bnf_ocr

python3 create_DB.py -d data/gallica_ocr_partners.xml -n gallica_ocr_partners
python3 create_DB.py -d data/gallica_ocr_partners_ocr.xml -n gallica_ocr_partners_ocr

python3 create_DB.py -d data/gallica_ocr_integrated.xml -n gallica_ocr_integrated
python3 create_DB.py -d data/gallica_ocr_integrated_ocr.xml -n gallica_ocr_integrated_ocr

python3 create_DB.py -d data/gallica_ocr_harvested.xml -n gallica_ocr_harvested
python3 create_DB.py -d data/gallica_ocr_harvested_ocr.xml -n gallica_ocr_harvested_ocr

python3 create_DB.py -d data/gallica_ocr_bnf_and_integrated.xml -n gallica_ocr_bnf_and_integrated
python3 create_DB.py -d data/gallica_ocr_bnf_and_integrated_ocr.xml -n gallica_ocr_bnf_and_integrated_ocr
