(:
 Recherche de pages illustrees par les annotations
:)

declare namespace functx = "http://www.functx.com";

declare option output:method 'html';

(: Arguments avec valeurs par defaut :)
(: cible de l'analyse :)
declare variable $target as xs:string external := "integrated"  ;  (: full, bnf_and_integrated, bnf, partners, integrated, harvested  :)
declare variable $DBtarget as xs:string  := concat("gallica_prov_", $target) ; 

declare variable $locale as xs:string external := "fr" ; 

(: the full collection :)
declare variable $DBall as xs:string external := "gallica_prov_full" ;
   
(: declare variable $currentDate as xs:date  := current-date(); :)

(: Parameters :)
(: Pie colors :)
declare variable $mainColor as xs:string := "#2A1388" ; (: green  :) 
declare variable $otherInnerColor as xs:string := "#B8B0AE" ; (: gray :)

(: colors for the small pie :)    
declare variable $innerColors := map{
    "BnF":"#040054", 
    "integrated":"#2A1388", 
    "harvested": "#5641C1"};
declare variable $innerColors_fr := map{
    "BnF":"#040054", 
    "intégrés":"#2A1388", 
    "moissonnés": "#5641C1"};
declare variable $innerColors_default as xs:string := "#3d598b";
            
declare variable $other  as xs:string := if ($locale='fr') then ("autres") else ("other");
declare variable $criteria as xs:string :=  if ($locale='fr') then ("Partenaires") else ("Partners") ; (: label of the graph criteria :)
declare variable $width as xs:integer := 850 ;
 
(: URL Gallica SRU de base :)
declare variable $SRU as xs:string external := fn:escape-html-uri("https://gallica.bnf.fr/services/engine/search/sru?operation=searchRetrieve&amp;exactSearch=false&amp;collapsing=false&amp;query=");

declare function local:evalQuery($query) {
    let $hits := xquery:eval($query)
    return $hits
};

(: return a color for a given provenance :)
declare function local:innerColors($prov) {
    let $foo := if ($locale eq "fr") then (map:get( $innerColors_fr, $prov)) else
     (map:get( $innerColors, $prov))
    return (if ($foo) then ($foo) else ($innerColors_default))
};

(: construction de la page HTML :)
declare function local:createOutput($db) {
<html>
{
(: the whole number of documents :)  
let $rawTotalAll := data(collection($DBall)//total)
let $totalAll := if ($locale='fr') then (replace(format-number( $rawTotalAll, '9,999'),',','&#x2009;')) else (format-number($rawTotalAll, '9,999'))

let $targetName := if ($locale='fr') then (data($db//source_fr)) else (data($db//source))
let $processingDate := xs:date($db//date)
let $date := if ($locale='fr') then (format-date($processingDate, "[D]-[M]-[Y]")) else (format-date($processingDate, "[Y]-[M]-[D]"))

(: URLs :) 
let $urlTarget := $db//search/item 
let $urlTotalTarget := $db/root/data/query/total_url

(: Data :)
let $totalData := count($db//collection/item)
let $colls := if ($locale='fr') then ($db/root/data/query/collection_fr/item[position() < last()]) else ($db/root/data/query/collection/item[position() < last()])
let $data := $db//sru/item
let $rawTotal := sum($data)
let $total := if ($locale='fr') then (replace(format-number( $rawTotal, '9,999'),',','&#x2009;')) else (format-number( $rawTotal, '9,999'))
 
let $title := if ($locale='fr') then (concat ("Analyse par partenaire pour la provenance : ",$targetName," &#x2014; Total : ",$total, "/",$totalAll)) else 
(concat ("Analysis by partner for provenance: ",$targetName," &#x2014;Total: ", $total,"/",$totalAll))
let $subTitle := if ($locale='fr') then (concat('Source : <a href="https://gallica.bnf.fr" target="_default">Gallica</a> et <a href="https://api.bnf.fr/fr/api-gallica-de-recherche" target="_default">API Gallica SRU</a> (', $date,')')) else (concat('Source: <a href="https://gallica.bnf.fr" target="_default">Gallica</a> and <a href="https://api.bnf.fr/fr/api-gallica-de-recherche" target="_default">Gallica SRU API</a> (', $date,')'))
let $collsData := for $c at $position in $colls 
  let $stringData := concat('	{
				name: "',data($c),'",  
				y: ',data($data[$position]),',
        url: "',concat($SRU, data($urlTarget[$position])),'"
        }', (if ($position != $totalData) then ',') ,codepoints-to-string(10)
    )
  return $stringData
return
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"></meta>
<title>{$title}</title>
<script src="/static/he.js"></script>
<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
<script type="text/javascript">
$(function () {{
	var pieColors = (function () {{
			var colors = [],
					base = "{$mainColor}", //  pie color  
					i;
			for (i = 0; i != 20; i += 1) {{
					colors.push(Highcharts.color(base).brighten((i - 1) / 20).get())
			}}
			return colors;
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
  width: {$width},
  height: 650
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
                      if(this.options.url!=null) {{
                        // console.log(he.decode(this.options.url)) // decode the &amp; entity
                        window.open(he.decode(this.options.url),'_blank' );
                      }} else{{
                        
         }}
                       
                    }}
                }}
            }}
        }},
	pie: {{
		startAngle: 270,
		allowPointSelect: true,
		cursor: "pointer",
		//colors: pieColors,
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
		name: "values",
		colorByPoint: true,
    colors: pieColors,
    innerSize: '40%',
    dataLabels: {{
                style: {{
                    fontSize: 10   
                }}
            }},
		data: [
      {$collsData}     
		]
	}} 
  ,{{  // small pie on top left corner
            type: 'pie',
            name: 'Ratio',       
            data: [{{
                name: '{$other}',
                y: {$rawTotalAll - $rawTotal},
                color: "{$otherInnerColor}",
            }},    
           {{ 
           		name: '{data($targetName)}',
							 y: {$rawTotal},
               url: '{$SRU}{data($urlTotalTarget)}',           
               color: '{local:innerColors(data($targetName))}'   
					 }}],
            center: [90, -30],
            size: 60,
            showInLegend: false,
            dataLabels: {{
                enabled: true
            }}
        }}  
]
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
<figure class="highcharts-figure">
	<div>
    <div id="container"></div>
</div>
{if ($locale='fr') then (<p class="scope-description">Collections : <a title ="Les documents numériques des partenaires de la BnF (intégrés et moissonnés)"  href="http://localhost:8984/rest?run=plotDataviz_partners.xq&amp;target=partners&amp;locale=fr">partenaires</a> &#x2022; <a title ="Les documents numériques des partenaires de la BnF consultables dans Gallica" href="http://localhost:8984/rest?run=plotDataviz_partners.xq&amp;target=integrated&amp;locale=fr">intégrés</a> &#x2022; <a title ="Les documents numériques des partenaires de la BnF référencés dans Gallica" href="http://localhost:8984/rest?run=plotDataviz_partners.xq&amp;target=harvested&amp;locale=fr">moissonnés</a></p> ) 
else
(<p class="scope-description">Collections:  <a title ="Digital documents from BnF&#8217;s partners (integrated and harvested)" href="http://localhost:8984/rest?run=plotDataviz_partners.xq&amp;target=partners&amp;locale=en">partners</a> &#x2022; <a title ="Digital documents from the BnF&#8217;s partners available in Gallica" href="http://localhost:8984/rest?run=plotDataviz_partners.xq&amp;target=integrated&amp;locale=en">integrated</a> &#x2022; <a title ="Digital documents from the BnF&#8217;s partners listed in Gallica" href="http://localhost:8984/rest?run=plotDataviz_partners.xq&amp;target=harvested&amp;locale=en">harvested</a></p>)}

<p class="highcharts-description">
 {if ($locale='en') then (
   <small class="caption"><a class="picto-item" aria-label="Source and documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁</a>  <a class="picto-item" aria-label="This graph analyses the distribution of document types according to the different provenances that make up Gallica." href="#">≡</a> <a  class="picto-item" aria-label="French" href="http://localhost:8984/rest?run=plotDataviz_partners.xq&amp;target={$target}&amp;locale=fr">⚐</a></small>) else
  (<small class="caption"><a class="picto-item" aria-label="Source et documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁ </a>  <a class="picto-item" aria-label="Ce graphe analyse la répartition par types de documents en fonction des différentes provenances constituant Gallica." href="#">≡</a> <a  class="picto-item" aria-label="English" href="http://localhost:8984/rest?run=plotDataviz_partners.xq&amp;target={$target}&amp;locale=en">⚐</a></small>)}
 </p>
</figure>
</body>
</html>
};


(: execution de la requete sur la base :)
let $data := collection($DBtarget) 
return
    local:createOutput($data)
