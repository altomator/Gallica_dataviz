#!/bin/bash
# TOP LEVEL bash script for generating all data

# NOTE: Needs a REST connection to BaseX

processes="pyramid_by_provenance pie_by_types pie_by_ocr pie_by_programs histogram_by_century_ocr"

for p in $processes; do
   tput rev
   echo "     ---| Extracting collections data: $p |---     "
   tput sgr0
   cd ./$p/BaseX
   ./generate_data.sh
   echo "Exit code: $?"
done
