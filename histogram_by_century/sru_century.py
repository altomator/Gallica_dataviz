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

def autopct_generator(limit):
    """Remove percent on small slices."""
    def inner_autopct(pct):
        return ('%.1f%%' % pct) if pct > limit else ''
    return inner_autopct

def auto_complete(a_dict):
    # fill empty centuries
    for i in range(1,century_H+1):
        if not(i in a_dict):
            #print(i, " century not exists, adding 0 value")
            a_dict[i] = 0

def del_outliers(a_dict):
    # remove centuries
    for key in list(a_dict):
        if (key > century_H) or (key < century_L):
            #print(" removing century ",key)
            a_dict.pop(key)

parser = argparse.ArgumentParser()
parser.add_argument("-type","-t", help="type of documents: monographie, manuscrit, fascicule, partition, carte, image, sonore, objet, video", required=True)
parser.add_argument("-source","-s", default="all", help="source of collection: gallica, bnf, partners, integrated, harvested")

args = parser.parse_args()
type = args.type

############################
# types of Gallica documents:  'monographie', 'carte', 'image', 'fascicule', 'manuscrit', 'partition', 'sonore', 'objet', 'video'
if type=="manuscrit":
    century_L = 1 # first century to process
elif type=="carte":
    century_L = 10
elif type=="image":
    century_L = 1
elif type=="fascicule":
    century_L = 15
elif type=="monographie":
    century_L = 15
elif type=="partition":
    century_L = 10
elif type=="objet":
    century_L = 1  # we have ancient coins
elif type=="video":
    century_L = 20
elif type=="sonore":
    century_L = 19
else:
    print ("... argument -t (type of documents) must be: monographie, manuscrit, fascicule, partition, carte, image, sonore, objet, video")
    quit()

# last century to process
century_H = 21

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
elif args.source=="all":
    provenance = ''
    source = 'tout'
else:
    print ("... argument -s (source of collection) must be: all, gallica, bnf, partners, integrated, harvested")
    quit()

print (" ---------\n requesting documents from: ",source)

centuries=[] #['1', '2', '3', '4','5','6','7','8','9','10', '11', '12', '13', '14','15','16','17','18','19','20','21',]
result={}
result_p={}
collection={}
query=''
i=0
OUT = type+"_by_CENTURY.json"
print ("...writing in: ",OUT)

# using the SRU:Categories service to get all the documents by century
print (" ---------\n requesting all "+type+" documents by filter: century")
for c in range(century_L,century_H+1):
  print ("... century: ", str(c))
  query = 'https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&collapsing=false&maximumRecords=50&query=(dc.type%20all%20%22'+type+'%22)&filter=century%20all%20%22'+str(c)+'%22&collapsing=false'
  #print (query)
  time.sleep(1)
  try:
      page = requests.get(query) # Getting page HTML through request
      soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
      value=int(soup.find("numberOfRecords").get_text())
      result[c]=value
      print (value)
  except:
      print("Wow, ", sys.exc_info()[0], " occurred!\n Maybe a APi error. Try again!")
      quit()
print (" ---------\n OAI sample query:", query)
print (" --------- raw data from the SRU API:\n" , result)

# adding empty values and sorting
auto_complete(result)
del_outliers(result)
sorted_result = dict(sorted(result.items(), key=operator.itemgetter(0)))
dataset1 = np.array(list(sorted_result.values()))
centuries = len(dataset1)
total_1 = sum(dataset1)

# asking for the whole number of documents (without the date md)
query = 'https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&query=(dc.type%20all%20%22'+type+'%22)&collapsing=false'
try:
  page = requests.get(query) # Getting page HTML through request
  soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
  result_tot_all= int(soup.find("numberOfRecords").get_text())
except:
      print("Wow, ", sys.exc_info()[0], " occurred!\n Maybe a APi error. Try again!")
      result_tot_all=0
print (" ---------\n total documents (no date facet used):", result_tot_all)

# outputing data as JSON
collection['all'] = {}
collection['all']['query'] = {}
collection['all']['query']['sample'] = query
collection['all']['query']['date'] = str(date.today())
collection['all']['query']['collection'] = type
collection['all']['query']['source'] = "bnf"
collection['all']['query']['facet_name'] = "century"
collection['all']['query']['total'] = result_tot_all
collection['all']['query']['with_facet'] = int(total_1)
collection['all']['data'] = sorted_result

# other collection to compare with
if args.source!="all":
    print (" ---------\n requesting  collection " + source + " by filter: century")
    for c in range(century_L,century_H+1):
        print ("... century: ", str(c))
        query = 'https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&collapsing=false&maximumRecords=50&query=(dc.type%20all%20%22'+type+'%22)'+provenance+'&filter=century%20all%20%22'+str(c)+'%22&collapsing=false'
        #print (query)
        time.sleep(1)
        try:
            page = requests.get(query) # Getting page HTML through request
            soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
            value=int(soup.find("numberOfRecords").get_text())
            result_p[c]=value
            print (value)
        except:
            print("Wow, ", sys.exc_info()[0], " occurred!\n Maybe a API error, try again!")
            quit()
    print (" ---------\n OAI sample query:", query)
    print (" --------- raw data from the SRU API:\n" , result_p)
    auto_complete(result_p)
    del_outliers(result_p)
    sorted_result_p = dict(sorted(result_p.items(), key=operator.itemgetter(0)))
    dataset2 = np.array(list(sorted_result_p.values()))
    total_2 = sum(dataset2)
    # whole number of documents of other collection
    query = 'https://gallica.bnf.fr/SRU?version=1.2&operation=searchRetrieve&query=(dc.type%20all%20%22'+type+'%22)'+provenance+'&collapsing=false'
    try:
        page = requests.get(query) # Getting page HTML through request
        soup = BeautifulSoup(page.content, 'xml') # Parsing content using beautifulsoup
        result_tot_partners= int(soup.find("numberOfRecords").get_text())
    except:
        print("Wow, ", sys.exc_info()[0], " occurred!")
        result_tot_partners=0
    print ("  total other collection (no date facet used):", result_tot_partners)

    #print (sorted_result_p)
    collection['partners'] = {}
    collection['partners']['query'] = {}
    collection['partners']['query']['sample'] = query
    collection['partners']['query']['date'] = str(date.today())
    collection['partners']['query']['collection'] = type
    collection['partners']['query']['source'] = source
    collection['partners']['query']['facet_name'] = "century"
    collection['partners']['query']['total'] = result_tot_partners
    collection['partners']['query']['with_facet'] = int(total_2)
    collection['partners']['data'] = sorted_result_p
    print (" ---------\n other collection facetted:", total_2)

print (" centuries:", centuries)

# writing json data
json_string = json.dumps(collection)
with open(OUT, 'w') as outfile:
    outfile.write(json_string)
outfile.close()

# building the graph
labels = list(map(str, sorted_result.keys()))
yoffset = max(dataset1)*0.02
cover_all = "{:.1f}%".format((total_1/result_tot_all)*100)

if args.source!="all":
    # we need to stack the 2 sets
    dataset1 = dataset1 - dataset2
    cover = "{:.1f}%".format((total_1-total_2)/(result_tot_all-result_tot_partners)*100)
    cover_p = "{:.1f}%".format((total_2/result_tot_partners)*100)
    p1 = plt.bar(labels, dataset2, color=plt.cm.Paired(1), label=type+ " (" + source + ") : "+str(total_2)+ " sur "+ str(result_tot_partners)+" ("+ cover_p +")")
    p2 = plt.bar(labels, dataset1, bottom=dataset2, color=plt.cm.Paired(2) , label=type+" (solde) : "+str(total_1-total_2)+ " sur "+ str(result_tot_all-result_tot_partners)+" ("+ cover +")" ) #https://matplotlib.org/stable/tutorials/colors/colormaps.html
    plt.title('Quantité de documents de type '+type+ " par siècles de publication et collection (tout Gallica/"+source+ ")\n Total avec facette 'century' : "+str(total_1)+' sur '+str(result_tot_all)+' ('+str(cover_all)+') - Source : API Gallica SRU')
    # annotating the chart
    i=0
    for rect2 in p2:
        height1 = p1[i].get_height()
        height2 = p1[i].get_height()+rect2.get_height()
        if (dataset1[i]+dataset2[i])!=0:
            percent = dataset1[i]/(dataset1[i] + dataset2[i])*100
            plt.annotate( "{:.1f}%".format(100.0 - percent),(rect2.get_x() + rect2.get_width()/2, height1-yoffset),ha="center",va="bottom",fontsize=5)
            plt.annotate( "{:.1f}%".format(percent),(rect2.get_x() + rect2.get_width()/2, height2-yoffset),ha="center",va="bottom",fontsize=5)
        plt.annotate( "{}".format(dataset1[i] + dataset2[i]),(rect2.get_x() + rect2.get_width()/2, height2+yoffset),ha="center",va="bottom",fontsize=8)
        i += 1
else:
    p1 = plt.bar(labels, dataset1, color=plt.cm.Paired(1), label=type+ " (" + source + ") : " + str(total_1))
    plt.title('Quantité de documents de type '+type+ " par siècles de publication et collection (tout Gallica)\n Total avec facette 'century' : " + str(total_1) + ' sur ' + str(result_tot_all) +' ('+str(cover_all)+') - Source : API Gallica SRU')
    i=0
    for rect1 in p1:
        height1 = p1[i].get_height()
        plt.annotate( "{}".format(dataset1[i]),(rect1.get_x() + rect1.get_width()/2, height1+yoffset),ha="center",va="bottom",fontsize=8)
        i += 1

plt.xlabel('siècles')
plt.ylabel('#documents')
plt.legend(loc="best")


plt.show()
