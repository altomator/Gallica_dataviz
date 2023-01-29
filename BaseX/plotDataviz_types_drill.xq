(:
 Dataviz of the Gallica collections
:)

declare namespace functx = "http://www.functx.com";

declare option output:method 'html';

(: Arguments avec valeurs par defaut :)
declare variable $locale as xs:string external := "fr" ; (: langue: fr/en :)

(: the full collection :)
declare variable $DBall as xs:string external := "gallica_types_full" ;
(: the DB for the targeted collection :)
declare variable $DBtarget1 as xs:string  := "gallica_types_bnf" ; 
declare variable $DBtarget2 as xs:string  := "gallica_types_integrated" ; 
declare variable $DBtarget3 as xs:string  := "gallica_types_harvested" ; 

(: declare variable $currentDate as xs:date  := current-date(); :)

(: Parameters :)

(: Pie colors :)
declare variable $mainColor as xs:string := "#3b9db3" ; (: green  :) 
declare variable $gallicaColors := map{
    "periodical":"#128799", 
    "monograph":"#149BB1", 
    "manuscript":"#78B7B7", 
    "music score":"#D6E9E9 ", 
    "map":"#d5c6ba ", 
    "image":"#a5846b", 
    "object":"#c2ab9b", 
    "sound":"#89A2B4", 
    "video":"#D2E1EC"};
declare variable $gallicaColors_fr := map{
    "fascicule":"#128799", 
    "monographie":"#149BB1", 
    "manuscrit":"#78B7B7", 
    "partition":"#D6E9E9 ", 
    "carte":"#d5c6ba ", 
    "image":"#a5846b", 
    "objet":"#c2ab9b", 
    "son":"#89A2B4", 
    "video":"#D2E1EC"}; 
(: Drill colors (provenance): bnf, integrated, harvested :)
declare variable $drillColors  := ("#040054", "#2A1388", "#5641C1") ; 
declare variable $other  as xs:string := if ($locale='fr') then ("autres") else ("other");
declare variable $criteria as xs:string :=  "Types" ; (: label of the graph criteria :)
declare variable $full as xs:string := if ($locale='fr') then ("tout") else ("full");
declare variable $width as xs:integer := 1100 ;
 
(: URL Gallica de base :)
declare variable $SRU as xs:string external := fn:escape-html-uri("https://gallica.bnf.fr/services/engine/search/sru?operation=searchRetrieve&amp;exactSearch=false&amp;collapsing=false&amp;query=");

declare function local:evalQuery($query) {
    let $hits := xquery:eval($query)
    return $hits
};

(: return a color for a given documents type:)
declare function local:pieColors($doc_type) {
    let $foo := if ($locale eq "fr") then (map:get( $gallicaColors_fr, $doc_type)) else
     (map:get( $gallicaColors, $doc_type))
    return $foo
};

(: construction de la page HTML :)
declare function local:createOutput($data) {
  
<html>
{
let $processingDate := xs:date($data//date)
let $date := if ($locale='fr') then (format-date($processingDate, "[D]-[M]-[Y]")) else (format-date($processingDate, "[Y]-[M]-[D]"))

let $totalData := count($data/root/data/query/collection/item)
let $colls := if ($locale='fr') then ($data/root/data/query/collection_fr/item) else ($data/root/data/query/collection/item)
let $targetName1 := if ($locale='fr') then (collection($DBtarget1)//source_fr) else (collection($DBtarget1)//source)
let $targetName2 := if ($locale='fr') then (collection($DBtarget2)//source_fr) else (collection($DBtarget2)//source)
let $targetName3 := if ($locale='fr') then (collection($DBtarget3)//source_fr) else (collection($DBtarget3)//source)

(: URLs :) 
let $urlAll := collection($DBall)//search/item 
let $urlTarget1 := collection($DBtarget1)//search/item 
let $urlTarget2 := collection($DBtarget2)//search/item 
let $urlTarget3 := collection($DBtarget3)//search/item 

(: data :)
let $data := $data//sru/item
let $rawTotal := sum($data)
let $total := if ($locale='fr') then (replace(format-number($rawTotal, '9,999'),',','&#x2009;')) else (format-number(sum($data), '9,999')) 

(: data from the sub collections :)  
let $dataDrill1 := collection($DBtarget1)//sru/item
let $rawTarget1 := sum($dataDrill1)

let $dataDrill2 := collection($DBtarget2)//sru/item
let $rawTarget2 := sum($dataDrill2)

let $dataDrill3 := collection($DBtarget3)//sru/item
let $rawTarget3 := sum($dataDrill3)

let $title := if ($locale='fr') then (concat ("Analyse par type de documents et provenance &#x2014; Total : ",$total)) else 
(concat ("Analysis by document type and provenance &#x2014; Documents: ", $total))
let $subTitle := if ($locale='fr') then (concat('Source : <a href="https://gallica.bnf.fr" target="_default">Gallica</a> et <a href="https://api.bnf.fr/fr/api-gallica-de-recherche" target="_default">API Gallica SRU</a> (', $date,')')) else (concat('Source: <a href="https://gallica.bnf.fr" target="_default">Gallica</a> and <a href="https://api.bnf.fr/fr/api-gallica-de-recherche" target="_default">Gallica SRU API</a> (', $date,')'))
let $collsData := for $c at $position in $colls 
  let $stringData := concat('	{
    ',
    (if ($c eq "video")   then 'sliced: true,' 
    else (if (($c eq "sonore") or ($c eq "sound"))  then 'sliced: true, ' )),'
				name: "',data($c),'",
				y: ',data($data[$position]),',
        color: "',data(local:pieColors($c)),'",  
        url: "',concat($SRU,data($urlAll[$position])),'",
				drilldown: "',data($c),'"        
        }', (if ($position != $totalData) then ',') ,codepoints-to-string(10)
    )
  return $stringData
let $collsDrillData := for $c at $position in $colls 
  let $stringData := concat('	{  
        name: "',data($c),'",
        id: "',data($c),'",    
        data: [       
          { name: "',
           data($targetName1),'",
            url: "',concat($SRU, data($urlTarget1[$position])),'",
            color: "',data($drillColors[1]),'",  
           y: ',data($dataDrill1[$position]),'
        },
          {name: "',
           data($targetName2),'",
           url: "',concat($SRU, data($urlTarget2[$position])),'",
          color: "',data($drillColors[2]),'",  
          y: ',data($dataDrill2[$position]),'
        },
        {name: "',
           data($targetName3),'",
           url: "',concat($SRU, data($urlTarget3[$position])),'",
          color: "',data($drillColors[3]),'",  
          y: ',data($dataDrill3[$position]),'
        }
       ]     
        }', (if ($position != $totalData) then ',') ,codepoints-to-string(10)
    )
  return $stringData
return
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"></meta>
<title>{$title}</title>
<script src="/static/he.js"></script>
<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
<style>.highcharts-drilldown-data-label text{{
  text-decoration:none !important;
}};
.highcharts-drilldown-data-label {{color: red}}
 </style>
<script type="text/javascript">
$(function () {{
  

var pieColors = (function (doc_type) {{
  var colors = ["#128799", "#149BB1", "#78B7B7",  "#CAC9B8", 
               "#D6E9E9",
                "#a5846b", 
                 "#c2ab9b",
                  "#B89E8B",
                "#d5c6ba"
           ];
  var colors_types = {{fascicule:"#128799", monographie:"#149BB1t", manuscrit:"#78B7B7", 
  partition:"#CAC9B8", carte:"#D6E9E", image:"#a5846", objet:"#c2ab9b", son:"#c2ab9b", video:"#c2ab9b"}} ;          
  return colors_types[doc_type]
      
	}}());
    
$('#container').highcharts({{
chart: {{
	type: "pie",
  backgroundColor: "#EBEBEB",
	spacingBottom: 30,
  spacingTop: 30,
  spacingLeft: 10,
  spacingRight: 10,
  // Explicitly tell the width and height of a chart
  width:  {$width},
  height: 630
}},
title: {{
   margin: 30, // margin before the graph
   style: {{
            fontWeight: 'bold'
        }},
  text: "{$title}"
}},
xAxis: {{
	title: false,
	labels: {{
            enabled: false
        }}
}},
subtitle: {{
  style: {{
            fontWeight: 'bold'
        }},
	text:
		'{$subTitle}'
}},
tooltip: {{
	formatter: function () {{ 
     if (String('{$locale}') == 'fr') {{
       sep = ' '
       txt = " sur "
     }} else {{
       sep = ',' 
       txt = " on "
     }}     
     return  '<b>' + this.point.name + '</b>' + ' :<br></br>'+ Highcharts.numberFormat(this.y, 0, ',',sep) + txt + Highcharts.numberFormat(this.total, 0, ',',sep);
   }}
}},

plotOptions: {{
  series: {{
            cursor: 'pointer',
            point: {{
                events: {{
                    click: function () {{
                      if(this.options.url!=null) {{
                         window.open(he.decode(this.options.url),'_blank' );
                      }} else{{                      
                     }}                      
                    }}
                }}
            }}
        }},
	pie: {{
		startAngle: 90,
		allowPointSelect: true,
		cursor: "pointer",
		
		dataLabels: {{
			enabled: true,
			formatter: function () {{
       if (String('{$locale}') == 'fr') {{
       sep = ' '
       dec = ','
       per = " %"
       colon = ' : '
     }} else {{
       sep = ','
       dec = '.' 
       per = "%"
       colon = ': '
     }}  
     return '<a target="_blank" href="' + this.point.url + '">'+ this.point.name  + colon + Highcharts.numberFormat(this.point.percentage, 2,dec,sep)+per + '</a>';   
     }}
		}},
		showInLegend: true
	}}
}},
series: [
	{{
    name: "{$criteria}",
    colorByPoint: true,
    
    innerSize: '40%',
    dataLabels: {{
                style: {{
                    fontSize: 14,
                    textOutline: "none",
                                        
                }}
            }},
		data: [
      {$collsData}     
		]
	}}
],
drilldown: {{
        series: [
            {$collsDrillData} 
        ]
      }}
      
    }});
}});
</script>
</head>
}
<body>
<style>
.highcharts-description  {{
    font-family: Lucida Grande;
    margin: 10px auto;
    text-align: center;
    width: 100%;
    max-width: {$width}px;
}}
.highcharts-figure,
.highcharts-data-table  {{
    min-width: 320px;
    max-width: {$width}px;
    margin: 1em auto;
}}
	.scope-description  {{
    font-family: Lucida Grande;
    font-weight: bold;
    background-color: #EBEBEB;
    margin: 10px auto;
    margin-top: -10px;
    padding-top : 10px;
    padding-bottom: 10px;
    text-align: center;
    width: 100%;
    max-width: {$width}px;
}}
.caption {{ color : gray }}
.flag {{ width : 20px }}
a {{ text-decoration: none }}

.picto-item {{
  position: relative;  /*les .picto-item deviennent référents*/
  cursor: help;
  border-radius: 50%;
}}

/* on génère un élément :after lors du survol et du focus :*/

.picto-item:hover:after,
.picto-item:focus:after {{
  content: attr(aria-label);  /* on affiche aria-label */
  position: absolute;
  top: -2.4em;
  left: 50%;
	transform: translateX(-50%); /* on centre horizontalement  */
  z-index: 1; /* pour s'afficher au dessus des éléments en position relative */
  white-space: nowrap;  /* on interdit le retour à la ligne*/
  padding: 5px 14px;
  background: #413219;
  color: #fff;
  border-radius: 4px;
  font-size: 0.7rem;
}}

/* on génère un second élément en :before pour la flèche */

[aria-label]:hover:before,
[aria-label]:focus:before {{
  content: "▼";
  position: absolute;
  top: -1em;
	left: 50%;
	transform: translateX(-50%); /* on centre horizontalement  */
  font-size: 14px;
  color: #413219;
}}

/* pas de contour durant le :focus */
[aria-label]:focus {{
  outline: none;
}}

.picto-item {{
  display: inline-flex;
  justify-content: center;
  align-items: center;
  margin: 3em 2em  1.5em  2e;
  width: 1.2em;
  height: 1.2em;
  color: #413219;
  background: #A0A0A0;
  font-size: 0.95rem;
  text-align: center;
  text-decoration: none;
}}


</style>

<script src="https://code.highcharts.com/highcharts.js"></script>
<script src="https://code.highcharts.com/modules/exporting.js"></script>
<script src="https://code.highcharts.com/modules/accessibility.js"></script>
<script src="https://code.highcharts.com/modules/export-data.js"></script>
<script src="https://code.highcharts.com/modules/drilldown.js"></script>
<figure class="highcharts-figure">
	<div>
    <div id="container">
  </div>
</div>


<p class="highcharts-description">
 {if ($locale='en') then (
   <small class="caption"><a class="picto-item" aria-label="Source and documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁</a>  <a class="picto-item" aria-label="This graph describes the share of the different types of documents in the Gallica collection, with a breakdown by provenance for each." href="#">≡</a> <a  class="picto-item" aria-label="French" href="http://localhost:8984/rest?run=plotDataviz_types_drill.xq&amp;target=bnf_and_integrated&amp;locale=fr">⚐</a></small>) else
  (<small class="caption"><a class="picto-item" aria-label="Source et documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁ </a>  <a class="picto-item" aria-label="Ce graphe décrit la part des différents types de document de la collection Gallica, avec pour chacun la répartition par provenance." href="#">≡</a> <a  class="picto-item" aria-label="English" href="http://localhost:8984/rest?run=plotDataviz_types_drill.xq&amp;target=bnf_and_integrated&amp;locale=en">⚐</a></small>)}
 </p>
</figure>
</body>
</html>
};


(: execution des requetes sur les bases :)
let $data := collection($DBall) 
return
    local:createOutput($data)

