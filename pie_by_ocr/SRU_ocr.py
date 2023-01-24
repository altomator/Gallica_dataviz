from bs4 import BeautifulSoup
import requests
import matplotlib.pyplot as plt
import json
import argparse
import numpy as np
from datetime import date
import os
from matplotlib import cm
from dicttoxml import dicttoxml

##################
SRU = "https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&collapsing=false&query="
OUT_folder = "data/"
OUT = "gallica_ocr_"
types=['periodical','monograph', 'manuscript',  'music score']
types_fr=['fascicule','monographie', 'manuscrit', 'partition']
query=''
result=[]
result_p=[]
sources=[]
searchs=[]
collection={}
total=0
total_p=0


def output_data(data, type, ocr):
    if args.format=="json":
        file_name=OUT_folder+OUT+type+ocr+".json"
        print ("...writing in: ",file_name)
        # JSON serialisation
        json_string = json.dumps(data)
        with open(file_name, 'w') as outfile:
            outfile.write(json_string)
        outfile.close()
    else:
        file_name=OUT_folder+OUT+type+ocr+".xml"
        print ("...writing in: ",file_name)
        # XML serialisation
        xml = dicttoxml(collection, attr_type=False)
        #encoding = 'utf-8'
        #str(xml, encoding)
        with open(file_name, 'w') as outfile:
            outfile.write(xml.decode("utf-8"))
        outfile.close()

parser = argparse.ArgumentParser()
parser.add_argument("-source","-s", default="full", help="Source of collection: full, bnf_and_integrated, bnf, partners, integrated, harvested")
parser.add_argument("-chart","-c", action="store_true", help="Produce a graph")
parser.add_argument("-format","-f", default="json", help="Data format (json, xml)")
args = parser.parse_args()

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

print ("-------------------------------------\n----------\n** Documents source set on the command line is: ",args.source,"**")


# Check whether the specified path exists or not
isExist = os.path.exists(OUT_folder)
if not isExist:
   os.makedirs(OUT_folder)
   print("...Data are outputed in: ",OUT_folder)

subgroup_names_legs=[]
for t in types:
    subgroup_names_legs.append(t+" : sans ocr")
    subgroup_names_legs.append(t+" : avec ocr")

#['mono:autre', 'mono:'+source, 'image:autre', 'image:'+source, 'manuscrit:autre', 'manuscrit:'+source,'carte:autre', 'carte:'+source, 'fascicule:autre', 'fascicule:'+source]

# querying all documents
print ("---------\nQuerying the digital collection\n")
for t in types_fr:
  print (" requesting:", t)
  if t=="fascicule": # bug Galica : two criteria depending if we're dealing with harvested partners or not
        search = '(dc.type%20all%20%22fascicule%22%20or%20dc.type%20all%20%22periodique%22)'+provenance
  else:
        search = '(dc.type%20all%20%22'+t+'%22)'+provenance
  query = SRU+search
  #print(query)
  page = requests.get(query) # Getting page HTML through request
  soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
  te=int(soup.find("numberOfRecords").get_text())
  print (te)
  total += te
  searchs.append(search)
  result.append(te)

print (" ---------\n SRU query sample:", query)
print (" --------- raw data from the SRU API:\n" , result)
collection['data'] = {}
collection['data']['query'] = {}
collection['data']['query']['sample_url'] = query
collection['data']['query']['total_url'] = provenance
collection['data']['query']['date'] = str(date.today())
collection['data']['query']['collection'] = types
collection['data']['query']['collection_fr'] = types_fr
collection['data']['query']['source'] = args.source
collection['data']['query']['source_fr'] = source_fr
collection['data']['query']['search'] = searchs
collection['data']['query']['total'] = total
collection['data']['sru'] = result

output_data(collection, args.source,"")
print (" ---------\n total documents:", total)

collection={}
searchs=[]

# querying OCRed documents
print ("---------\nNow querying OCRed documents from source:", args.source,"\n")
i=0
for t in types_fr:
  print ("  requesting: ", t)
  if t=="fascicule": # bug Galica : two criteria depending if we're dealing with harvested partners or not
        search = '(dc.type%20all%20%22fascicule%22%20or%20dc.type%20all%20%22periodique%22)%20and%20(ocr.quality%20all%20%22Texte%20disponible%22)'+provenance
  else:
        search = '(dc.type%20all%20%22'+t+'%22)%20and%20(ocr.quality%20all%20%22Texte%20disponible%22)'+provenance
  query = SRU+search
  page = requests.get(query) # Getting page HTML through request
  soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
  te=int(soup.find("numberOfRecords").get_text())
  print (te)
  total_p += te
  searchs.append(search) # ocred
  result_p.append(result[i] - te) # all - ocred = no OCR
  result_p.append(te)
  sources.append(' ')
  sources.append(("OCR: \n{:.1f}%".format(te/result[i]*100)) if te/result[i] > 0.05 else '')
  i+=1
print (" ---------\n SRU query sample:", query)
print (" --------- raw data from the SRU API:\n" , result_p)

collection['data'] = {}
collection['data']['query'] = {}
collection['data']['query']['sample_url'] = query
collection['data']['query']['total_url'] = '(ocr.quality%20all%20%22Texte%20disponible%22)%20and%20' + provenance
collection['data']['query']['date'] = str(date.today())
collection['data']['query']['collection'] = types
collection['data']['query']['collection_fr'] = types_fr
collection['data']['query']['source'] = args.source
collection['data']['query']['source_fr'] = source_fr
collection['data']['query']['search'] = searchs
collection['data']['query']['ocr'] = 'y'
collection['data']['query']['total'] = total_p
collection['data']['sru'] = result_p

output_data(collection, args.source, "_ocr")

print (" ---------\n total documents:", total_p)

if not(args.chart):
    quit()

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
mypie2, _ = ax.pie(result_p, radius=1.2-0.3,
labels=sources, labeldistance=0.7, colors=inner_colors, textprops={'fontsize': 8,'fontweight':'bold'})
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

plt.title('Part des collections océrisées \''+source_fr+ "\', total : "+str(total_p)+' ('+"{:.1f}%".format(total_p/total*100)+')\nrelativ. à la collection textuelle, total : '+str(total)+' - Source : API Gallica SRU')
plt.show()


#colors = ['yellowgreen', 'gold', 'lightskyblue', 'lightcoral']
#plt.pie(result.values(), labels=types, colors=colors,
#        autopct='%1.1f%%', shadow=True, startangle=90)

#plt.axis('equal')

#plt.show()
