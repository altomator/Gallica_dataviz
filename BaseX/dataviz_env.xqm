(: library of parameters for the gallica dataviz app:
- constant values
- GUI setup
:)

module namespace gdp = "http:/gallicaviz.bnf.fr/env";


(: URL prefix for the web app:
"http://localhost:8984"
"https://pfvgallicaviz.bnf.fr"
:)
declare variable $gdp:appPrefix as xs:string := "http://localhost:8984" ;

(: margin before chart:)
declare variable $gdp:marginTop as xs:integer := 50 ;

declare function gdp:openInGallica ($locale as xs:string?) as xs:string {
   if ($locale='fr') then ("Cliquer pour voir dans Gallica") else ("Click to open in Gallica")};

declare function gdp:labelOn ($locale as xs:string?) as xs:string {
   if ($locale='fr') then (" sur ") else (" on ")
 };
declare function gdp:labelDate ($locale as xs:string?) as xs:string {
   if ($locale='fr') then (" couverture date") else (" date coverage")
 };
declare function gdp:percent ($locale as xs:string?) as xs:string {
   if ($locale='fr') then (" %") else ("%")
 };
declare function gdp:colon ($locale as xs:string?) as xs:string {
   if ($locale='fr') then (" : ") else (": ")
 };
        
(: base URL for Gallica SRU API :)
declare variable $gdp:SRU as xs:string  := fn:escape-html-uri("https://gallica.bnf.fr/services/engine/search/sru?operation=searchRetrieve&amp;exactSearch=false&amp;collapsing=false&amp;query=");

(: localize "other":)
declare function gdp:other($locale as xs:string?)  as xs:string {
  if ($locale='fr') then ("autres") 
  else ("other")
};

(: localize chart's subtitle :)
declare function gdp:subtitle($date as xs:string?, $locale as xs:string?)  as xs:string {
  if ($locale='fr') then (concat('Source : <a href="https://gallica.bnf.fr" target="_default">Gallica</a> et <a href="https://api.bnf.fr/fr/api-gallica-de-recherche" target="_default">API Gallica SRU</a> (', $date,')')) else (concat('Source: <a href="https://gallica.bnf.fr" target="_default">Gallica</a> and <a href="https://api.bnf.fr/fr/api-gallica-de-recherche" target="_default">Gallica SRU API</a> (', $date,')'))
};

(: chart's background color :)
declare variable $gdp:backgroundColor as xs:string :=   "#EBEBEB";
(: color for other part  :)
declare variable $gdp:otherInnerColor as xs:string := "#B8B0AE" ; (: gray :)
(: small pie on top left corner :)
declare variable $gdp:smallPieLabelSize as xs:integer := 9;
declare variable $gdp:smallPieLabelColor as xs:string := "gray";

(: chart's labels :)
declare variable $gdp:labelSize as xs:integer := 14;
declare variable $gdp:labelMedSize as xs:integer := 12;
declare variable $gdp:labelSmallSize as xs:integer := 11;
declare variable $gdp:labelTinySize as xs:integer := 8;
declare variable $gdp:labelColor as xs:string := "#202020";
declare variable $gdp:labelOutline as xs:string := "0.5px contrast";
(: labels: number of digits after the decimal point :)
declare variable $gdp:labelDigits as xs:integer := 1;


(: ####### PROVENANCES chart ########## :)
(: convert source category to DB name:)
declare variable $gdp:provNameFR2EN := map{
    "BnF": "bnf", 
    "intégrés": "integrated", 
    "moissonnés": "harvested",
    "BnF et intégrés": "bnf_and_integrated"
   };

declare variable $gdp:provNameEN2FR := map{
    "integrated": "intégrés", 
    "harvested": "moissonnés",
    "BnF": "BnF",
    "bnf_and_integrated": "BnF et intégrés"
   };

(: convert EN source category to the right language, dependning of locale :)
declare function gdp:provName ($prov as xs:string?, $locale as xs:string?) as xs:string {
  if ($locale='fr') then (map:get($gdp:provNameEN2FR,$prov)) else
   ($prov)  
};
      
(: provenance main color :)
declare variable $gdp:provColor as xs:string := "#6A5ACD" ; (: "SlateBlue" :)

(: provenance drill colors :)
declare variable $gdp:provDrillColors := ("#250b3b" ,"#371456", "#371357", "#4a2569", "#4c018d", "#5c1c95", "#6f29ac",  "#6e26af",   "#8140b9",   "#8502f7", "#9342db", "#a466da", "#a464dc", "#b58dd7","#b767fd", "#c69cec", "#c88afe", "#e3c4fe", "lightgray") ;  

declare variable $gdp:provCriteria as xs:string :=  "Provenances" ; 

(: ####### PARTNERS chart ########## :)
declare variable $gdp:partnersList  := ("integrated", "harvested", "bnf_and_integrated");

(: partners main color :)
declare variable $gdp:partnersStartColor as xs:string := "#2A1388" ; (: purple :)

(: partners color by provenance 
declare variable $gdp:partnersColors := map{
    "BnF":"#040054",  
    "intégrés":"#2A1388", 
    "moissonnés": "#5641C1",
    "integrated":"#2A1388", 
    "harvested": "#5641C1"
  };
 :)

(: colors by provenance 
We used gradients even for solid colors because of solid colors must be in enclosed in ""
and gradients not :)  
declare variable $gdp:partnersColors := map{
    "BnF": "{linearGradient: { x1: 0, y1: 0, x2: 1, y2: 1 }, stops: [[0, '#030163'], [1, '#030163'] ]}", 
    "bnf": "{linearGradient: { x1: 0, y1: 0, x2: 1, y2: 1 }, stops: [[0, '#030163'], [1, '#030163'] ]}",
    "moissonnés":  "{linearGradient: { x1: 0, y1: 0, x2: 1, y2: 1 }, stops: [[0, '#675BC6'], [1, '#675BC6'] ]}",
    "harvested": "{linearGradient: { x1: 0, y1: 0, x2: 1, y2: 1 }, stops: [[0, '#675BC6'], [1, '#675BC6'] ]}" ,
    "integrated": "{linearGradient: { x1: 0, y1: 0, x2: 1, y2: 1 }, stops: [[0, '#352894'], [1, '#352894'] ]}" , 
    "intégrés": "{linearGradient: { x1: 0, y1: 0, x2: 1, y2: 1 }, stops: [[0, '#352894'], [1, '#352894'] ]}" , 
    "BnF et intégrés": "{linearGradient: { x1: 0, y1: 0, x2: 1, y2: 1 }, stops: [[0, '#030163'], [1, 'white'] ]}",
    "bnf_and_integrated": "{linearGradient: { x1: 0, y1: 0, x2: 1, y2: 1 }, stops: [[0, '#030163'], [1, 'white'] ]}",
    "partenaires": "{linearGradient: { x1: 0, y1: 0, x2: 1, y2: 1 }, stops: [[0, '#675BC6'], [1, 'white'] ]}",
    "partners": "{linearGradient: { x1: 0, y1: 0, x2: 1, y2: 1 }, stops: [[0, '#675BC6'], [1, 'white'] ]}",
    "complète": "{linearGradient: { x1: 0, y1: 0, x2: 1, y2: 1 }, stops: [[0, '#030163'], [1, '#675BC6']]}",
    "full": "{linearGradient: { x1: 0, y1: 0, x2: 1, y2: 1 }, stops: [[0, '#030163'], [1, '#675BC6']]}",
    "tout": "{linearGradient: { x1: 0, y1: 0, x2: 1, y2: 1 }, stops: [[0, '#030163'], [1, '#675BC6']]}"
  };

declare function gdp:partnersCriteria ($locale as xs:string?) as xs:string {
  if ($locale='fr') then ("partenaires") else ("partners")  
};


(: ####### PARTNERS chart ########## :)  
declare variable $gdp:regionHoverColor as xs:string := "#eccfcf";
declare variable $gdp:cityColor as xs:string := "white";

(: ####### TYPES chart ########## :)  
declare variable $gdp:gallicaTypesColors := map{
    "periodical":"#128799", 
    "monograph":"#149BB1", 
    "manuscript":"#78B7B7", 
    "music score":"#D6E9E9 ", 
    "map":"#d5c6ba ", 
    "image":"#a5846b", 
    "object":"#c2ab9b", 
    "sound":"#89A2B4", 
    "video":"#D2E1EC",
    
    "fascicule":"#128799", 
    "monographie":"#149BB1", 
    "manuscrit":"#78B7B7", 
    "partition":"#D6E9E9 ", 
    "carte":"#d5c6ba ", 
    "objet":"#c2ab9b", 
    "son":"#89A2B4"
  };
declare variable $gdp:gallicaTypesPatterns := map{
  "periodical": "pattern: {
          image: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/United_States_one_dollar_bill%2C_obverse.jpg/320px-United_States_one_dollar_bill%2C_obverse.jpg',
          aspectRatio: 9 / 4
        }", 
    "monograph":  "pattern: {
          image: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/United_States_one_dollar_bill%2C_obverse.jpg/320px-United_States_one_dollar_bill%2C_obverse.jpg',
          aspectRatio: 9 / 4
        }", 
    "manuscript": "pattern: {
          image: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/United_States_one_dollar_bill%2C_obverse.jpg/320px-United_States_one_dollar_bill%2C_obverse.jpg',
          aspectRatio: 9 / 4
        }",
    "music score":  "pattern: {
          image: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/United_States_one_dollar_bill%2C_obverse.jpg/320px-United_States_one_dollar_bill%2C_obverse.jpg',
          aspectRatio: 9 / 4
        }",
    "map": "pattern: {
          image: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/United_States_one_dollar_bill%2C_obverse.jpg/320px-United_States_one_dollar_bill%2C_obverse.jpg',
          aspectRatio: 9 / 4
        }", 
    "image": "pattern: {
          image: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/United_States_one_dollar_bill%2C_obverse.jpg/320px-United_States_one_dollar_bill%2C_obverse.jpg',
          aspectRatio: 9 / 4
        }", 
    "object": "pattern: {
          image: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/United_States_one_dollar_bill%2C_obverse.jpg/320px-United_States_one_dollar_bill%2C_obverse.jpg',
          aspectRatio: 9 / 4
        }",
    "sound": "pattern: {
          image: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/United_States_one_dollar_bill%2C_obverse.jpg/320px-United_States_one_dollar_bill%2C_obverse.jpg',
          aspectRatio: 9 / 4
        }", 
    "video": "pattern: {
          image: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/United_States_one_dollar_bill%2C_obverse.jpg/320px-United_States_one_dollar_bill%2C_obverse.jpg',
          aspectRatio: 9 / 4
        }",
        
    "fascicule": "pattern: {
          image: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/United_States_one_dollar_bill%2C_obverse.jpg/320px-United_States_one_dollar_bill%2C_obverse.jpg'
        }", 
    "monographie": "pattern: {
          image: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/United_States_one_dollar_bill%2C_obverse.jpg/320px-United_States_one_dollar_bill%2C_obverse.jpg'
        }",
    "manuscrit": "pattern: {
          image: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/United_States_one_dollar_bill%2C_obverse.jpg/320px-United_States_one_dollar_bill%2C_obverse.jpg'
        }", 
    "partition": "pattern: {
          image: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/United_States_one_dollar_bill%2C_obverse.jpg/320px-United_States_one_dollar_bill%2C_obverse.jpg'
        }", 
    "carte": "pattern: {
          image: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/United_States_one_dollar_bill%2C_obverse.jpg/320px-United_States_one_dollar_bill%2C_obverse.jpg',
          aspectRatio: 9 / 4
        }", 
    "objet": "pattern: {
          image: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/United_States_one_dollar_bill%2C_obverse.jpg/320px-United_States_one_dollar_bill%2C_obverse.jpg',
          aspectRatio: 9 / 4
        }", 
    "son": "{pattern: {
          image: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/United_States_one_dollar_bill%2C_obverse.jpg/320px-United_States_one_dollar_bill%2C_obverse.jpg',
          aspectRatio: 9 / 4
        }"
};

declare function gdp:typesCriteria ($locale as xs:string?) as xs:string {
 "types"
};

(: ####### OCR chart ########## :)  
declare function gdp:noOCR ($locale as xs:string?) as xs:string {
  if ($locale='fr') then ("sans OCR") else ("no OCR")
};

declare function gdp:OCR ($locale as xs:string?) as xs:string {
   if ($locale='fr') then ("avec OCR") else ("with OCR")
 };

(: ####### PROGRAMS chart ########## :)  
declare variable $gdp:progColor as xs:string := "#ae5a4d" ;

declare function gdp:programsCriteria ($locale as xs:string?) as xs:string {
   if ($locale='fr') then ("Programmes") else ("Programs")
 };
 
(: ####### DATES chart ########## :)
declare function gdp:suffix ($locale as xs:string?) as xs:string {
   if ($locale='fr') then ("e") else ("th") 
 };
 
declare function gdp:types ($era as xs:integer?)  {
  let $types :=  if ($era=1) then (
      (  "image", "object", "manuscript" )) 
   else if ($era=2) then (
    ( "monograph", "image", "object", "manuscript", "map", "music_score"))
   else if ($era=3) then (
    ("periodical", "monograph", "image", "object", "manuscript", "map", "music_score"))
   else (("periodical", "monograph", "image", "object", "manuscript", "map", "music_score", "sound", "video"))  
   return $types
 };
 
declare function gdp:types_fr ($era as xs:integer?)  {
  let $types :=  if ($era=1) then ( (: antiquity :)
      (  "image", "objet", "manuscrit")) 
   else if ($era=2) then ( (: middle-age :)
    ( "monographie", "image", "objet", "manuscrit", "carte", "partition"))
   else if ($era=3) then ( (: modern :)
    ("fascicule", "monographie", "image", "objet", "manuscrit", "carte", "partition"))
   else (: contemporary and all periods :)
   (("fascicule", "monographie", "image", "objet", "manuscrit", "carte", "partition", "son", "video"))  
   return $types
 };  
   

declare variable $gdp:ocrTypes  := ("periodical", "monograph", "music_score" )  ;
(: declare variable $types_fr  := ("fascicule", "monographie", "partition")  ;:)
declare variable $gdp:ocrTypes_fr  := ("fascicule", "monographie", "partition");

declare function gdp:show ($locale as xs:string?) as xs:string {
    if ($locale='fr') then ("Masquer tout") else ("Show/Hide all")  
  };
declare function gdp:century ($locale as xs:string?) as xs:string {
  if ($locale='fr') then ("Siècles") else ("Centuries")  
};