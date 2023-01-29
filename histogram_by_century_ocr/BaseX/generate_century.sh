#!/bin/bash
# bash script

# Needs a REST connection to BaseX


#types="monograph periodical music manuscript image map  object sound video"
types="monograph periodical music manuscript"
collections="bnf integrated bnf_and_integrated partners harvested full"

echo "### Extracting collection data using the Gallica SRU API ###"
for t in $types; do
 echo $t
 for c in $collections; do
   python3 ../SRU_century.py -s $c -t $t -f xml
 done
done


echo "### Creating BaseX databases for each digital collection ###"
for t in $types; do
 echo "-----------------"
 echo $t
 for c in $collections; do
   echo " source: "$c
   in="data/gallica_century_$c-$t.xml"
   inOCR="data/gallica_century_$c-$t-ocr.xml"
   echo $in
   out="gallica_century_$c-$t"
   outOCR="gallica_century_$c-$t-OCR"
   echo $out
   python3 create_DB.py -d $in -n $out
   python3 create_DB.py -d $inOCR -n $outOCR
 done
done

#python3 create_DB.py -d data/gallica_century_full_monograph_ocr.xml -n gallica_century_full_monograph_ocr
#python3 create_DB.py -d data/gallica_century_bnf_monograph.xml -n gallica_century_bnf_monograph
#python3 create_DB.py -d data/gallica_century_bnf_monograph_ocr.xml -n gallica_century_bnf_monograph_ocr

#python3 create_DB.py -d data/gallica_century_full_periodical.xml -n gallica_century_full_periodical
#python3 create_DB.py -d data/gallica_century_full_periodical_ocr.xml -n gallica_century_full_periodical_ocr
#python3 create_DB.py -d data/gallica_century_bnf_periodical.xml -n gallica_century_bnf_periodical
#python3 create_DB.py -d data/gallica_century_bnf_periodical_ocr.xml -n gallica_century_bnf_periodical_ocr

#python3 create_DB.py -d data/gallica_century_full_image.xml -n gallica_century_full_image
#python3 create_DB.py -d data/gallica_century_bnf_image.xml -n gallica_century_bnf_image
