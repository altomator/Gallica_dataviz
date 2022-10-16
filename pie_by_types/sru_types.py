# Query the Gallica SRU API to output documents quantities by types of document and source of collections
# Output data as XML and JSON files
# Create a chart (optionnal)
#  - pie if source = full
#  - donut if source /= full

# usage: python3 SRU_types.py [-source] source [-chart]
#  - source: full, gallica, bnf, partners, integrated, harvested (default=full)
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


def output_data(data, source):
    if args.format=="json":
        file_name=OUT+source+".json"
        print ("...writing in: ",file_name)
        # JSON serialisation
        json_string = json.dumps(data)
        with open(file_name, 'w') as outfile:
            outfile.write(json_string)
        outfile.close()
    else:
        file_name=OUT+source+".xml"
        print ("...writing in: ",file_name)
        # XML serialisation
        xml = dicttoxml(collection, attr_type=False)
        #encoding = 'utf-8'
        #str(xml, encoding)
        with open(file_name, 'w') as outfile:
            outfile.write(xml.decode("utf-8"))
        outfile.close()

parser = argparse.ArgumentParser()
parser.add_argument("-source","-s", default="full", help="Source of collection: full, gallica, bnf, partners, integrated, harvested")
parser.add_argument("-chart","-c", action="store_true", help="Produce a graph")
parser.add_argument("-format","-f", default="json", help="Data format (json, xml)")
args = parser.parse_args()


##################
OUT = "gallica_types_"
types=['periodical','monograph', 'image', 'object','manuscript', 'map', 'music score', 'sound','video']
types_fr=['fascicule','monographie', 'image', 'objet','manuscrit', 'carte', 'partition', 'sonore','video']
query=''
result=[]
result_p=[]
result_inner=[]
sources=[]
collection={}
total=0
total_p=0

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
elif args.source=="gallica": #  consultation = gallica (BnF + integrated)
    provenance = '%20and%20%28provenance%20adj%20%22bnf.fr%22%29'
    source_fr = 'BnF et intégrés'
elif args.source=="full": #  consultation = gallica (BnF + integrated)
    provenance = ''
    source_fr = 'complète'
else:
    print ("... argument -s (source of collection) must be: full, gallica, bnf, partners, integrated, harvested")
    quit()

print (" ---------\n** Documents source set on the command line is: ",args.source,"**")

# creating the chart legends
subgroup_names_legs=[]
if args.source=='full':
    for t in types:
        subgroup_names_legs.append(t)
else: # we are requesting all + another source
    for t in types:
        subgroup_names_legs.append(t+":autre")
        subgroup_names_legs.append(t+":"+source_fr)

#print(subgroup_names_legs)

# querying all documents
print ("---------\nQuerying the complete digital collection\n")
for t in types_fr:
  query = 'https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&query=(dc.type%20all%20%22'+t+'%22)&collapsing=false'
  try:
      page = requests.get(query) # Getting page HTML through request
      soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
      te=int(soup.find("numberOfRecords").get_text())
      print (" requesting", t,": ",te)
      total += te
      result.append(te)
  except:
      print("Wow, ", sys.exc_info()[0], " occurred!\n Maybe a API error, try again!")
      quit()

print (" ---------\n SRU query sample:", query)
print (" --------- raw data from the SRU API:\n" , result)

collection['data'] = {}
collection['data']['query'] = {}
collection['data']['query']['sample'] = query
collection['data']['query']['date'] = str(date.today())
collection['data']['query']['collection'] = types
collection['data']['query']['collection_fr'] = types_fr
collection['data']['query']['source'] = 'full'
collection['data']['query']['source_fr'] = 'complète'
collection['data']['query']['total'] = total
collection['data']['sru'] = result

output_data(collection, "full")

if args.source!='full':
    # querying partners documents
    collection={}
    print ("---------\nNow querying source:", args.source,"\n")
    i=0
    for t in types_fr:
        query = 'https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&query=(dc.type%20all%20%22'+t+'%22)'+provenance+'&collapsing=false'
        try:
            page = requests.get(query) # Getting page HTML through request
            soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
            te=int(soup.find("numberOfRecords").get_text())
            print (" requesting", t,": ",te)
            total_p += te
            # we build the data for the donut inner circle
            result_inner.append(result[i] - te) # all - partners
            result_inner.append(te) # partners
            result_p.append(te) # partners
            sources.append(' ')
            sources.append(("{:.1f}%".format(te/result[i]*100)) if te/result[i] > 0.05 else '')
            i+=1
        except:
            print("Wow, ", sys.exc_info()[0], " occurred!\n Maybe a API error, try again!")
            quit()
    print (" ---------\n SRU query sample:", query)
    print (" --------- raw data from the SRU API:\n" , result_p)
    collection['data'] = {}
    collection['data']['query'] = {}
    collection['data']['query']['sample'] = query
    collection['data']['query']['date'] = str(date.today())
    collection['data']['query']['collection'] = types
    collection['data']['query']['collection_fr'] = types_fr
    collection['data']['query']['source'] = args.source
    collection['data']['query']['source_fr'] = source_fr
    collection['data']['query']['total'] = total_p
    collection['data']['sru'] = result_p

    output_data(collection, args.source)

print (" ---------\n total documents:", total)

if not(args.chart):
    quit()

# creating a chart
NUM_TYPES = len(types_fr)

fig, ax = plt.subplots()
# color themes: https://matplotlib.org/api/pyplot_summary.html#colors-in-matplotlib
#bmap = plt.colormaps["tab20b"]
bmap = cm.get_cmap('tab20b')
cmap = cm.get_cmap("tab20c")
outer_colors = cmap(np.arange(5)*4)   # 5 color groups in tab20c
bouter_colors = bmap(np.arange(4)*4)  # 4 more color groups
nine_colors = np.concatenate((outer_colors,bouter_colors),axis=0)
cinner_colors = cmap([1, 2, 5, 6, 9, 10, 13, 14, 17, 18])
binner_colors = bmap([1, 2, 5, 6, 9, 10, 13, 14])
inner_colors = np.concatenate((cinner_colors,binner_colors), axis=0)

# outer circle
ax.axis('equal')
mypie, _ = ax.pie(result, radius=1.2,  colors=nine_colors, textprops={'fontsize': 11,'fontweight':'bold'})
plt.setp( mypie, width=0.7, edgecolor='white')

if args.source!='full':
    # Second Ring (inside)
    mypie2, _ = ax.pie(result_inner, radius=1.2-0.3,
    labels=sources, labeldistance=0.7, colors=inner_colors, textprops={'fontsize': 9})
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
    ax.annotate(types_fr[i]+" : {} ({:.1f}%)".format(result[i], result[i]/total*100), xy=(x, y), xytext=(1.35*np.sign(x), 1.4*y),
                horizontalalignment=horizontalalignment, fontsize=10,**kw)

if args.source!='full':
    plt.title('Gallica - Répartition des types de documents de source \''+source_fr+ "\', total : "+str(total_p)+' ('+"{:.1f}%".format(total_p/total*100)+')\nrelativ. à la collection complète, total : '+str(total)+' - Source : API Gallica SRU')
else:
    plt.title('Gallica - Répartition des types de documents, total : '+str(total)+' - Source : API Gallica SRU')

plt.show()


#colors = ['yellowgreen', 'gold', 'lightskyblue', 'lightcoral']
#plt.pie(result.values(), labels=types, colors=colors,
#        autopct='%1.1f%%', shadow=True, startangle=90)

#plt.axis('equal')

#plt.show()
