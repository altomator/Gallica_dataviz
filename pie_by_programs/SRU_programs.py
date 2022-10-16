# Query the Gallica SRU API to output documents quantities by digitization program and types of documents
# Output data as XML and JSON files
# Create a chart (optional)

# usage: python3 SRU_programs.py [-type] type [-chart]
#  - type: monographie, fascicule
#  - chart


from bs4 import BeautifulSoup
import requests
import matplotlib.pyplot as plt
import json
import argparse
import numpy as np
from datetime import date
from matplotlib import cm


def autopct_generator(limit):
    """Remove percent on small slices."""
    def inner_autopct(pct):
        return ('%.1f%%' % pct) if pct > limit else ''
    return inner_autopct

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
parser.add_argument("-type","-t", default="all", help="type of collection: fascicule, monographie")
parser.add_argument("-chart","-c", action="store_true", help="Produce a graph")
parser.add_argument("-format","-f", default="json", help="Data format (json, xml)")
args = parser.parse_args()

if args.type=="monographie":
    type_name = "Monographie"
elif args.type=="fascicule":
    type_name = "Périodique"
else:
    print ("... argument -t (type of documents) must be: monographie, fascicule")
    quit()

##################
#types=['fascicule','monographie']
OUT = "gallica_programs_"
t=args.type
programs=['%20and%20(%20notice%20all%22numérisation des indisponibles%22)','%20and%20(%20notice%20all%22proquest%22)','' ]
program_names=['Indisponibles du 20e','Proquest','Autres']
query=''
result=[]
result_p=[]
sources=[]
collection={}
total=0
total_p=0

#  consultation = gallica (BnF + integrated)
provenance = '%20and%20%28provenance%20adj%20%22bnf.fr%22%29'
source = 'BnF et intégrés'

print (" ---------\n** Documents type set on the command line is: ",type_name,"**")

subgroup_names_legs=[]
for p in program_names:
    subgroup_names_legs.append(p+" : sans ocr")
    subgroup_names_legs.append(p+" : avec ocr")

#['mono:autre', 'mono:'+source, 'image:autre', 'image:'+source, 'manuscrit:autre', 'manuscrit:'+source,'carte:autre', 'carte:'+source, 'fascicule:autre', 'fascicule:'+source]


# querying all documents
print ("---------\nQuerying documents type: ", t, "\n")
for p in programs:
  print (" requesting program:", p)
  query = 'https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&collapsing=false&query=(dc.type%20all%20%22'+t+'%22)'+provenance+p
  page = requests.get(query) # Getting page HTML through request
  soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
  te=int(soup.find("numberOfRecords").get_text())
  print (te)
  result.append(te)
print (" ---------\n SRU query sample:", query)

total = result[-1] # total number of documents
total_p = sum(result) -total   #total number of documents form program
result[-1] = total - total_p # no-program documents

print (" --------- raw data from the SRU API:\n" , result)

collection['data'] = {}
collection['data']['query'] = {}
collection['data']['query']['sample'] = query
collection['data']['query']['date'] = str(date.today())
collection['data']['query']['collection'] = t
collection['data']['query']['source'] = source
collection['data']['query']['total'] = total
collection['data']['sru'] = result
collection['data']['programs'] = programs

output_data(collection, "full")
collection={}

# Now querying OCRed documents
print ("---------\nQuerying OCRed documents type:", t,"\n")
i=0
for p in programs:
  print ("  requesting program: ", p)
  query = 'https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&collapsing=false&query=(dc.type%20all%20%22'+t+'%22)%20and%20(ocr.quality%20all%20"Texte%20disponible")'+provenance+p
  page = requests.get(query) # Getting page HTML through request
  soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
  te=int(soup.find("numberOfRecords").get_text())
  print (te)
  result_p.append(result[i] - te) # all - ocred
  result_p.append(te)
  # creating labels
  sources.append(' ')
  sources.append(("OCR: \n{:.1f}%".format(te/result[i]*100)) if te/result[i] > 0.05 else '')
  i+=1
print (" ---------\n SRU query sample:", query)

#total_ocr = result_p[-1] # total number of documents
total_ocr_p = sum(result_p)
#result_p[-1] = total_ocr - total_ocr_p # no-program documents
print (" --------- raw data from the SRU API:\n" , result_p)

collection['OCRed'] = {}
collection['OCRed']['query'] = {}
collection['OCRed']['query']['sample'] = query
collection['OCRed']['query']['date'] = str(date.today())
collection['OCRed']['query']['collection'] = t
collection['OCRed']['query']['source'] = source
collection['OCRed']['query']['total'] = total_ocr_p
collection['OCRed']['data'] = result_p

output_data(collection, "ocr")

print (" ---------\n total documents:", total)


if not(args.chart):
    quit()

NUM_TYPES = len(programs)
# set color theme
# https://matplotlib.org/api/pyplot_summary.html#colors-in-matplotlib
fig, ax = plt.subplots()
#bmap = cm.get_cmap('tab20b')
cmap = cm.get_cmap("tab20c")
#cmap = plt.colormaps["tab20c"]
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
    ax.annotate(program_names[i]+" : \n{:.1f}% ({})".format(result[i]/total*100,result[i]), xy=(x, y), xytext=(1.35*np.sign(x), 1.4*y),
                horizontalalignment=horizontalalignment, **kw)

plt.title('Part des collections \''+type_name+ "\' sous programme (source : \'"+source+ "\'), total : "+str(total_p)+' ('+"{:.1f}%".format(total_p/total*100)+')\nrelativ. à la collection, total : '+str(total)+' - Source : API Gallica SRU')
plt.show()


#colors = ['yellowgreen', 'gold', 'lightskyblue', 'lightcoral']
#plt.pie(result.values(), labels=types, colors=colors,
#        autopct='%1.1f%%', shadow=True, startangle=90)

#plt.axis('equal')

#plt.show()
