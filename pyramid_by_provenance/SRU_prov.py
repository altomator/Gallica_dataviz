# Query the Gallica SRU API to output documents quantities by provenance of collections
# Output data as XML and JSON files

# usage: python3 SRU_colls.py [-source] source [-chart]
#  - chart


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
OUT_folder = "data/"
OUT = "gallica_prov"
types=['BnF', 'integrated', 'harvested' ]
types_fr=['BnF', 'intégrés', 'moissonnés' ]
queries=[
'%20%28dc.source%20adj%20%22Biblioth%C3%A8que%20nationale%20de%20France%22%29%20and%20%28provenance%20adj%20%22bnf.fr%22%29',
'%20%28not%20dc.source%20adj%20%22Biblioth%C3%A8que%20nationale%20de%20France%22%29%20and%20%28provenance%20adj%20%22bnf.fr%22%29',
'%20%28not%20dc.source%20adj%20%22Biblioth%C3%A8que%20nationale%20de%20France%22%29%20and%20%28not%20provenance%20adj%20%22bnf.fr%22%29'
]
query=''
result=[]
result_p=[]
result_inner=[]
collection={}
total=0
total_p=0

def output_data(data):
    if args.format=="json":
        file_name=OUT_folder+OUT+".json"
        print ("...writing in: ",file_name)
        # JSON serialisation
        json_string = json.dumps(data)
        with open(file_name, 'w') as outfile:
            outfile.write(json_string)
        outfile.close()
    else:
        file_name=OUT_folder+OUT+".xml"
        print ("...writing in: ",file_name)
        # XML serialisation
        xml = dicttoxml(collection, attr_type=False)
        #encoding = 'utf-8'
        #str(xml, encoding)
        with open(file_name, 'w') as outfile:
            outfile.write(xml.decode("utf-8"))
        outfile.close()

parser = argparse.ArgumentParser()
parser.add_argument("-chart","-c", action="store_true", help="Produce a graph")
parser.add_argument("-format","-f", default="json", help="Data format (json, xml)")
args = parser.parse_args()


# Check whether the specified path exists or not
isExist = os.path.exists(OUT_folder)
if not isExist:
   os.makedirs(OUT_folder)
   print("...Data are outputed in: ",OUT_folder)


print ("---------\nQuerying the digital collection by provenance\n")
for q in queries:
  query = 'https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&query='+q+'&collapsing=false'
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
collection['data']['query']['sample'] = query
collection['data']['query']['date'] = str(date.today())
collection['data']['query']['source'] = types
collection['data']['query']['source_fr'] = types_fr
collection['data']['query']['total'] = total
collection['data']['sru'] = result

output_data(collection)

print (" ---------\n total documents:", total)
