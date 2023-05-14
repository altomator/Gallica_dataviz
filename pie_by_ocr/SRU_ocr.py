from bs4 import BeautifulSoup
import requests
import matplotlib.pyplot as plt
import json
import argparse
import sys
import numpy as np
from datetime import date
import os
from matplotlib import cm
from dicttoxml import dicttoxml
import time

##################
# output folder
##################
OUT = "gallica_ocr_"

args = ""

# time out between calls to the API
timeout=1

# importing constants and vars
sys.path.append(os.path.abspath("/Users/bnf/Documents/BnF/Dev/Dataviz/Gallica-médiation des collections/_python_stuff"))
from dataviz import *

# overwritting values from dataviz.py
types=['periodical','monograph', 'manuscript',  'music score']
types_fr=['fascicule','monographie', 'manuscrit', 'partition']

sources_labels=[]


# MAIN #
print ("##################################################")
parser = argparse.ArgumentParser()
parser.add_argument("-source","-s", default="full", help="Source of collection: "+' '.join(sources_coll))
parser.add_argument("-chart","-c", action="store_true", help="Produce a graph")
parser.add_argument("-format","-f", default="json", help="Data format (json, xml)")
args = parser.parse_args()


#print ("---------------------------------\n** Documents source set on the command line is: ",args.source,"**")

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

# Check whether the specified path exists or not
isExist = os.path.exists(OUT_folder)
if not isExist:
   os.makedirs(OUT_folder)
   print("...data are outputed in: ",OUT_folder)

subgroup_names_legs=[]
for t in types:
    subgroup_names_legs.append(t+" : sans ocr")
    subgroup_names_legs.append(t+" : avec ocr")

#['mono:autre', 'mono:'+source, 'image:autre', 'image:'+source, 'manuscrit:autre', 'manuscrit:'+source,'carte:autre', 'carte:'+source, 'fascicule:autre', 'fascicule:'+source]

# querying all documents
print ("---------\nQuerying the digital collection from source: \033[7m", src_target,"\033[m\n")
for t in types_fr:
  print (" requesting type:", t)
  if t=="fascicule": # bug Galica : two criteria depending if we're dealing with harvested partners or not
        search = '(dc.type%20all%20%22fascicule%22%20or%20dc.type%20all%20%22periodique%22)'
  else:
        search = '(dc.type%20all%20%22'+t+'%22)'
  if provenance!="":
        search = search+'%20and%20'+provenance
  query = SRU+search
  print(query)
  time.sleep(timeout)
  try:
      page = requests.get(query) # Getting page HTML through request
      soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
      te=int(soup.find("numberOfRecords").get_text())
      print (te)
      total += te
      searchs.append(search)
      result.append(te)
  except:
      print("Wow, ", sys.exc_info()[0], " occurred!\n Maybe a API error, try again!")
      sys.exit(-1)

print (" ---------\n SRU query sample:", query)
print (" --------- raw data from the SRU API:\n" , result)
collection['data'] = {}
collection['data']['query'] = {}
collection['data']['query']['sample_url'] = query
collection['data']['query']['date'] = str(date.today())
collection['data']['query']['collection'] = types
collection['data']['query']['collection_fr'] = types_fr
collection['data']['query']['source'] = src_target
collection['data']['query']['source_fr'] = source_fr
collection['data']['query']['search'] = searchs
collection['data']['query']['total'] = total
collection['data']['sru'] = result

print (" ---------\n total documents:", total)

output_data(args.format,OUT,collection,src_target,"","")



collection={}
searchs=[]
# querying OCRed documents
print ("---------\nNow querying OCRed documents from source: \033[7m", src_target,"\033[m\n")
i=0
for t in types_fr:
  print ("  requesting: ", t)
  if t=="fascicule": # bug Galica : two criteria depending if we're dealing with harvested partners or not
        search = '(dc.type%20all%20%22fascicule%22%20or%20dc.type%20all%20%22periodique%22)%20and%20(ocr.quality%20all%20%22Texte%20disponible%22)'
  else:
        search = '(dc.type%20all%20%22'+t+'%22)%20and%20(ocr.quality%20all%20%22Texte%20disponible%22)'
  if provenance!="":
      search = search+'%20and%20'+provenance
  query = SRU+search
  print(query)
  time.sleep(timeout)
  try:
      page = requests.get(query) # Getting page HTML through request
      soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
      te=int(soup.find("numberOfRecords").get_text())
      print (te)
      total_OCR += te
      searchs.append(search) # ocred
      result_OCR.append(result[i] - te) # all - ocred = no OCR
      result_OCR.append(te)
      sources_labels.append(' ')
      sources_labels.append(("OCR: \n{:.1f}%".format(te/result[i]*100)) if te/result[i] > 0.05 else '')
      i+=1
  except:
      print("Wow, ", sys.exc_info()[0], " occurred!\n Maybe a API error, try again!")
      sys.exit(-1)

print (" ---------\n SRU query sample:", query)
print (" --------- raw data from the SRU API:\n" , result_OCR)


if provenance!="":
    total_search = '(ocr.quality%20all%20%22Texte%20disponible%22)'
else:
    total_search = '(ocr.quality%20all%20%22Texte%20disponible%22)%20and%20' + provenance
collection['data'] = {}
collection['data']['query'] = {}
collection['data']['query']['sample_url'] = query
collection['data']['query']['total_url'] =  total_search
collection['data']['query']['date'] = str(date.today())
collection['data']['query']['collection'] = types
collection['data']['query']['collection_fr'] = types_fr
collection['data']['query']['source'] = src_target
collection['data']['query']['source_fr'] = source_fr
collection['data']['query']['search'] = searchs
collection['data']['query']['ocr'] = 'y'
collection['data']['query']['total'] = total_OCR
collection['data']['sru'] = result_OCR

print (" ---------\n total documents with OCR:", total_OCR)

output_data(args.format,OUT,collection,src_target,"","-ocr")



if not(args.chart):
    sys.exit(0)

########### PIE ##############
NUM_TYPES = len(types)
# set color theme
# https://matplotlib.org/api/pyplot_summary.html#colors-in-matplotlib
fig, ax = plt.subplots()
bmap = cm.get_cmap('tab20b')
cmap = cm.get_cmap("tab20c")
outer_colors = cmap(np.arange(4)*4)   # 4 color groups in tab20c
inner_colors = cmap([2, 1, 6, 5, 10, 9, 14, 13])

# outer circle
ax.axis('equal')
mypie, _ = ax.pie(result, radius=1.2,  colors=outer_colors, textprops={'fontsize': 10,'fontweight':'bold'})
plt.setp( mypie, width=0.5, edgecolor='white')

# Second Ring (inside): all - partners
mypie2, _ = ax.pie(result_OCR, radius=1.2-0.3,
labels=sources_labels, labeldistance=0.7, colors=inner_colors, textprops={'fontsize': 8,'fontweight':'bold'})
plt.setp( mypie2, width=0.7, edgecolor='white')
plt.margins(0,0)

bbox_props = dict(boxstyle="square,pad=0.2", fc="w", ec="k", lw=0.72)
kw = dict(arrowprops=dict(arrowstyle="-"),
          bbox=bbox_props, zorder=0, va="center")

handles, labels = ax.get_legend_handles_labels()
ax.legend(handles, subgroup_names_legs, loc='best', fontsize=8)

for i, p in enumerate(mypie):
    ang = (p.theta2 - p.theta1)/2. + p.theta1
    y = np.sin(np.deg2rad(ang))
    x = np.cos(np.deg2rad(ang))
    horizontalalignment = {-1: "right", 1: "left"}[int(np.sign(x))]
    connectionstyle = "angle,angleA=0,angleB={}".format(ang)
    kw["arrowprops"].update({"connectionstyle": connectionstyle})
    ax.annotate(types[i]+" : \n{:.1f}% ({})".format(result[i]/total*100,result[i]), xy=(x, y), xytext=(1.35*np.sign(x), 1.4*y),
                horizontalalignment=horizontalalignment, **kw)

plt.title('Part des collections océrisées \''+source_fr+ "\', total : "+str(total_OCR)+' ('+"{:.1f}%".format(total_OCR/total*100)+')\nrelativ. à la collection textuelle, total : '+str(total)+' - Source : API Gallica SRU')
plt.show()


#colors = ['yellowgreen', 'gold', 'lightskyblue', 'lightcoral']
#plt.pie(result.values(), labels=types, colors=colors,
#        autopct='%1.1f%%', shadow=True, startangle=90)

#plt.axis('equal')

#plt.show()
