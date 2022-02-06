# Gallica_dataviz
  *Datavisualisation of Gallica's digital collections*

Theses Python scripts perform an analysis of the Gallica collection relatively to its components:
- BnF's collection 
- BnF's digitisation partners (their documents are integrated into the Gallica repository)
- BnF's harvested partners (their documents are not integrated, only referenced by their bibliographic record)

and various criteria:
- ocerized/not ocerized
- type of documents (monography, manuscript, images, etc.)
- publication date (century)
- date of on-line publication

All scripts generate a graph and JSON data.

## Histogram by century

This analysis is based on the "century" facet of Gallica, the coverage of which may vary depending on the component of the collection studied and the type of documents. This coverage is provided (%).

The graph shows the ratio of the collection component (passed as the -source argument) to the entire collection. If no -source argument is provided, the whole collection is analyzed.

Usage:
``` 
>python3 sru_century.py -t monographie -s gallica # analysis of the BnF + integrated partners collections
>python3 sru_century.py -t monographie  # analysis of the whole collection
```

![analysis of the BnF + integrated partners collections](https://github.com/altomator/Gallica_dataviz/blob/main/histogram_by_century/monographie_by_CENTURY.png)
*Analysis of the BnF + integrated partners collections*

## Histogram by date of on-line publication

This analysis is based on the "indexationdate" facet of Gallica. This data is only available from 2007.

The graph shows the ratio of the collection component (passed as the -source argument) to the entire collection. If no -source argument is provided, the whole collection is analyzed. Considering the type of documents, the OCRed part of collection is also provided.

Usage:
``` 
>python3 sru_online_pub_date.py -t monographie -s gallica # analysis of the BnF + integrated partners collections
>python3 sru_online_pub_date.py -t monographie  # analysis of the whole collection
```

![analysis of the whole collection](https://github.com/altomator/Gallica_dataviz/blob/main/histogram_by_online_pub_date/monographie_by_ONLINE.png)
*Analysis of the whole collection*

## Histogram by OCR presence

This analysis is also based on the "century" facet of Gallica and show the OCRed part of the collection.
It only operates on specific types: monography, periodical, manuscript, score.

As harvested partners can't be ocerized, they are not part of this analysis.

Usage:
``` 
>python3 sru_ocr.py -t monographie -s gallica # analysis of the BnF + integrated partners collections
>python3 sru_ocr.py -t monographie  # analysis of the whole collection
```

![analysis of the BnF + integrated partners collections](https://github.com/altomator/Gallica_dataviz/blob/main/histogram_by_online_pub_date/monographie_by_OCR.png)
*Analysis of the BnF + integrated partners collections*
