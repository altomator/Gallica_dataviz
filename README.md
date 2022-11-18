# Gallica_dataviz
  *Datavisualisation of Gallica's digital collections*

These Python scripts perform an analysis of the Gallica collection relatively to its components:
- BnF's collection 
- BnF's digitisation partners (their documents are integrated into the Gallica's repository)
- BnF's harvested partners (their documents are not integrated, only referenced by their bibliographic record)

and various criteria:
- OCRerized/not OCRerized
- type of documents (monography, manuscript, images, etc.)
- publication date (century)
- date of on-line publication
- digitization programs

All scripts leverage the [Gallica SRU API](https://api.bnf.fr/fr/api-gallica-de-recherche) and generate a graph (optional) and JSON or XML data.

Warning: 
- Some types of documents can be catalogued with the concept of multi-volume documents (books, scores, manuscripts, sound recordings). With the Gallica SRU API, the `collapsing=false` parameter allows to "flatten" these aggregates. These scripts apply `collapsing=false` by default.
- Gallica's quantity information [page](https://gallica.bnf.fr/GallicaEnChiffres) applies various rules for counting numbers of documents that may differ from the SRU API results (maps, images, objects: the number of scanned pages is counted).
- The 2021 peak is due to an error in the harvesting of the BNUS collections.


## Pie chart for types of documents 

This analysis is based on the Gallica types of documents: monography, periodical, manuscript, map, score, image, object, video, sound.
The graph shows the ratio of the collection component (passed as the -source argument) and the entire collection. 

Usage:
``` 
>python3 SRU_types.py  -source partners  # all partners collections compared to the whole collection
>python3 SRU_types.py  -chart # analysis of the whole collection + chart
``` 

![analysis of the partners collections](https://github.com/altomator/Gallica_dataviz/blob/main/pie_by_types/all_by_TYPES_partners.png)

*Analysis of the partners collection relatively to the whole collection*

![analysis of the whole collection](https://github.com/altomator/Gallica_dataviz/blob/main/pie_by_types/all_by_TYPES.jpg)

*Analysis of the whole collection*

## Pie chart by digitization programs

This analysis is dealing with two major digitization programs: 'Indisponibles du XXe siècle' and 'Proquest'. 
The pie shows the ratio of the programs components relatively to the entire collection. The OCRed portion is also computed.

Usage:
``` 
>python3 SRU_programs.py  -type monograph -f xml  # types of collection: monograph or periodical
>python3 SRU_programs.py  -type periodical -f xml   
``` 

![analysis of the programs](https://github.com/altomator/Gallica_dataviz/blob/main/pie_by_programs/mono.png)

*Analysis of the programs for the monographs collection*

## Pyramid by provenance 

This analysis is dealing with the 3 components of the Gallica collection: the BnF holdings, the digitisation partners (their digital content are integrated into Gallica) and the harvested partners (Gallica only references those content). 

Usage:
``` 
>python3 SRU_prov.py
``` 

(See the last section for an example of a graph.)

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

![analysis of the BnF + integrated partners collections](https://github.com/altomator/Gallica_dataviz/blob/main/histogram_by_ocr/monographie_by_OCR.png)

*Analysis of the BnF + integrated partners collections*



## Generating HTML charts with BaseX 

The BaseX subfolders includes a dynamic HTML rendition of the charts using the Highcharts JS library and the BaseX REST feature.

1. A .sh script generates all the XML data with calls to the Python scripts described above. Then anoter Python script populates some BaseX databases thanks to the BaseX [Python client](https://pypi.org/project/BaseXClient/).
2. XQuery scripts can then generate the HTML pages (REST mode).

Example:
``` 
http://localhost:8984/rest?run=plotDataviz_donut.xq&target=bnf&locale=en
``` 

![analysis of the BnF + integrated partners collections relatively to documents types](https://github.com/altomator/Gallica_dataviz/blob/main/pie_by_types/highcharts.jpg)

*Highcharts example: documents types*

![analysis of the BnF + integrated partners collections relatively to provenance](https://github.com/altomator/Gallica_dataviz/blob/main/pyramid_by_provenance/provenance.jpg)

*Highcharts example: provenance*
