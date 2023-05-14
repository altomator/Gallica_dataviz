(:
 Produce a pie by partners 
:)

import module namespace gd = "http:/gallicaviz.bnf.fr/" at "../webapp/dataviz_lib.xqm";
import module namespace gdp = "http:/gallicaviz.bnf.fr/env" at "../webapp/dataviz_env.xqm";

declare namespace functx = "http://www.functx.com";

declare option output:method 'html';

(: Arguments avec valeurs par defaut :)
(: cible de l'analyse :)
declare variable $target as xs:string external := "integrated"  ;  (: full, bnf_and_integrated, bnf, partners, integrated, harvested  :)
declare variable $locale as xs:string external := "fr" ; 

(: Parameters :)
declare variable $DBtarget as xs:string  := concat("gallica_prov_", $target) ; 
(: the full collection :)
declare variable $DBall as xs:string external := "gallica_prov_full" ;
   
declare variable $width as xs:integer := 850 ;
declare variable $height as xs:integer := 650 ;

(: construction de la page HTML :)
declare function local:createOutput($db) {
<html>
{
(: the whole number of documents :)  
let $rawTotalAll := data(collection($DBall)//total)
let $totalAll := gd:number($rawTotalAll, $locale)
let $targetName := if ($locale='fr') then (data($db//source_fr)) else (data($db//source))
let $processingDate := xs:date($db//date)
let $date := gd:date($processingDate, $locale)

(: URLs :) 
let $urlsTarget := $db//search/item 
let $urlTotalTarget := $db//total_url

(: Data :)
let $totalData := count($db//collection/item)
(: to suppress the last item = other category 
let $colls := if ($locale='fr') then ($db/root/data/query/collection_fr/item[position() < last()]) else ($db/root/data/query/collection/item[position() < last()]) :)

let $colls := if ($locale='fr') then ($db//collection_fr/item) else ($db//collection/item)
let $data := $db//sru/item
let $rawTotal := sum($data)
let $total := gd:number($rawTotal,$locale) 
let $title := if ($locale='fr') then (concat ("Analyse par partenaire pour la provenance : ",$targetName," &#x2014; Total : ",$total, "/",$totalAll)) else 
(concat ("Analysis by partner for provenance: ",$targetName," &#x2014;Total: ", $total,"/",$totalAll))
let $subTitle := gdp:subtitle($date, $locale)

let $collsData := for $c at $position in $colls 
  let $stringData := concat('	{
				name: "',data($c),'",  
				y: ',data($data[$position]),', ',
         (if ($position != $totalData) then (concat('url: "',$gdp:SRU, $urlsTarget[$position],'"'))  else (' ')),
        '}', (if ($position != $totalData) then ',') ,codepoints-to-string(10)
    )
  return $stringData
return
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"></meta>
<title>{$title}</title>
<link rel="stylesheet" type="text/css" href="/static/dataviz.css"></link>
<style>
.highcharts-description  {{
    max-width: {$width}px;
}}
.highcharts-figure,
.highcharts-data-table  {{
    max-width: {$width}px;
}}
.scope-description  {{
    max-width: {$width}px;
}}
</style>
<script src="/static/he.js"></script>
<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
<script src="https://code.highcharts.com/highcharts.js"></script>
<script src="https://code.highcharts.com/modules/exporting.js"></script>
<script src="https://code.highcharts.com/modules/accessibility.js"></script>
<script src="https://code.highcharts.com/modules/export-data.js"></script>
<script type="text/javascript">
$(function () {{
	var pieColors = (function () {{
			var colors = [],
					base = "{$gdp:partnersStartColor}", //  pie color  
					i;
			for (i = 0; i != 20; i += 1) {{
					colors.push(Highcharts.color(base).brighten((i - 1) / 20).get())
			}}
			return colors;
	}}());

function formatNumbers (val,digits) {{
  if (String('{$locale}') == 'fr') {{
       sep = ' ' 
       dec = ','  
     }} else {{
       sep = ',' 
       dec = '.'
     }}  
  return Highcharts.numberFormat(val,digits,dec,sep)
}};

$('#container').highcharts({{
chart: {{
	type: "pie",
  backgroundColor: "{$gdp:backgroundColor}",
	spacingBottom: 30,
  spacingTop: 30,
  spacingLeft: 10,
  spacingRight: 10,
  // Explicitly tell the width and height of a chart
  width: {$width},
  height: {$height}
}},
title: {{
   margin: {$gdp:marginTop},
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
     return  '<b>' + this.point.name + '</b>' + ' :<br></br>'+ formatNumbers(this.y, 0) + '{gdp:labelOn($locale)}' + formatNumbers(this.total, 0);
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
		startAngle: 360,
		allowPointSelect: true,
		cursor: "pointer",
		//colors: pieColors,
		dataLabels: {{
			enabled: true,
			formatter: function () {{
       return '<a target="_blank" href="' + this.point.url + '">'+ this.point.name  + '{gdp:colon($locale)}' + formatNumbers(this.point.percentage,{$gdp:labelDigits}) + '{gdp:percent($locale)}' + '</a>';      
     }}
		}},
		showInLegend: true
	}}
}},
series: [
	{{
		name: "{gdp:partnersCriteria($locale)}",
		colorByPoint: true,
    colors: pieColors,
    innerSize: '40%',
    dataLabels: {{
                style: {{
                    fontSize: {$gdp:labelSmallSize},
                    color: "{$gdp:labelColor}",
                    textOutline: "{$gdp:labelOutline}"   
                }}, 
                distance: 10              
            }},
		data: [
      {$collsData}     
		]
	}} 
  ,{{  // small pie on top left corner
            type: 'pie',
            startAngle:180,
            name: 'Ratio', 
            dataLabels: {{
                style: {{
                    fontSize: {$gdp:smallPieLabelSize},
                    textOutline: "none",
                    color: "{$gdp:smallPieLabelColor}"                                 
                }},
                enabled: true,
                distance: 0
              }},      
            data: [{{
                name: '{gdp:other($locale)}',
                y: {$rawTotalAll - $rawTotal},
                color: "{$gdp:otherInnerColor}",
            }},    
           {{ 
           		name: '{data($targetName)}',
							 y: {$rawTotal},
               url: '{$gdp:SRU}{data($urlTotalTarget)}',           
               color: {$gdp:partnersColors(data($targetName))}  
					 }}],
            center: [80, -20],
            size: 60,
            showInLegend: false
        }}  
]
    }});
}});
</script>
</head>
}
<body>
<figure class="highcharts-figure">
	<div>
    <div id="container"></div>
</div>
{if ($locale='fr') then (<p class="scope-description">Collections : <a title ="Les documents numériques des partenaires de la BnF consultables dans Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_partners.xq&amp;target=integrated&amp;locale=fr">intégrés</a> &#x2022; <a title ="Les documents numériques des partenaires de la BnF référencés dans Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_partners.xq&amp;target=harvested&amp;locale=fr">moissonnés</a></p> ) 
else
(<p class="scope-description">Collections: <a title ="Digital documents from the BnF&#8217;s partners available in Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_partners.xq&amp;target=integrated&amp;locale=en">integrated</a> &#x2022; <a title ="Digital documents from the BnF&#8217;s partners listed in Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_partners.xq&amp;target=harvested&amp;locale=en">harvested</a></p>)}

<p class="highcharts-description">
 {if ($locale='en') then (
   <small class="caption"><a class="picto-item" aria-label="Source and documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁</a>  <a class="picto-item" aria-label="This graph analyses the distribution of document types according to the different provenances that make up Gallica." href="#">≡</a> <a  class="picto-item" aria-label="French" href="{$gdp:appPrefix}/rest?run=plotDataviz_partners.xq&amp;target={$target}&amp;locale=fr">⚐</a></small>) else
  (<small class="caption"><a class="picto-item" aria-label="Source et documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁ </a>  <a class="picto-item" aria-label="Ce graphe analyse la répartition par types de documents en fonction des différentes provenances constituant Gallica." href="#">≡</a> <a  class="picto-item" aria-label="English" href="{$gdp:appPrefix}/rest?run=plotDataviz_partners.xq&amp;target={$target}&amp;locale=en">⚐</a></small>)}
 </p>
</figure>
</body>
</html>
};


(: execution de la requete sur la base :)
let $data := collection($DBtarget) 
return
    local:createOutput($data)
