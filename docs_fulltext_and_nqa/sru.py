from bs4 import BeautifulSoup
import requests
# import matplotlib.pyplot as plt
# import numpy as np
import pandas
# from pandas.conftest import axis
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry

###### SETTING UP REQUESTS RETRY STRATEGY
retry_strategy = Retry(
    total=6,
    status_forcelist=[429, 500, 502, 503, 504],
    allowed_methods=["HEAD", "GET", "OPTIONS"]
)
adapter = HTTPAdapter(max_retries=retry_strategy)
http = requests.Session()
http.mount("https://", adapter)
http.mount("http://", adapter)
# exemple
#https://gallica.bnf.fr/services/engine/search/sru?operation=searchRetrieve&exactSearch=false&collapsing=true&version=1.2&query=(dc.type%20all%20%22manuscrit%22)%20and%20(indexationdate%3E=%222022/01/01%22%20and%20indexationdate%3C=%222022/01/31%22)&suggest=10&keywords=
#https://gallica.bnf.fr/services/engine/search/sru?operation=searchRetrieve&exactSearch=false&collapsing=false&version=1.2&query=(dc.type%20all%20%22monographie%22)%20and%20(indexationdate%3C=%222022/01/31%22)&suggest=10&keywords=

##################
type = 'monographie' # 'monographie', 'carte', 'image', 'fascicule', 'manuscrit', 'partition', 'sonore', 'objet', 'video'

##################################
### TOTAL ET ÉVOLUTION PAR SIÈCLES
##################################

# First, we get the total number of docs by date online

years = [str(y) for y in range(2007,2022)]
### Stats all docs
grandTotal = {}

for y in years:
  print ("... year:", str(y))
  query = 'https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&query=(indexationdate%3C<=%22'+str(y)+'/12/31%22)&collapsing=false'
  page = requests.get(query) # Getting page HTML through request
  soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
  grandTotal[y] = soup.find("numberOfRecords").get_text()

pandas.DataFrame.from_dict(grandTotal, orient="index").to_csv("total_from_API.csv")

############################################
### Documents et fulltext par type et siècle
############################################

FulltextByTypes = {'manuscrit': {}, 'monographie': {}}
century = [str(c) for c in range(0,21)]

for key in FulltextByTypes.keys():
    type = key
    for c in century:
        print("... century:", str(c))
        query = 'https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&query=(dc.type%20all%20%22' \
                + type + '%22)%20and%20(ocr.quality%20all%20"Texte%20disponible")&filter=century%20all%20%22' \
                + c + '%22)&collapsing=false'
        page = requests.get(query)  # Getting page HTML through request
        soup = BeautifulSoup(page.content, 'xml')  # Parsing content using beautifulsoup
        FulltextByTypes[type][c] = soup.find("numberOfRecords").get_text()

typesRaw = {'manuscrit': {}, 'monographie': {}}
for key in typesRaw.keys():
    type = key
    for c in century:
        print("... century:", str(c))
        if type != "monographie" or int(c) >= 15:
            query = 'https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&query=(dc.type%20all%20%22' \
                    + type + '%22)%20&filter=century%20all%20%22' \
                    + c + '%22)&collapsing=false'
            page = requests.get(query)  # Getting page HTML through request
            soup = BeautifulSoup(page.content, 'xml')  # Parsing content using beautifulsoup
            typesRaw[type][c] = soup.find("numberOfRecords").get_text()

        else:
            typesRaw[type][c] = 0

pandas.concat([pandas.DataFrame.from_dict(typesRaw),
               pandas.DataFrame.from_dict(FulltextByTypes).rename(
                   columns={'manuscrit': "MSS-Fulltext", "monographie": "monogr-Fulltext"})
               ], axis=1).to_csv("TypesWithFulltextByCentury.csv")


########################################################
### OCR NQA (niveau de qualité moyen) by cent's and docs
########################################################
century = [str(c) for c in range(15,21)]

for key in ['monographie']: # ['manuscrit', 'monographie']:
    type = key
    for c in century:
        results = []
        print("... century:"+" ("+key+")", str(c))
        # INITIAL REQUEST
        retry = 0
        query = 'https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&query=(dc.type%20all%20%22' \
                + type + '%22)%20and%20(ocr.quality%20all%20"Texte%20disponible")&filter=century%20all%20%22' \
                + c + '%22)'
        page = requests.get(query)  # Getting page HTML through request
        soup = BeautifulSoup(page.content, 'xml')  # Parsing content using beautifulsoup
        while soup.find('title') is not None and ("Error" or "Unavailable") in soup.find('title').get_text():
            retry += 1
            print(soup.find('title').get_text() + "Retrying for " + retry + " time")
            page = requests.get(query)  # Getting page HTML through request
            soup = BeautifulSoup(page.content, 'xml')  # Parsing content using beautifulsoup

        n = int(soup.find("numberOfRecords").get_text())
        if n is not None and n > 0:
            nextRecord = 1
            while nextRecord is not None and nextRecord <= n:
                # if next record is greater than 1, we need to
                # query again the following records
                if nextRecord > 1:
                    query = 'https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&query=(dc.type%20all%20%22' \
                            + type + '%22)%20and%20(ocr.quality%20all%20"Texte%20disponible")&filter=century%20all%20%22' \
                            + c + '%22)&' \
                            + 'startRecord=' + str(nextRecord)
                    print("querying records " + str(nextRecord) + " of " + str(n))
                    page = requests.get(query)  # Getting page HTML through request
                    soup = BeautifulSoup(page.content, 'xml')  # Parsing content using beautifulsoup
                    # Let's iterate to avoid stopping in the middle of scrapping
                    retries = 0
                    while soup.find("searchRetrieveResponse") is None:
                        retries += 1
                        print("RETYING CAUSE OF EMPTY DOC " + str(retries))
                        page = requests.get(query)  # Getting page HTML through request
                        soup = BeautifulSoup(page.content, 'xml')  # Parsing content using beautifulsoup

                for nqa in soup.find_all("nqamoyen"):
                    results.append([c, type, nqa.get_text()])

                nextRecord = soup.find("nextRecordPosition")
                if nextRecord is not None:
                    nextRecord = int(nextRecord.get_text())
        pandas.DataFrame(results, columns=['Century', 'Type', 'NQA']).to_csv("nqa_"+type+"_"+c+".csv")


