# Gallica_dataviz
  *Datavisualisation of Gallica's digital collections*

Theses scripts perform an analysis of the Gallica collection relatively to its components:
- BnF's collection 
- BnF's digitisation partners (their documents are integrated into the Gallica repository)
- harvested partners (their documents are not integrated, only referenced by their bibliographic record)
and various criteria:
- ocerized/not ocerized
- collection types (monography, manuscript, etc.)
- publication date (century)
- date of on-line publication

## Histogram by century

Usage:
``` 
>python3 sru_century.py -c monographie -s gallica # analysis of the BnF + integrated partners collections
>python3 sru_century.py -c monographie  # analysis of the whole collection
```

![Sample](https://github.com/altomator/Gallica_dataviz/blob/main/histogram_by_century/monographie_by_CENTURY.png)
