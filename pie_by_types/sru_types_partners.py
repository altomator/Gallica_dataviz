from bs4 import BeautifulSoup
import requests
import matplotlib.pyplot as plt
import json
import argparse
import numpy as np


def autopct_generator(limit):
    """Remove percent on small slices."""
    def inner_autopct(pct):
        return ('%.1f%%' % pct) if pct > limit else ''
    return inner_autopct


parser = argparse.ArgumentParser()
parser.add_argument("-source","-s", default="partners", help="source of collection: gallica, bnf, partners, integrated, harvested")
args = parser.parse_args()
print()

##################
OUT = "collections_ALL.json"
types=['fascicule','monographie', 'carte', 'manuscrit', 'partition','image', 'sonore', 'objet','video']
query=''
result=[]
result_p=[]
sources=[]
collection={}
total=0
total_p=0

OUT = "all_by_TYPES.json"
print ("...writing in: ",OUT)

# source of collections
if args.source=="partners": # source != bnf
    provenance = '%20and%20%28not%20dc.source%20adj%20%22Biblioth%C3%A8que%20nationale%20de%20France%22%29%20'
    source = 'partenaires'
elif args.source=="harvested": # source != bnf AND consultation = gallica
    provenance = '%20and%20%28not%20dc.source%20adj%20%22Biblioth%C3%A8que%20nationale%20de%20France%22%29%20and%20%28not%20provenance%20adj%20%22bnf.fr%22%29'
    source = 'moissonnés'
elif args.source=="integrated": # source != bnf AND consultation = gallica only (excluding harvested partners)
    provenance = '%20and%20%28not%20dc.source%20adj%20%22Biblioth%C3%A8que%20nationale%20de%20France%22%29%20and%20%28provenance%20adj%20%22bnf.fr%22%29'
    source = 'intégrés'
elif args.source=="bnf": # source = bnf AND consultation = gallica
        provenance = '%20and%20%28dc.source%20adj%20%22Biblioth%C3%A8que%20nationale%20de%20France%22%29%20and%20%28provenance%20adj%20%22bnf.fr%22%29'
        source = 'BnF'
elif args.source=="gallica": #  consultation = gallica (BnF + integrated)
    provenance = '%20and%20%28provenance%20adj%20%22bnf.fr%22%29'
    source = 'BnF et intégrés'
else:
    print ("... argument -s (source of collection) must be: gallica, bnf, partners, integrated, harvested")
    quit()


subgroup_names_legs=[]
for t in types:
    subgroup_names_legs.append(t+":autre")
    subgroup_names_legs.append(t+":"+source)

print(subgroup_names_legs)
#['mono:autre', 'mono:'+source, 'image:autre', 'image:'+source, 'manuscrit:autre', 'manuscrit:'+source,'carte:autre', 'carte:'+source, 'fascicule:autre', 'fascicule:'+source]


# querying all documents
print ("---------\nQuerying all documents\n")
for t in types:
  print (" requesting:", t)
  query = 'https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&query=(dc.type%20all%20%22'+t+'%22)&collapsing=false'
  page = requests.get(query) # Getting page HTML through request
  soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
  te=int(soup.find("numberOfRecords").get_text())
  print (te)
  total += te
  result.append(te)

collection['all'] = {}
collection['all']['query'] = {}
collection['all']['query']['sample'] = query
collection['all']['query']['date'] = "2022/31/01"
collection['all']['query']['source'] = 'all'
collection['all']['query']['total'] = total
collection['all']['data'] = result

# querying partners documents
print ("---------\nQuerying source:", source,"\n")
i=0
for t in types:
  print ("  requesting: ", t)
  query = 'https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&query=(dc.type%20all%20%22'+t+'%22)'+provenance+'&collapsing=false'
  page = requests.get(query) # Getting page HTML through request
  soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
  te=int(soup.find("numberOfRecords").get_text())
  print (te)
  total_p += te
  result_p.append(result[i] - te) # all - partners
  result_p.append(te)
  sources.append(' ')
  sources.append(("{:.1f}%".format(te/result[i]*100)) if te/result[i] > 0.05 else '')
  i+=1
print(result_p)

collection['partners'] = {}
collection['partners']['query'] = {}
collection['partners']['query']['sample'] = query
collection['partners']['query']['date'] = "2022/31/01"
collection['partners']['query']['source'] = source
collection['partners']['query']['total'] = total_p
collection['partners']['data'] = result_p

json_string = json.dumps(collection)
with open(OUT, 'w') as outfile:
    outfile.write(json_string)
outfile.close()

print (" ---------\n total documents:", total)


NUM_TYPES = len(types)
# set color theme
# https://matplotlib.org/api/pyplot_summary.html#colors-in-matplotlib
fig, ax = plt.subplots()
bmap = plt.colormaps["tab20b"]
cmap = plt.colormaps["tab20c"]
outer_colors = cmap(np.arange(5)*4)   # 5 color groups in tab20c
bouter_colors = bmap(np.arange(4)*4)  # 4 more color groups
nine_colors = np.concatenate((outer_colors,bouter_colors),axis=0)
cinner_colors = cmap([1, 2, 5, 6, 9, 10, 13, 14, 17, 18])
binner_colors = bmap([1, 2, 5, 6, 9, 10, 13, 14])
inner_colors = np.concatenate((cinner_colors,binner_colors), axis=0)

# outer circle
ax.axis('equal')
mypie, _ = ax.pie(result, radius=1.2,  colors=nine_colors, textprops={'fontsize': 10,'fontweight':'bold'})
plt.setp( mypie, width=0.5, edgecolor='white')

# Second Ring (inside): all - partners
mypie2, _ = ax.pie(result_p, radius=1.2-0.3,
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
    ax.annotate(types[i]+" ({:.1f}%)".format(result[i]/total*100), xy=(x, y), xytext=(1.35*np.sign(x), 1.4*y),
                horizontalalignment=horizontalalignment, **kw)

plt.title('Part des collections de source \''+source+ "\', total : "+str(total_p)+' ('+"{:.1f}%".format(total_p/total*100)+')\nrelativ. à la collection complète, total : '+str(total)+' - Source : API Gallica SRU')
plt.show()


#colors = ['yellowgreen', 'gold', 'lightskyblue', 'lightcoral']
#plt.pie(result.values(), labels=types, colors=colors,
#        autopct='%1.1f%%', shadow=True, startangle=90)

#plt.axis('equal')

#plt.show()
