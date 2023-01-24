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
from dicttoxml import dicttoxml
from matplotlib import cm
import os


def output_data(data, type, ocr):
    if args.format=="json":
        file_name=OUT_folder+OUT+ocr+"_"+type+".json"
        print ("...writing in: ",file_name)
        # JSON serialisation
        json_string = json.dumps(data)
        with open(file_name, 'w') as outfile:
            outfile.write(json_string)
        outfile.close()
    else:
        file_name=OUT_folder+OUT+ocr+"_"+type+".xml"
        print ("...writing in: ",file_name)
        # XML serialisation
        xml = dicttoxml(collection, attr_type=False)
        #encoding = 'utf-8'
        #str(xml, encoding)
        with open(file_name, 'w') as outfile:
            outfile.write(xml.decode("utf-8"))
        outfile.close()

parser = argparse.ArgumentParser()
parser.add_argument("-type","-t", default="all", help="type of collection: periodical, monograph")
parser.add_argument("-chart","-c", action="store_true", help="Produce a graph")
parser.add_argument("-format","-f", default="xml", help="Data format (json, xml)")
args = parser.parse_args()

if args.type=="monograph":
    type_name_fr = "Monographie"
    type_name = "Monograph"
    type_req = "monographie"
    programs=['%20and%20(%20notice%20all%22numérisation des indisponibles%22)','%20and%20(%20notice%20all%22proquest%22)','' ]
    program_names_fr=['Indisponibles du 20e','Proquest','autres']
    program_names=['Indisponibles du 20e','Proquest','other']
elif args.type=="periodical":
    type_name_fr = "Périodique"
    type_name = "Periodical"
    type_req = "fascicule"
    programs=['%20and%20(%20notice%20all%22Presse Ancienne RetroNews%22)','']
    program_names_fr=['Retronews','Autres']
    program_names=['Retronews','Other']
else:
    print ("... argument -t (type of documents) must be: periodical, monograph")
    quit()

#  consultation = gallica (BnF + integrated)
provenance = '%20and%20%28provenance%20adj%20%22bnf.fr%22%29'
source = 'BnF and integrated'
source_fr = 'BnF et intégrés'


##################
SRU = "https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&collapsing=false&query="
OUT_folder = "data/"
OUT = "gallica_programs_"
query=''
result=[]
result_p=[]
result_inner=[]
sources=[]
searchs=[]
collection={}
total=0
total_p=0



# Check whether the specified path exists or not
isExist = os.path.exists(OUT_folder)
if not isExist:
   os.makedirs(OUT_folder)
   print("...Data are outputed in: ",OUT_folder)

print (" ---------\n** Documents type set on the command line is: ",type_name,"**")

subgroup_names_legs=[]
for p in program_names_fr:
    subgroup_names_legs.append(p+" : sans ocr")
    subgroup_names_legs.append(p+" : avec ocr")


# querying all documents
print ("---------\nQuerying documents type: ", type_req, "\n")
for p in programs:
  print (" requesting program: ", p)
  search = '(dc.type%20all%20%22'+type_req+'%22)'+provenance + p
  query = SRU + search
  #print(query)
  page = requests.get(query) # Getting page HTML through request
  soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
  te=int(soup.find("numberOfRecords").get_text())
  print (te)
  result.append(te)
  searchs.append(search)
print (" ---------\n SRU query sample:", query)

total = result[-1] # total number of documents
total_p = sum(result) - total   #total number of documents from programs
result[-1] = total - total_p # no-program documents

print (" --------- raw data from the SRU API:\n" , result)
collection['data'] = {}
collection['data']['query'] = {}
collection['data']['query']['sample_url'] = query
collection['data']['query']['date'] = str(date.today())
collection['data']['query']['collection'] = program_names
collection['data']['query']['collection_fr'] = program_names_fr
collection['data']['query']['target'] = type_name
collection['data']['query']['target_fr'] = type_name_fr
collection['data']['query']['source'] = source
collection['data']['query']['source_fr'] = source_fr
collection['data']['query']['search'] = searchs
collection['data']['query']['total'] = total
collection['data']['query']['total_p'] = total_p
collection['data']['sru'] = result

output_data(collection, args.type, "bnf_and_integrated")

# Now querying OCRed documents
print ("---------\nQuerying OCRed documents type:", type_req,"\n")
i=0
collection={}
searchs=[]

for p in programs:
  print ("  requesting program: ", p)
  search = '(dc.type%20all%20%22'+type_req+'%22)%20and%20(ocr.quality%20all%20%22Texte%20disponible%22)' + provenance + p
  query = SRU + search
  #print(query)
  page = requests.get(query) # Getting page HTML through request
  soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
  te=int(soup.find("numberOfRecords").get_text())
  print (te)
  result_inner.append(result[i] - te) # all - ocred
  result_inner.append(te)
  result_p.append(te)
  searchs.append(search)
  # creating labels
  sources.append(' ')
  sources.append(("OCR: \n{:.1f}%".format(te/result[i]*100)) if te/result[i] > 0.05 else '')
  i+=1
print (" ---------\n SRU query sample:", query)

total_ocr = result_p[-1] # total number of documents with OCR
total_ocr_p = sum(result_p) - total_ocr #total number of OCRed documents from programs
result_p[-1] = total_ocr - total_ocr_p # no-program documents
print (" --------- raw data from the SRU API:\n" , result_p)

collection['data'] = {}
collection['data']['query'] = {}
collection['data']['query']['sample_url'] = query
collection['data']['query']['total_url'] = '(dc.type%20all%20%22'+type_req+'%22)%20and%20(ocr.quality%20all%20%22Texte%20disponible%22)' + provenance
collection['data']['query']['date'] = str(date.today())
collection['data']['query']['collection'] = program_names
collection['data']['query']['collection_fr'] = program_names_fr
collection['data']['query']['target'] = type_name
collection['data']['query']['target_fr'] = type_name_fr
collection['data']['query']['source'] = source
collection['data']['query']['source_fr'] = source_fr
collection['data']['query']['search'] = searchs
collection['data']['query']['ocr'] = 'y'
collection['data']['query']['total'] = total_ocr
collection['data']['query']['total_p'] = total_ocr_p
collection['data']['sru'] = result_p

output_data(collection, args.type, "bnf_and_integrated_ocr")

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

# Second Ring (inside): all - ocr
mypie2, _ = ax.pie(result_inner, radius=1.2-0.3,
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
    ax.annotate(program_names_fr[i]+" : \n{:.1f}% ({})".format(result[i]/total*100,result[i]), xy=(x, y), xytext=(1.35*np.sign(x), 1.4*y),
                horizontalalignment=horizontalalignment, **kw)

plt.title('Part des collections \''+type_name+ "\' sous programme (source : \'"+source_fr+ "\'), total : "+str(total_p)+' ('+"{:.1f}%".format(total_p/total*100)+')\nrelativ. à la collection, total : '+str(total)+' - Source : API Gallica SRU')
plt.show()


#colors = ['yellowgreen', 'gold', 'lightskyblue', 'lightcoral']
#plt.pie(result.values(), labels=types, colors=colors,
#        autopct='%1.1f%%', shadow=True, startangle=90)

#plt.axis('equal')

#plt.show()
