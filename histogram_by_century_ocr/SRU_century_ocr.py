# Query the Gallica SRU API to output documents quantities by date of publication (centuries)
# Output data as XML or JSON files

# usage: python3 SRU_century.py -s source -t type [-f] format [-c]

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
# output folder
OUT = "gallica_century_"

args = ""

# time out between calls to the API
timeout=10

# centuries to process
century_L = 1
century_H = 21
labels=[]

# importing constants and vars
sys.path.append(os.path.abspath("/Users/bnf/Documents/BnF/Dev/Dataviz/Gallica-médiation des collections/_python_stuff"))
from dataviz import *

# MAIN #
print ("##################################################")
parser = argparse.ArgumentParser()
parser.add_argument("-type","-t", help="type of collection: "+' '.join(types), required=True)
parser.add_argument("-source","-s", default="full", help="source of collection: "+' '.join(sources_coll))
parser.add_argument("-chart","-c", action="store_true", help="Produce a graph")
parser.add_argument("-format","-f", default="json", help="Data format (json, xml)")
args = parser.parse_args()

############################
#types of Gallica documents
type_target = args.type
try:
    type_index = types.index(type_target)
    type_fr=types_fr[type_index]
    print(" ...processing type: \033[7m",type_fr,"\033[m")
except:
    print("# type argument [-t] must be in: ")
    print (' '.join(types))
    quit()

#centuries=[] #['1', '2', '3', '4','5','6','7','8','9','10', '11', '12', '13', '14','15','16','17','18','19','20','21',]
# first century to process
#if type=="manuscript":
    #century_L = 1
#    type_fr = "manuscrit"
#else:
#    type_fr =type

# source of collections
src_target = args.source
try:
    src_index = sources_coll.index(src_target)
    source_fr=sources_coll_fr[src_index]
    provenance=queries_coll[src_index]
    print(" ...processing source: \033[7m", source_fr,"\033[m")
except:
    print("# source argument [-s] must be in: ")
    print (' '.join(sources_coll))
    quit()

#print ("--------------------------\n** Documents source set on the command line is: ",args.source,"**")

# Check whether the specified path exists or not
isExist = os.path.exists(OUT_folder)
if not isExist:
   os.makedirs(OUT_folder)
   print(" ...data are outputed in: ",OUT_folder)

print ("---------\nRequesting documents from: ",src_target,"\n")
print ("  from:",century_L, " century to:", century_H," century")

# using the SRU service
print (" requesting all "+ type_target +" documents by filter: century")
for c in range(century_L,century_H+1):
  time.sleep(timeout)
  label = str(c)
  labels.append(label) # to build the chart later
  print ("... century: ", label)
  if provenance!="":
        prov = '%20and%20'+provenance
  else:
        prov=""
  if type_fr=="fascicule":
      search = '(dc.type%20all%20%22fascicule%22%20or%20dc.type%20all%20%22periodique%22)'+prov+'&filter=century%20all%20%22'+str(c)+'%22'
  else:
      search = '(dc.type%20all%20%22'+type_fr+'%22)'+prov+'&filter=century%20all%20%22'+str(c)+'%22'

  query = SRU + search
  print (query)
  searchs.append(search)
  centuries.append(label)
  try:
      page = requests.get(query) # Getting page HTML through request
      soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
      value=int(soup.find("numberOfRecords").get_text())
      result.append(value)
      print (value)
  except:
      print("Wow, ", sys.exc_info()[0], " occurred! Maybe a API error, try again!")
      # result.append(0) # SRU bug on Gallica century facet
      sys.exit(-1)

print (" ---------\n SRU sample query:", query)
print (" --------- raw data from the SRU API:\n" , result)

# adding empty values and sorting
#auto_complete(result)
#del_outliers(result)
#sorted_result = dict(sorted(result.items(), key=operator.itemgetter(0)))
dataset1 = np.array(result)

total_centuries = len(centuries)
total_f = sum(result)

# outputing data
collection['data'] = {}
collection['data']['query'] = {}
collection['data']['query']['sample_url'] = query
collection['data']['query']['date'] = str(date.today())
collection['data']['query']['collection'] = type_target
collection['data']['query']['collection_fr'] = type_fr
collection['data']['query']['source'] = src_target
collection['data']['query']['source_fr']= source_fr
collection['data']['query']['century'] = centuries
collection['data']['query']['search'] = searchs
collection['data']['query']['total_with_facet'] = int(total_f)
collection['data']['sru'] = result

print ("\n----\n  now querying the whole collection \n")
# asking for the whole number of documents (no date metadata)

if type_fr=="fascicule":
    search = '(dc.type%20all%20%22fascicule%22%20or%20dc.type%20all%20%22periodique%22)'
else:
    search = '(dc.type%20all%20%22'+type_fr+'%22)'
if provenance!="":
      search = search+'%20and%20'+provenance
query = SRU + search
print (query)
try:
    page = requests.get(query) # Getting page HTML through request
    soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
    result_tot= int(soup.find("numberOfRecords").get_text())
    print(result_tot)
    time.sleep(timeout)
except:
      print("Wow, ", sys.exc_info()[0], " occurred! Maybe a API error, try again!")
      #result_tot = 0
      sys.exit(-1)

collection['data']['query']['total_url'] = search
collection['data']['query']['total'] = result_tot

output_data(args.format,OUT,collection,src_target,"-"+type_target,"")

# if the type is not ocerized, quit properly
try:
    ocr_index = types_ocr.index(type_target)
except:
    sys.exit(0)


collection={}
searchs=[]
# OCRed documents
print ("\n----\n  now requesting OCRed documents by filter: century")
for c in range(century_L,century_H+1):
      label = str(c)
      print ("... century: ", label)
      if provenance!="":
            prov = '%20and%20'+provenance
      else:
            prov=""
      if type_fr=="fascicule":
          search = '(dc.type%20all%20%22fascicule%22%20or%20dc.type%20all%20%22periodique%22)%20and%20(ocr.quality%20all%20%22Texte%20disponible%22)'+prov+'&filter=century%20all%20%22'+str(c)+'%22'
      else:
          search = '(dc.type%20all%20%22'+type_fr+'%22)%20and%20(ocr.quality%20all%20%22Texte%20disponible%22)'+prov+'&filter=century%20all%20%22'+str(c)+'%22'
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
          #result_OCR.append(0) # SRU bug on century facet
          sys.exit(-1)
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
collection['data']['query']['collection'] = type_target
collection['data']['query']['collection_fr'] = type_fr
collection['data']['query']['source'] = src_target
collection['data']['query']['source_fr']= source_fr
collection['data']['query']['century'] = centuries
collection['data']['query']['search'] = searchs
#collection['data']['query']['facet_name'] = "century"
collection['data']['query']['ocr'] = 'y'
collection['data']['query']['total_with_facet'] = int(total_f)
collection['data']['sru'] = result_OCR

print (" ---------\n total documents facetted:", total_f)
print (" total documents:", result_tot)
print (" centuries:", total_centuries)

output_data(args.format,OUT,collection,src_target,"-"+type_target,"-ocr")

# just leave with OK exit code
if not(args.chart):
    sys.exit(0)

# building the chart
#labels = list(map(str, sorted_result.keys()))
dataset2 = np.array(result_OCR)
# we need to stack the 2 sets in the graph
dataset1 = dataset1 - dataset2 # documents with no OCR
total_1 = sum(dataset1)
total_2 = sum(dataset2)
#collection['OCRed']['query']['with_facet'] = int(total_2)
cover1 = "{:.1f}%".format((total_1/total_f)*100)
cover2 = "{:.1f}%".format((total_2/total_f)*100)
p1 = plt.bar(labels, dataset2, color="steelblue", label=type_target+" "+src_target+" avec OCR : \n"+ str(total_2)+ " sur "+ str(total_f)+" (océrisé à "+ cover2 +")") #https://matplotlib.org/stable/tutorials/colors/colormaps.html
p2 = plt.bar(labels, dataset1, bottom=dataset2, color="paleturquoise", label="sans OCR : "+ str(total_1)+ " sur "+ str(total_f)+" ("+ cover1 +")")

cover = "{:.1f}%".format((total_f/result_tot)*100)
plt.xlabel('siècles')
plt.ylabel('#documents')
plt.title('Gallica – Quantité de documents de type '+type_target+ " par siècles de publication \n Total avec facette 'century' : "+str(total_f)+' sur '+str(result_tot)+' ('+ cover+') - Source : API Gallica SRU')
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

plt.show()
sys.exit(0)
