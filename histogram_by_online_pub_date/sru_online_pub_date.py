from bs4 import BeautifulSoup
import requests
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import numpy as np
import argparse
from datetime import date
import json
import sys

def autopct_generator(limit):
    """Remove percent on small slices."""
    def inner_autopct(pct):
        return ('%.1f%%' % pct) if pct > limit else ''
    return inner_autopct

# exemple
#https://gallica.bnf.fr/services/engine/search/sru?operation=searchRetrieve&exactSearch=false&collapsing=true&version=1.2&query=(dc.type%20all%20%22manuscrit%22)%20and%20(indexationdate%3E=%222022/01/01%22%20and%20indexationdate%3C=%222022/01/31%22)&suggest=10&keywords=
#https://gallica.bnf.fr/services/engine/search/sru?operation=searchRetrieve&exactSearch=false&collapsing=false&version=1.2&query=(dc.type%20all%20%22monographie%22)%20and%20(indexationdate%3C=%222022/01/31%22)&suggest=10&keywords=

parser = argparse.ArgumentParser()
parser.add_argument("-type","-t", help="type of collection: monographie, manuscrit, fascicule, partition, carte, image, sonore, objet, video", required=True)
parser.add_argument("-source","-s", default="all", help="source of collection: all, gallica, bnf, integrated, harvested")
args = parser.parse_args()

##################
if args.type in ['monographie', 'carte', 'image', 'fascicule', 'manuscrit', 'partition', 'sonore', 'objet', 'video']:
    type = args.type
else:
    print ("... argument -t (type of documents) must be: monographie, manuscrit, fascicule, partition, carte, image, sonore, objet, video")
    quit()
    
start=2007 # no production data available before 2007
end=2023
years=[]
result=[]
result_OCR=[]
collection={}
query=''
ocr=False


############################
if type=="fascicule":
        ocr=True
elif type=="monographie":
        ocr=True
elif type=="partition":
        ocr=True

# source of collections
if args.source=="harvested":
    provenance = '%20and%20%28not%20dc.source%20adj%20%22Biblioth%C3%A8que%20nationale%20de%20France%22%29%20and%20%28not%20provenance%20adj%20%22bnf.fr%22%29'
    source = 'moissonnés'
elif args.source=="bnf": # source = bnf AND consultation = gallica
    provenance = '%20and%20%28dc.source%20adj%20%22Biblioth%C3%A8que%20nationale%20de%20France%22%29%20and%20%28provenance%20adj%20%22bnf.fr%22%29'
    source = 'BnF'
elif args.source=="integrated": # source != bnf AND consultation = gallica only (excluding harvested partners)
    provenance = '%20and%20%28not%20dc.source%20adj%20%22Biblioth%C3%A8que%20nationale%20de%20France%22%29%20and%20%28provenance%20adj%20%22bnf.fr%22%29'
    source = 'intégrés'
elif args.source=="gallica": #  consultation = gallica only (excluding harvested partners)
    provenance = '%20and%20%28provenance%20adj%20%22bnf.fr%22%29'
    source = 'BnF et intégrés'
elif args.source=="all" : # all
    provenance = ''
    source = 'tout'
else:
    print ("... argument -s (source of collection) must be: all, gallica, bnf, partners, integrated, harvested")
    quit()

if args.source=="harvested": # no ocr for harvested partners!
    ocr=False

OUT = type+"_by_ONLINE.json"
print ("...writing in: ",OUT)

#####
print (" ---------\n requesting", type, "from: ",source)
for y in range(start,end):
    print ("... year:", str(y))
    query = 'https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&collapsing=false&query=(dc.type%20all%20%22'+type+'%22)'+provenance+'%20and%20(indexationdate%3C=%22'+str(y)+'/12/31%22)'
    try:
        page = requests.get(query) # Getting page HTML through request
        soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
        value=int(soup.find("numberOfRecords").get_text())
        print (value)
        result.append(value)
        years.append(str(y))
    except:
          print("Wow, ", sys.exc_info()[0], " occurred!\n Maybe a API error, try again!")
          quit()
print (" ---------\n SRU query sample:", query)
print (" --------- raw data from the SRU API:\n" , result)
total = result[-1]

# outputing data as JSON
collection['all'] = {}
collection['all']['query'] = {}
collection['all']['query']['sample'] = query
collection['all']['query']['date'] = str(date.today())
collection['all']['query']['collection'] = type
collection['all']['query']['source'] = source
collection['all']['query']['facet_name'] = "indexationdate"
collection['all']['query']['total'] = total
collection['all']['data'] = result

### OCR
if ocr:
    print (" ---------\n requesting OCRed",type, "from: ",source)
    for y in range(start,end):
        print ("... year:", str(y))
        query = 'https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&collapsing=false&query=(dc.type%20all%20%22'+type+'%22)'+provenance+'%20and%20(ocr.quality%20all%20"Texte%20disponible")%20and%20(indexationdate%3C=%22'+str(y)+'/12/31%22)'
        try:
            page = requests.get(query) # Getting page HTML through request
            soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
            value=int(soup.find("numberOfRecords").get_text())
            result_OCR.append(value)
            print (value)
        except:
            print("Wow, ", sys.exc_info()[0], " occurred!\n Maybe a API error, try again!")
            quit()
    print (" ---------\n SRU query sample:", query)
    print (" --------- raw data from the SRU API:\n" , result)
    total_ocr = result_OCR[-1]
    # outputing data as JSON
    collection['OCRed'] = {}
    collection['OCRed']['query'] = {}
    collection['OCRed']['query']['sample'] = query
    collection['OCRed']['query']['date'] = str(date.today())
    collection['OCRed']['query']['collection'] = type
    collection['OCRed']['query']['source'] = source
    collection['OCRed']['query']['facet_name'] = "indexationdate"
    collection['OCRed']['query']['total'] = total_ocr
    collection['OCRed']['data'] = result_OCR

#
collection['years'] = years

if ocr:
    dataset1 = np.array(result)-np.array(result_OCR)
    dataset2 = np.array(result_OCR)
    p1 = plt.bar(years,dataset2,color=plt.cm.Paired(1), label=type+" "+source+" avec OCR")
    p2 = plt.bar(years,dataset1, bottom=dataset2, color=plt.cm.Paired(0), label="sans OCR")
    plt.title('Gallica – Quantité de documents de type '+type+ " en ligne\n"+ str(years[-1])+ " : "+str(total)+', OCR : '+str(total_ocr)+' - Source : API Gallica SRU')
else:
    dataset1 = np.array(result)
    p1 = plt.bar(years,dataset1, color=plt.cm.Paired(0), label=type+" "+source)
    plt.title('Gallica – Quantité de documents de type '+type+ " en ligne\n"+ str(years[-1])+ " : "+ str(total)+' - Source : API Gallica SRU')

plt.xlabel('années')
plt.ylabel('#documents')
plt.legend(loc="best")

yoffset = max(dataset1)*0.02

# quantity annotations
if ocr:
    i=0
    for rect1 in p1:
        if result[i]!=0:
            height = rect1.get_height()
            percent = result_OCR[i]/result[i]*100
            plt.annotate( "{:.1f}%".format(percent),(rect1.get_x() + rect1.get_width()/2, height-yoffset),ha="center",va="bottom",fontsize=6)
            plt.annotate( "{}".format(result[i]),(rect1.get_x() + rect1.get_width()/2, p2[i].get_height()+height+yoffset),ha="center",va="bottom",fontsize=8)
        else:
            plt.annotate( "{}".format(result[i]),(rect1.get_x() + rect1.get_width()/2, p2[i].get_height()+height+yoffset),ha="center",va="bottom",fontsize=8)
        i += 1
else:
    i=0
    # display sum
    for rect1 in p1:
        height = p1[i].get_height()
        plt.annotate( "{}".format(dataset1[i]),(rect1.get_x() + rect1.get_width()/2, height+yoffset),ha="center",va="bottom",fontsize=8)
        i += 1

# Writing JSON data
json_string = json.dumps(collection)
with open(OUT, 'w') as outfile:
    outfile.write(json_string)
outfile.close()

plt.show()
