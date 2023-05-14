(:
  Produce a pie regarding document types ratios
:)

import module namespace gd = "http:/gallicaviz.bnf.fr/" at "../webapp/dataviz_lib.xqm";
import module namespace gdp = "http:/gallicaviz.bnf.fr/env" at "../webapp/dataviz_env.xqm";


declare namespace functx = "http://www.functx.com";

declare option output:method 'html';

(: Arguments avec valeurs par defaut :)
(: cible de l'analyse :)
declare variable $target as xs:string external := "full"  ;  (: full, bnf_and_integrated, bnf, partners, integrated, harvested  :)
declare variable $locale as xs:string external := "fr" ; 

(: Parameters :)
declare variable $DBtarget as xs:string  := concat("gallica_types_", $target) ; 
(: the full collection :)
declare variable $DBall as xs:string external := "gallica_types_full" ;

declare variable $width as xs:integer := 900 ;
declare variable $height as xs:integer := 610 ;

(: construction de la page HTML :)
declare function local:createOutput($db) {
<html>
{
(: the whole number of documents :)  
let $totalAll := data(collection($DBall)//total )

let $targetName := if ($locale='fr') then (data($db//source_fr)) else (data($db//source))
let $processingDate := xs:date($db//date)
let $date := gd:date($processingDate, $locale)

(: URLs :) 
let $urlTarget := $db//search/item 
let $urlTotalTarget := $db/root/data/query/total_url
(: Data :)
let $totalData := count($db//collection/item)
let $colls := if ($locale='fr') then ($db//collection_fr/item) else ($db//collection/item)
let $data := $db//sru/item
let $rawTotal := sum($data)
let $total := gd:number($rawTotal,$locale)
let $title := if ($locale='fr') then (concat ("Analyse par type de document pour la provenance : ",$targetName," &#x2014; Total : ",$total)) else 
(concat ("Analysis by document type for provenance: ",$targetName," &#x2014;Total: ", $total))
let $subTitle := gdp:subtitle($date, $locale)

let $collsData := for $c at $position in $colls 
  let $stringData := concat('	{
    ',
    (if ($c eq "video")  then 'sliced: true, ' else (if ($c eq "sonore")  then 'sliced: true, ' )),'
				name: "',data($c),'",
        color: "',data($gdp:gallicaTypesColors($c)),'",  
				y: ',data($data[$position]),',
        url: "',concat($gdp:SRU, data($urlTarget[$position])),'"
        }', (if ($position != $totalData) then ',') ,codepoints-to-string(10)
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
<script src="https://highcharts.github.io/pattern-fill/pattern-fill-v2.js"></script>

<script type="text/javascript">
$(function () {{

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
  backgroundColor: '{$gdp:backgroundColor}',
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
		startAngle: 90,
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
		name: "{gdp:typesCriteria($locale)}",
		colorByPoint: true,
    innerSize: '40%',
    dataLabels: {{
              style: {{
                    fontSize: {$gdp:labelSize},
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
            startAngle: 90,
            name: 'Ratio',       
            data: [{{
                name: '{gdp:other($locale)}',
                y: {$totalAll - $rawTotal},
                color: "{$gdp:otherInnerColor}",
            }},    
           {{ 
           		name: '{data($targetName)}',
							 y: {$rawTotal},
               url: '{$gdp:SRU}{data($urlTotalTarget)}',           
               color: {$gdp:partnersColors(data($targetName))}   
					 }}],
            center: [100, -10],
            size: 60,
            showInLegend: false,
            dataLabels: {{
                 style: {{
                    fontSize: {$gdp:smallPieLabelSize},
                    textOutline: "none",
                    color: "{$gdp:smallPieLabelColor}"                                 
                }},
                enabled: true,
                distance: 0               
            }}
        }} ]
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
{if ($locale='fr') then (<p class="scope-description">Collections : <a title ="Toute la collection Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_types.xq&amp;target=full&amp;locale=fr">Complète</a> &#x2022; <a title ="Les documents numériques de la BnF et de ses partenaires consultables dans Gallica"  href="{$gdp:appPrefix}/rest?run=plotDataviz_types.xq&amp;target=bnf_and_integrated&amp;locale=fr">BnF et intégrés</a> &#x2022; <a title="Les documents numériques de la BnF" href="{$gdp:appPrefix}/rest?run=plotDataviz_types.xq&amp;target=bnf&amp;locale=fr">BnF</a> &#x2022; <a title ="Les documents numériques des partenaires de la BnF (intégrés et moissonnés)"  href="{$gdp:appPrefix}/rest?run=plotDataviz_types.xq&amp;target=partners&amp;locale=fr">partenaires</a> &#x2022; <a title ="Les documents numériques des partenaires de la BnF consultables dans Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_types.xq&amp;target=integrated&amp;locale=fr">intégrés</a> &#x2022; <a title ="Les documents numériques des partenaires de la BnF référencés dans Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_types.xq&amp;target=harvested&amp;locale=fr">moissonnés</a></p> ) 
else
(<p class="scope-description">Collections: <a title ="All the Gallica collection" href="{$gdp:appPrefix}/rest?run=plotDataviz_types.xq&amp;target=full&amp;locale=en">Full</a> &#x2022; <a title ="Digital documents from BnF and its partners available in Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_types.xq&amp;target=bnf_and_integrated&amp;locale=en">BnF and integrated</a> &#x2022; <a title ="Digital documents from BnF" href="{$gdp:appPrefix}/rest?run=plotDataviz_types.xq&amp;target=bnf&amp;locale=en">BnF</a> &#x2022; <a title ="Digital documents from BnF&#8217;s partners (integrated and harvested)" href="{$gdp:appPrefix}/rest?run=plotDataviz_types.xq&amp;target=partners&amp;locale=en">partners</a> &#x2022; <a title ="Digital documents from the BnF&#8217;s partners available in Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_types.xq&amp;target=integrated&amp;locale=en">integrated</a> &#x2022; <a title ="Digital documents from the BnF&#8217;s partners listed in Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_types.xq&amp;target=harvested&amp;locale=en">harvested</a></p>)}

<p class="highcharts-description">
 {if ($locale='en') then (
   <small class="caption"><a class="picto-item" aria-label="Source and documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁</a>  <a class="picto-item" aria-label="This graph analyses the distribution of document types according to the different provenances that make up Gallica." href="#">≡</a> <a  class="picto-item" aria-label="French" href="{$gdp:appPrefix}/rest?run=plotDataviz_types.xq&amp;target={$target}&amp;locale=fr">⚐</a></small>) else
  (<small class="caption"><a class="picto-item" aria-label="Source et documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁ </a>  <a class="picto-item" aria-label="Ce graphe analyse la répartition par types de documents en fonction des différentes provenances constituant Gallica." href="#">≡</a> <a  class="picto-item" aria-label="English" href="{$gdp:appPrefix}/rest?run=plotDataviz_types.xq&amp;target={$target}&amp;locale=en">⚐</a></small>)}
 </p>
</figure>
</body>
</html>
};


(: execution de la requete sur la base :)
let $data := collection($DBtarget) 
return
    local:createOutput($data)
