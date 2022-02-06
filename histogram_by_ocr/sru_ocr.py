from bs4 import BeautifulSoup
import requests
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import numpy as np
import sys
import json
from datetime import date
import time
import operator
import argparse

def autopct_generator(limit):
    """Remove percent on small slices."""
    def inner_autopct(pct):
        return ('%.1f%%' % pct) if pct > limit else ''
    return inner_autopct

def auto_complete(a_dict):
    # fill empty centuries
    for i in range(1,century_H+1):
        if not(i in a_dict):
            #print(i, " century not exists, adding 0 value")
            a_dict[i] = 0

def del_outliers(a_dict):
    # remove centuries
    for key in list(a_dict):
        if (key > century_H) or (key < century_L):
            #print(" removing century ",key)
            a_dict.pop(key)

parser = argparse.ArgumentParser()
parser.add_argument("-type","-t", help="type of collection: monographie, manuscrit, fascicule, partition", required=True)
parser.add_argument("-source","-s", default="all", help="source of collection: all, gallica, bnf, integrated")

args = parser.parse_args()
type = args.type

############################
#types of Gallica documents
# 'monographie', 'carte', 'image', 'fascicule', 'manuscrit', 'partition', 'sonore', 'objet', 'video'

# first century to process
if type=="manuscrit":
    century_L = 1
elif type=="fascicule":
    century_L = 17
elif type=="monographie":
    century_L = 15
elif type=="partition":
    century_L = 16
else:
    print ("... argument -t (type of documents) must be: monographie, manuscrit, fascicule, partition, carte")
    quit()

# last century to process
century_H = 21

# source of collections
if args.source=="bnf": # source = bnf AND consultation = gallica
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
    provenance = ''
else:
    print ("... argument -s (source of collection) must be: all, gallica, bnf, partners, integrated, harvested")
    quit()


#centuries=[] #['1', '2', '3', '4','5','6','7','8','9','10', '11', '12', '13', '14','15','16','17','18','19','20','21',]
result={}
result_OCR={}
collection={}
query=''
i=0
OUT = type+"_by_OCR.json"
print ("...writing in: ",OUT)

print (" ---------\n requesting documents from: ",source)
print ("  from:",century_L, " century to:", century_H," century")

# using the SRU service
print (" ---------\n requesting all "+type+" documents by filter: century")
for c in range(century_L,century_H+1):
  print ("... century: ", str(c))
  query = 'https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&collapsing=false&maximumRecords=50&query=(dc.type%20all%20%22'+type+'%22)'+provenance+'&filter=century%20all%20%22'+str(c)+'%22'
  #print (query)
  time.sleep(1)
  try:
      page = requests.get(query) # Getting page HTML through request
      soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
      value=int(soup.find("numberOfRecords").get_text())
      result[c]=value
      print (value)
  except:
      print("Wow, ", sys.exc_info()[0], " occurred!")
      quit()
print (" ---------\n SRU sample query:", query)
print (" --------- raw data from the SRU API:\n" , result)

# adding empty values and sorting
auto_complete(result)
del_outliers(result)
sorted_result = dict(sorted(result.items(), key=operator.itemgetter(0)))
dataset1 = np.array(list(sorted_result.values()))
centuries = len(dataset1)
total_f = sum(dataset1)

# asking for the whole number of documents (without the date md)
query = 'https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&query=(dc.type%20all%20%22'+type+'%22)'+provenance+'&collapsing=false'
try:
    page = requests.get(query) # Getting page HTML through request
    soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
    result_tot= int(soup.find("numberOfRecords").get_text())
except:
      print("Wow, ", sys.exc_info()[0], " occurred!")
      quit()
print (" ---------\n total documents (no date MD used):", result_tot)

# outputing data as JSON
collection['all'] = {}
collection['all']['query'] = {}
collection['all']['query']['sample'] = query
collection['all']['query']['date'] = str(date.today())
collection['all']['query']['collection'] = type
collection['all']['query']['source'] = source
collection['all']['query']['facet_name'] = "century"
collection['all']['query']['total'] = result_tot
collection['all']['query']['with_facet'] = int(total_f)
collection['all']['data'] = sorted_result


# OCRed documents
print (" ---------\n requesting OCRed documents by filter: century")
for c in range(century_L,century_H+1):
      print ("... century: ", str(c))
      query = 'https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&collapsing=false&maximumRecords=50&query=(dc.type%20all%20%22'+type+'%22)%20and%20(ocr.quality%20all%20"Texte%20disponible")'+provenance+'&filter=century%20all%20%22'+str(c)+'%22'
      #print (query)
      time.sleep(1)
      try:
          page = requests.get(query) # Getting page HTML through request
          soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
          value=int(soup.find("numberOfRecords").get_text())
          result_OCR[c]=value
          print (value)
      except:
          print("Wow, ", sys.exc_info()[0], " occurred!")
          quit()
print (" ---------\n SRU sample query:", query)
print (" --------- raw data from the SRU API:\n" , result_OCR)

auto_complete(result_OCR)
del_outliers(result_OCR)
sorted_result_OCR = dict(sorted(result_OCR.items(), key=operator.itemgetter(0)))

#print (sorted_result_OCR)
collection['OCRed'] = {}
collection['OCRed']['query'] = {}
collection['OCRed']['query']['sample'] = query
collection['OCRed']['query']['date'] = str(date.today())
collection['OCRed']['query']['collection'] = type
collection['OCRed']['query']['facet_name'] = "century"
collection['OCRed']['data'] = sorted_result_OCR

print (" ---------\n total documents facetted:", total_f)
print (" total documents:", result_tot)
print (" centuries:", centuries)


# building the chart
labels = list(map(str, sorted_result.keys()))

#print (" yoffset:", yoffset)
#  OCR:
dataset2 = np.array(list(sorted_result_OCR.values()))
# we need to stack the 2 sets in the graph
dataset1 = dataset1 - dataset2 # documents with no OCR
total_1 = sum(dataset1)
total_2 = sum(dataset2)
collection['OCRed']['query']['with_facet'] = int(total_2)
cover1 = "{:.1f}%".format((total_1/total_f)*100)
cover2 = "{:.1f}%".format((total_2/total_f)*100)
p1 = plt.bar(labels, dataset2, color=plt.cm.Paired(1) , label=type+" "+source+" avec OCR : \n"+ str(total_2)+ " sur "+ str(total_f)+" (océrisé à "+ cover2 +")") #https://matplotlib.org/stable/tutorials/colors/colormaps.html
p2 = plt.bar(labels, dataset1, bottom=dataset2, color=plt.cm.Paired(0), label="sans OCR : "+ str(total_1)+ " sur "+ str(total_f)+" ("+ cover1 +")")

cover = "{:.1f}%".format((total_f/result_tot)*100)
plt.xlabel('siècles')
plt.ylabel('#documents')
plt.title('Gallica – Quantité de documents de type '+type+ " par siècles de publication \n Total avec facette 'century' : "+str(total_f)+' sur '+str(result_tot)+' ('+ cover+') - Source : API Gallica SRU')
plt.legend(loc="best")

yoffset = (max(dataset2))*0.02
# display OCR%
i=0
# annotating the graph
for rect2 in p2:
        height1 = p1[i].get_height()
        height2 = p1[i].get_height()+rect2.get_height()
        if (dataset2[i])!=0:
            percent = dataset2[i]/(dataset1[i] + dataset2[i])*100
            plt.annotate( "{:.1f}%".format(percent),(rect2.get_x() + rect2.get_width()/2, height1-yoffset),ha="center",va="bottom",fontsize=5)
            plt.annotate( "{:.1f}%".format(100.0 - percent),(rect2.get_x() + rect2.get_width()/2, height2-yoffset),ha="center",va="bottom",fontsize=5)
            plt.annotate( "{}".format(dataset1[i] + dataset2[i]),(rect2.get_x() + rect2.get_width()/2, height2+yoffset),ha="center",va="bottom",fontsize=8)
        else:
            plt.annotate( "{}".format(dataset1[i]),(rect2.get_x() + rect2.get_width()/2, height1+yoffset),ha="center",va="bottom",fontsize=8)
        i += 1


# Writing JSON data
json_string = json.dumps(collection)
with open(OUT, 'w') as outfile:
    outfile.write(json_string)
outfile.close()

plt.show()
