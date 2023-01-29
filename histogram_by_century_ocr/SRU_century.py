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
import os
from dicttoxml import dicttoxml

##################
SRU = "https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&collapsing=false&query="
OUT_folder = "data/"
OUT = "gallica_century_"
types=['periodical','monograph', 'manuscript',  'music score', 'image' , "object", "map"]
types_fr=['fascicule','monographie', 'manuscrit', 'partition', 'image', "objet", 'carte']

query=''
result=[]
result_OCR=[]
sources=[]
searchs=[]
collection={}
century=[]
total=0
total_p=0

timeout=2

# last century to process
century_H = 21
century_L = 5

def auto_complete(a_dict):
    # fill empty centuries
    for i in range(century_L,century_H+1):
        if not(str(i) in a_dict):
            #print(i, " century not exists, adding 0 value")
            a_dict[str(i)] = 0

def del_outliers(a_dict):
    # remove centuries
    for key in list(a_dict):
        if (key > century_H) or (key < century_L):
            #print(" removing century ",key)
            a_dict.pop(key)

def output_data(data, src, type, ocr):
    if args.format=="json":
        file_name=OUT_folder+OUT+src+"-"+type+ocr+".json"
        print ("...writing in: ",file_name)
        # JSON serialisation
        json_string = json.dumps(data)
        with open(file_name, 'w') as outfile:
            outfile.write(json_string)
        outfile.close()
    else:
        file_name=OUT_folder+OUT+src+"-"+type+ocr+".xml"
        print ("...writing in: ",file_name)
        # XML serialisation
        xml = dicttoxml(collection, attr_type=False)
        #encoding = 'utf-8'
        #str(xml, encoding)
        with open(file_name, 'w') as outfile:
            outfile.write(xml.decode("utf-8"))
        outfile.close()

# main #
parser = argparse.ArgumentParser()
parser.add_argument("-type","-t", help="type of collection: periodical, monograph, manuscript, music, image, video", required=True)
parser.add_argument("-source","-s", default="full", help="source of collection: full, bnf, bnf_and_integrated, integrated, harvested")
parser.add_argument("-chart","-c", action="store_true", help="Produce a graph")
parser.add_argument("-format","-f", default="json", help="Data format (json, xml)")

args = parser.parse_args()
type = args.type

############################
#types of Gallica documents
# 'monographie', 'carte', 'image', 'fascicule', 'manuscrit', 'partition', 'sonore', 'objet', 'video'

# first century to process
if type=="manuscript":
    #century_L = 1
    type_fr = "manuscrit"
elif type=="periodical":
    #century_L = 15
    type_fr = "fascicule"
elif type=="monograph":
    #century_L = 15
    type_fr = "monographie"
elif type=="music":
    #century_L = 15
    type_fr = "partition"
else:
    type_fr =type

# source of collections
if args.source=="partners": # source != bnf
    provenance = '%20and%20%28not%20dc.source%20adj%20%22Biblioth%C3%A8que%20nationale%20de%20France%22%29%20'
    source_fr = 'partenaires'
elif args.source=="harvested": # source != bnf AND consultation = gallica
    provenance = '%20and%20%28not%20dc.source%20adj%20%22Biblioth%C3%A8que%20nationale%20de%20France%22%29%20and%20%28not%20provenance%20adj%20%22bnf.fr%22%29'
    source_fr = 'moissonnés'
elif args.source=="integrated": # source != bnf AND consultation = gallica only (excluding harvested partners)
    provenance = '%20and%20%28not%20dc.source%20adj%20%22Biblioth%C3%A8que%20nationale%20de%20France%22%29%20and%20%28provenance%20adj%20%22bnf.fr%22%29'
    source_fr = 'intégrés'
elif args.source=="bnf": # source = bnf AND consultation = gallica
    provenance = '%20and%20%28dc.source%20adj%20%22Biblioth%C3%A8que%20nationale%20de%20France%22%29%20and%20%28provenance%20adj%20%22bnf.fr%22%29'
    source_fr = 'BnF'
elif args.source=="bnf_and_integrated": #   BnF + integrated documents
    provenance = '%20and%20%28provenance%20adj%20%22bnf.fr%22%29'
    source_fr = 'BnF et intégrés'
elif args.source=="full": #  all the digital collection
    provenance = ''
    source_fr = 'complète'
else:
    print ("... argument -s (source of collection) must be: full, bnf_partners, BnF, partners, integrated, harvested")
    quit()

print ("--------------------------\n** Documents source set on the command line is: ",args.source,"**")

# Check whether the specified path exists or not
isExist = os.path.exists(OUT_folder)
if not isExist:
   os.makedirs(OUT_folder)
   print("...Data are outputed in: ",OUT_folder)

#centuries=[] #['1', '2', '3', '4','5','6','7','8','9','10', '11', '12', '13', '14','15','16','17','18','19','20','21',]


print ("---------\nQuerying the digital collection\n")
print ("---------\nRequesting documents from: ",args.source,"\n")
print ("  from:",century_L, " century to:", century_H," century")

# using the SRU service
print (" requesting all "+ type +" documents by filter: century")
for c in range(century_L,century_H+1):
  label = str(c)+"e"
  print ("... century: ", label)
  search = '(dc.type%20all%20%22'+type_fr+'%22)'+provenance+'&filter=century%20all%20%22'+str(c)+'%22'
  query = SRU + search
  print (query)
  time.sleep(timeout)
  searchs.append(search)
  century.append(label)
  try:
      page = requests.get(query) # Getting page HTML through request
      soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
      value=int(soup.find("numberOfRecords").get_text())
      result.append(value)
      print (value)
  except:
      print("Wow, ", sys.exc_info()[0], " occurred! Maybe a API error, try again!")
      result.append(0) # SRU bug on century facet
      #quit()

print (" ---------\n SRU sample query:", query)
print (" --------- raw data from the SRU API:\n" , result)

# adding empty values and sorting
#auto_complete(result)
#del_outliers(result)
#sorted_result = dict(sorted(result.items(), key=operator.itemgetter(0)))
#dataset1 = np.array(list(sorted_result.values()))
centuries = len(century)
total_f = sum(result)

# outputing data as JSON
collection['data'] = {}
collection['data']['query'] = {}
collection['data']['query']['sample_url'] = query
collection['data']['query']['date'] = str(date.today())
collection['data']['query']['collection'] = type
collection['data']['query']['collection_fr'] = type_fr
collection['data']['query']['source'] = args.source
collection['data']['query']['source_fr']= source_fr
collection['data']['query']['century'] = century
collection['data']['query']['search'] = searchs
collection['data']['query']['total_with_facet'] = int(total_f)
collection['data']['sru'] = result

print ("\n----\n  now querying the whole collection \n")
# asking for the whole number of documents (no date metadata)
search = '(dc.type%20all%20%22'+type_fr+'%22)'+provenance
query = SRU + search
print (query)
time.sleep(3)
try:
    page = requests.get(query) # Getting page HTML through request
    soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
    result_tot= int(soup.find("numberOfRecords").get_text())
except:
      print("Wow, ", sys.exc_info()[0], " occurred! Maybe a API error, try again!")
      quit()

collection['data']['query']['total_url'] = query
collection['data']['query']['total'] = result_tot

output_data(collection,args.source,type,"")

collection={}
searchs=[]
# OCRed documents
print ("\n----\n  now requesting OCRed documents by filter: century")
for c in range(century_L,century_H+1):
      label = str(c)+"e"
      print ("... century: ", label)
      search = '(dc.type%20all%20%22'+type_fr+'%22)%20and%20(ocr.quality%20all%20%22Texte%20disponible%22)'+provenance+'&filter=century%20all%20%22'+str(c)+'%22'
      query = SRU + search
      #print (query)
      time.sleep(timeout)
      searchs.append(search)
      try:
          page = requests.get(query) # Getting page HTML through request
          soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
          value=int(soup.find("numberOfRecords").get_text())
          result_OCR.append(value)
          print (value)
      except:
          print("Wow, ", sys.exc_info()[0], " occurred! Maybe a API error, try again!")
          result_OCR.append(0) # SRU bug on century facet
          #quit()
print (" ---------\n SRU sample query:", query)
print (" --------- raw data from the SRU API:\n" , result_OCR)

#auto_complete(result_OCR)
#del_outliers(result_OCR)
#sorted_result_OCR = dict(sorted(result_OCR.items(), key=operator.itemgetter(0)))

#print (sorted_result_OCR)
collection['data'] = {}
collection['data']['query'] = {}
collection['data']['query']['sample_sru'] = query
collection['data']['query']['date'] = str(date.today())
collection['data']['query']['collection'] = type
collection['data']['query']['collection_fr'] = type_fr
collection['data']['query']['source'] = args.source
collection['data']['query']['source_fr']= source_fr
collection['data']['query']['century'] = century
collection['data']['query']['search'] = searchs
#collection['data']['query']['facet_name'] = "century"
collection['data']['query']['ocr'] = 'y'
collection['data']['sru'] = result_OCR

print (" ---------\n total documents facetted:", total_f)
print (" total documents:", result_tot)
print (" centuries:", centuries)

output_data(collection,args.source,type,"-ocr")


if not(args.chart):
    quit()

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
