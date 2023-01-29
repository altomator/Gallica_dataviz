(:
 Recherche de pages illustrees par les annotations
:)

declare namespace functx = "http://www.functx.com";

declare option output:method 'html';

(: Arguments avec valeurs par defaut :)

(: nom de la base BaseX :)
declare variable $DBall as xs:string external := "gallica_prov_full" ;
declare variable $locale as xs:string external := "fr" ; (: langue: fr/en :)
   
(: declare variable $currentDate as xs:date  := current-date(); :)

declare variable $DBprefix as xs:string := "gallica_prov_" ;

(: Parameters :)
(: Pie colors :)
declare variable $mainColor as xs:string := "#6A5ACD" ; (: "SlateBlue" :)
(: Drill colors :)
declare variable $drillColors := ("#250b3b" ,"#371456", "#371357", "#4a2569", "#4c018d", "#5c1c95", "#6f29ac",  "#6e26af",   "#8140b9",   "#8502f7", "#9342db", "#a466da", "#a464dc", "#b58dd7","#b767fd",
"#c69cec", "#c88afe", "#e3c4fe", "lightgray") ;  (: inner colors:)

declare variable $criteria as xs:string :=  if ($locale='fr') then ("Provenances") else ("Provenances") ; (: label of the graph criteria :)

declare variable $width as xs:integer := 800 ;
 
(: URL Gallica de base :)
declare variable $SRU as xs:string external := fn:escape-html-uri("https://gallica.bnf.fr/services/engine/search/sru?operation=searchRetrieve&amp;exactSearch=false&amp;collapsing=false&amp;query=");

declare function local:evalQuery($query) {
    let $hits := xquery:eval($query)
    return $hits
};

(: convert source category to DB name:)
declare variable $sourceName := map{
    "BnF":"bnf", 
    "intégrés":"integrated", 
    "moissonnés":"harvested"
   };
    
(: construction de la page HTML :)
declare function local:createOutput($db) {
  
<html>
{
let $processingDate := xs:date($db//date)
let $date := if ($locale='fr') then (format-date($processingDate, "[D]-[M]-[Y]")) else (format-date($processingDate, "[Y]-[M]-[D]"))
let $other := if ($locale='fr') then ("autres") else ("other")

 
(: data for provenances :)
let $totalData := count($db//source/item)
let $sources := if ($locale='fr') then ($db//collection_fr/item) else ($db//collection/item)
let $dataSources := $db//sru/item
let $dataURL := $db//search/item

let $total := if ($locale='fr') then (replace(format-number(sum($dataSources), '9,999'),',','&#x2009;')) else (format-number(sum($dataSources), '9,999')) 
let $title := if ($locale='fr') then (concat ("Analyse de la collection par provenance &#x2014; Total : ",$total)) else 
(concat ("Analysis of the collection by provenance &#x2014; Total: ", $total))
let $subTitle := if ($locale='fr') then (concat('Source : <a href="https://gallica.bnf.fr" target="_default">Gallica</a> et <a href="https://api.bnf.fr/fr/api-gallica-de-recherche" target="_default">API Gallica SRU</a> (', $date,')')) else (concat('Source: <a href="https://gallica.bnf.fr" target="_default">Gallica</a> and <a href="https://api.bnf.fr/fr/api-gallica-de-recherche" target="_default">Gallica SRU API</a> (', $date,')'))
let $collsData := for $c at $position in $sources 
  let $stringData := concat('	{
				name: "',data($c),'",
				y: ',data($dataSources[$position]),',
        url: "',concat($SRU,data($dataURL[$position])),'",
				drilldown: "',data($c),'"        
        }', (if ($position != $totalData) then ',') ,codepoints-to-string(10)
    )
  return $stringData
  
let $collsDrillData := for $s at $position in $sources 
  let $stringData := concat(' {  
        name: "',data($s),'",
        id: "',data($s),'",    
        data: [ ',
           let $DBname := (if ($locale="fr") then (map:get($sourceName, $s)) else ($s))
           let $libraries := collection(concat($DBprefix,$DBname)) 
           let $totalLib := count($libraries//collection/item)
           let $tmp := for $l at $pos in (if ($locale='fr') then ($libraries//collection_fr/item) else ($libraries//collection/item))
           return concat('{ name: "',
           data($l),'",
           ',
           if (data($libraries//search/item[$pos])) then (concat('url: "',$SRU,data($libraries//search/item[$pos]),'",
           ')),
           'color: "', $drillColors[$pos],'", 
           y: ',data($libraries//sru/item[$pos]),'
         }', (if ($pos != $totalLib) then ',') ,codepoints-to-string(10))
         return string-join($tmp,' '),
      
       ']     
       }', (if ($position != $totalData) then ','), codepoints-to-string(10)
    )
  return string($stringData)
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
	var pieColors = (function () {{
			var colors = [],
					base = "{$mainColor}", 
					i;
			for (i = 0; i != 20; i += 1) {{
					colors.push(Highcharts.color(base).brighten((i - 2) / 5).get())
			}}
			return colors;
	}}());

  
$('#container').highcharts({{
chart: {{
	type: "pyramid",
  backgroundColor: "#EBEBEB",
	spacingBottom: 30,
  spacingTop: 40,
  spacingLeft: 10,
  spacingRight: 100,
  // Explicitly tell the width and height of a chart
  width:  {$width},
  height: 680
}},
title: {{
   margin: 50,
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
                      if(this.options.url) {{                        
                        window.open(he.decode(this.options.url),'_blank' );
                      }} else{{                   
         }}                     
                    }}
                }}
            }}
        }},
	pyramid: {{
		allowPointSelect: true,
		cursor: "pointer",
		colors: pieColors,
    
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
       return '<a target="_blank" href="' + this.point.url + '">'+ this.point.name  + colon + Highcharts.numberFormat(this.point.percentage, 2,dec,sep) + per + '</a>'; 
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
                    textOutline: "none"
                                        
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
<script src="https://code.highcharts.com/modules/funnel.js"></script>
<script src="https://code.highcharts.com/modules/pyramid.js"></script>

<figure class="highcharts-figure">
	<div >
    <div id="container"></div>
</div>
<p class="highcharts-description">
 {if ($locale='en') then (
   <small class="caption"><a class="picto-item" aria-label="Source and documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁</a>  <a class="picto-item" aria-label="This graph analyses Gallica in its different components: the BnF&#8217;s collection, that of its partners (integrated when their documents can be consulted in Gallica, harvested otherwise)." href="#">≡</a> <a  class="picto-item" aria-label="French" href="http://localhost:8984/rest?run=plotDataviz_prov.xq&amp;locale=fr">⚐</a></small>) else
  (<small class="caption"><a class="picto-item" aria-label="Source et documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁ </a>  <a class="picto-item" aria-label="Ce graphe analyse Gallica dans ses  différentes composantes : la collection de la BnF, celle de ses partenaires (intégrés lorsque leurs documents sont consultables dans Gallica, moissonnés sinon)." href="#">≡</a> <a  class="picto-item" aria-label="English" href="http://localhost:8984/rest?run=plotDataviz_prov.xq&amp;locale=en">⚐</a></small>)}
 </p>
</figure>
</body>
</html>
};


(: execution des requetes sur les bases :)
let $data := collection($DBall) 
return
    local:createOutput($data)

