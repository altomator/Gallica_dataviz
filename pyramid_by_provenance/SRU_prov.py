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


# importing constants and vars
sys.path.append(os.path.abspath("/Users/bnf/Documents/BnF/Dev/Dataviz/Gallica-médiation des collections/_python_stuff"))
from dataviz import *

##################
# output folder
##################
OUT = "gallica_prov_"

# overwritting values from default (cf. dataviz package)
sources_coll=['BnF', 'integrated', 'harvested' ]
sources_coll_fr=['BnF', 'intégrés', 'moissonnés' ]
queries_coll=[
'%20%28dc.source%20adj%20%22Biblioth%C3%A8que%20nationale%20de%20France%22%29%20and%20%28provenance%20adj%20%22bnf.fr%22%29',
'%20%28not%20dc.source%20adj%20%22Biblioth%C3%A8que%20nationale%20de%20France%22%29%20and%20%28provenance%20adj%20%22bnf.fr%22%29',
'%20%28not%20dc.source%20adj%20%22Biblioth%C3%A8que%20nationale%20de%20France%22%29%20and%20%28not%20provenance%20adj%20%22bnf.fr%22%29'
]


### MAIN ###
parser = argparse.ArgumentParser()
parser.add_argument("-format","-f", default="json", help="Data format (json, xml)")
args = parser.parse_args()

# Check whether the specified path exists or not
isExist = os.path.exists(OUT_folder)
if not isExist:
   os.makedirs(OUT_folder)
   print("...Data are outputed in: ",OUT_folder)

print ("---------\nQuerying the digital collection by provenance\n")
for index,q in enumerate (queries_coll):
  query = SRU + q
  #print (query)
  print(" ...processing collection: \033[7m",sources_coll_fr[index],"\033[m")
  try:
      page = requests.get(query) # Getting page HTML through request
      soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
      te=int(soup.find("numberOfRecords").get_text())
      print (" requesting", q)
      print(te)
      total += te
      result_all.append(te)
  except:
      print("Wow, ", sys.exc_info()[0], " occurred!\n Maybe a API error, try again!")
      sys.exit(-1)
      #quit()

print (" --------- raw data from the SRU API:\n" , result_all)

collection['data'] = {}
collection['data']['query'] = {}
collection['data']['query']['sample_url'] = query
collection['data']['query']['date'] = str(date.today())
collection['data']['query']['collection'] = sources_coll
collection['data']['query']['collection_fr'] = sources_coll_fr
collection['data']['query']['source'] = "full"
collection['data']['query']['source_fr'] = "tout"
collection['data']['query']['search'] = queries_coll
collection['data']['query']['total'] = total
collection['data']['sru'] = result_all

output_data(args.format,OUT,collection,"full","","")
print (" ---------\n total documents:", total)

collection={}
result=[]
total=0
print ("---------\nQuerying the BnF digital collections \n")
for index,q in enumerate(bnf_queries):
  query = SRU+q
  #print (query)
  print(" ...processing dpt: \033[7m",bnf_fr[index],"\033[m")
  try:
      page = requests.get(query) # Getting page HTML through request
      soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
      te=int(soup.find("numberOfRecords").get_text())
      print (" requesting", q,": ",te)
      total += te
      result.append(te)
  except:
      print("Wow, ", sys.exc_info()[0], " occurred!\n Maybe a API error, try again!")
      sys.exit(-1)

collection['data'] = {}
collection['data']['query'] = {}
collection['data']['query']['sample_url'] = query
collection['data']['query']['date'] = str(date.today())
collection['data']['query']['collection'] = bnf
collection['data']['query']['collection_fr'] = bnf_fr
collection['data']['query']['source'] = sources_coll[0]
collection['data']['query']['source_fr'] = sources_coll_fr[0]
collection['data']['query']['search'] = bnf_queries
collection['data']['query']['total_url'] = queries_coll[0]
collection['data']['query']['total'] = total
result.append(result_all[0]-total) # the whole - the dpts
collection['data']['sru'] = result

print (" --------- data:\n" , result)
output_data(args.format,OUT,collection,"bnf","","")
print (" ---------\n total documents:", total)

collection={}
result=[]
total=0
print ("---------\nQuerying the digital collection for integrated partners\n")
for index,q in enumerate(integrated_queries):
  query = SRU+q
  print(" ...processing partner: \033[7m",integrated_fr[index],"\033[m")
  try:
      page = requests.get(query) # Getting page HTML through request
      soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
      te=int(soup.find("numberOfRecords").get_text())
      print (" requesting", q,": ",te)
      total += te
      result.append(te)
  except:
      print("Wow, ", sys.exc_info()[0], " occurred!\n Maybe a API error, try again!")
      sys.exit(-1)

collection['data'] = {}
collection['data']['query'] = {}
collection['data']['query']['sample_url'] = query
collection['data']['query']['date'] = str(date.today())
collection['data']['query']['collection'] = integrated
collection['data']['query']['collection_fr'] = integrated_fr
collection['data']['query']['source'] = sources_coll[1]
collection['data']['query']['source_fr'] = sources_coll_fr[1]
collection['data']['query']['search'] = integrated_queries
collection['data']['query']['total_url'] = queries_coll[1]
collection['data']['query']['total'] = total
result.append(result_all[1]-total) # the sub-collection minus the top 10 integrated partners' collections
collection['data']['sru'] = result

print (" --------- data:\n" , result)
output_data(args.format,OUT,collection,"integrated","","")

print (" ---------\n total documents:", total)

collection={}
result=[]
total=0
print ("---------\nQuerying the digital collection for harvested partners\n")
for index,q in enumerate(harvested_queries):
  query = SRU+q
  print(" ...processing partner: \033[7m",harvested_fr[index],"\033[m")
  try:
      page = requests.get(query) # Getting page HTML through request
      soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
      te=int(soup.find("numberOfRecords").get_text())
      print (" requesting", q,": ",te)
      total += te
      result.append(te)
  except:
      print("Wow, ", sys.exc_info()[0], " occurred!\n Maybe a API error, try again!")
      sys.exit(-1)

collection['data'] = {}
collection['data']['query'] = {}
collection['data']['query']['sample_url'] = query
collection['data']['query']['date'] = str(date.today())
collection['data']['query']['collection'] = harvested
collection['data']['query']['collection_fr'] = harvested_fr
collection['data']['query']['source'] = sources_coll[2]
collection['data']['query']['source_fr'] = sources_coll_fr[2]
collection['data']['query']['search'] = harvested_queries
collection['data']['query']['total_url'] = queries_coll[2]
collection['data']['query']['total'] = total
result.append(result_all[2]-total) # the sub-collection minus the top 10 harvested partners' collections
collection['data']['sru'] = result

print (" --------- data:\n" , result)
output_data(args.format,OUT,collection,"harvested","","")

print (" ---------\n total documents:", total)
sys.exit(0)
