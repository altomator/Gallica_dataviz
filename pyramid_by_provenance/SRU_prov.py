# Query the Gallica SRU API to output documents quantities by provenance of collections
# Output data as XML or JSON files

# usage: python3 SRU_prov.py [-f] format



from bs4 import BeautifulSoup
import requests
import matplotlib.pyplot as plt
import json
import argparse
import sys
import numpy as np
from datetime import date
from dicttoxml import dicttoxml
from matplotlib import cm
import os

##################
SRU = "https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&collapsing=false&query="
OUT_folder = "data/"
OUT = "gallica_prov_"
types=['BnF', 'integrated', 'harvested' ]
types_fr=['BnF', 'intégrés', 'moissonnés' ]
queries=[
'%20%28dc.source%20adj%20%22Biblioth%C3%A8que%20nationale%20de%20France%22%29%20and%20%28provenance%20adj%20%22bnf.fr%22%29',
'%20%28not%20dc.source%20adj%20%22Biblioth%C3%A8que%20nationale%20de%20France%22%29%20and%20%28provenance%20adj%20%22bnf.fr%22%29',
'%20%28not%20dc.source%20adj%20%22Biblioth%C3%A8que%20nationale%20de%20France%22%29%20and%20%28not%20provenance%20adj%20%22bnf.fr%22%29'
]
bnf_queries=[
'%20%28dc.source%20adj%20%22Biblioth%C3%A8que%20nationale%20de%20France%22%29%20and%20%28provenance%20adj%20%22bnf.fr%22%29',
]
bnf=[
'Bibliothèque nationale de France',
'autres'
]
integrated_queries=[
'%20%28bibliotheque%20adj%20%22Bibliothèque%20nationale%20et%20universitaire%20de%20Strasbourg%22%29',
'%20%28bibliotheque%20adj%20%22Bibliothèque%20du%20Sénat%22%29',
'%20%28bibliotheque%20adj%20%22Bibliothèque%20et%20Archives%20de%20l%27Assemblée%20nationale%22%29'
]
integrated=[
"Bibliothèque nationale et universitaire de Strasbourg",
"Bibliothèque du Sénat",
"Bibliothèque et Archives de l'Assemblée nationale",
'autres'
]
harvested_queries=[
'%20%28provenance%20adj%20%22ville-paris%22%29',
'%20%28provenance%20adj%20%22bvh.univtours.fr%22%29'
]
harvested=[
"Bibliothèques spécialisées de la Ville de Paris",
"Bibliothèques virtuelles humanistes",
'autres'
]
query=''
result=[]
result_all=[]
collection={}
total=0
total_p=0

def output_data(data, source):
    if args.format=="json":
        file_name=OUT_folder+OUT+source+".json"
        print ("...writing in: ",file_name)
        # JSON serialisation
        json_string = json.dumps(data)
        with open(file_name, 'w') as outfile:
            outfile.write(json_string)
        outfile.close()
    else:
        file_name=OUT_folder+OUT+source+".xml"
        print ("...writing in: ",file_name)
        # XML serialisation
        xml = dicttoxml(collection, attr_type=False)
        #encoding = 'utf-8'
        #str(xml, encoding)
        with open(file_name, 'w') as outfile:
            outfile.write(xml.decode("utf-8"))
        outfile.close()

parser = argparse.ArgumentParser()
parser.add_argument("-format","-f", default="json", help="Data format (json, xml)")
args = parser.parse_args()


# Check whether the specified path exists or not
isExist = os.path.exists(OUT_folder)
if not isExist:
   os.makedirs(OUT_folder)
   print("...Data are outputed in: ",OUT_folder)


print ("---------\nQuerying the digital collection by provenance\n")
for q in queries:
  query = SRU+q
  #print (query)
  try:
      page = requests.get(query) # Getting page HTML through request
      soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
      te=int(soup.find("numberOfRecords").get_text())
      print (" requesting", q,": ",te)
      total += te
      result_all.append(te)
  except:
      print("Wow, ", sys.exc_info()[0], " occurred!\n Maybe a API error, try again!")
      quit()

print (" --------- raw data from the SRU API:\n" , result_all)

collection['data'] = {}
collection['data']['query'] = {}
collection['data']['query']['sample_url'] = query
collection['data']['query']['date'] = str(date.today())
collection['data']['query']['source'] = types
collection['data']['query']['source_fr'] = types_fr
collection['data']['query']['search'] = queries
collection['data']['query']['total'] = total
collection['data']['sru'] = result_all

output_data(collection,"full")
print (" ---------\n total documents:", total)

collection={}
result=[]
total=0
print ("---------\nQuerying the BnF digital collection \n")
for q in bnf_queries:
  query = SRU+q
  print (query)
  try:
      page = requests.get(query) # Getting page HTML through request
      soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
      te=int(soup.find("numberOfRecords").get_text())
      print (" requesting", q,": ",te)
      total += te
      result.append(te)
  except:
      print("Wow, ", sys.exc_info()[0], " occurred!\n Maybe a API error, try again!")
      quit()

print (" --------- raw data from the SRU API:\n" , result)

collection['data'] = {}
collection['data']['query'] = {}
collection['data']['query']['sample_url'] = query
collection['data']['query']['date'] = str(date.today())
collection['data']['query']['source'] = bnf
collection['data']['query']['source_fr'] = bnf
collection['data']['query']['search'] = bnf_queries
collection['data']['query']['total'] = total
result.append(0) # other = 0
collection['data']['sru'] = result

output_data(collection,"bnf")
print (" ---------\n total documents:", total)

collection={}
result=[]
total=0
print ("---------\nQuerying the digital collection for integrated partners\n")
for q in integrated_queries:
  query = SRU+q
  print (query)
  try:
      page = requests.get(query) # Getting page HTML through request
      soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
      te=int(soup.find("numberOfRecords").get_text())
      print (" requesting", q,": ",te)
      total += te
      result.append(te)
  except:
      print("Wow, ", sys.exc_info()[0], " occurred!\n Maybe a API error, try again!")
      quit()

print (" --------- raw data from the SRU API:\n" , result)

collection['data'] = {}
collection['data']['query'] = {}
collection['data']['query']['sample_url'] = query
collection['data']['query']['date'] = str(date.today())
collection['data']['query']['source'] = integrated
collection['data']['query']['source_fr'] = integrated
collection['data']['query']['search'] = integrated_queries
collection['data']['query']['total'] = total
result.append(result_all[1]-total) # the sub-collection minus the top 10 integrated partners' collections
collection['data']['sru'] = result

output_data(collection,"integrated")
print (" ---------\n total documents:", total)

collection={}
result=[]
total=0
print ("---------\nQuerying the digital collection for harvested partners\n")
for q in harvested_queries:
  query = SRU+q
  print (query)
  try:
      page = requests.get(query) # Getting page HTML through request
      soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
      te=int(soup.find("numberOfRecords").get_text())
      print (" requesting", q,": ",te)
      total += te
      result.append(te)
  except:
      print("Wow, ", sys.exc_info()[0], " occurred!\n Maybe a API error, try again!")
      quit()

print (" --------- raw data from the SRU API:\n" , result)

collection['data'] = {}
collection['data']['query'] = {}
collection['data']['query']['sample_url'] = query
collection['data']['query']['date'] = str(date.today())
collection['data']['query']['source'] = harvested
collection['data']['query']['source_fr'] = harvested
collection['data']['query']['search'] = harvested_queries
collection['data']['query']['total'] = total
result.append(result_all[2]-total) # the sub-collection minus the top 10 harvested partners' collections
collection['data']['sru'] = result

output_data(collection,"harvested")
print (" ---------\n total documents:", total)
