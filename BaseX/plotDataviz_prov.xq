(:
 Produce a pyramid by provenance, with drilldown 
:)

import module namespace gd = "http:/gallicaviz.bnf.fr/" at "../webapp/dataviz_lib.xqm";
import module namespace gdp = "http:/gallicaviz.bnf.fr/env" at "../webapp/dataviz_env.xqm";

declare namespace functx = "http://www.functx.com";

declare option output:method 'html';

(: Arguments avec valeurs par defaut :)
(: nom de la base BaseX :)
declare variable $DBall as xs:string external := "gallica_prov_full" ;
declare variable $locale as xs:string external := "fr" ; (: langue: fr/en :) 

(: declare variable $currentDate as xs:date  := current-date(); :)

(: Parameters : see also module gdp :)
declare variable $DBprefix as xs:string := "gallica_prov_" ;
declare variable $width as xs:integer := 900 ;
declare variable $height as xs:integer := 680 ;
   
(: construction de la page HTML :)
declare function local:createOutput($db) {
<html>
{
let $processingDate := xs:date($db//date)
let $date := gd:date($processingDate,$locale)

(: data for provenances :)
let $totalData := count($db//source/item)
let $sources := if ($locale='fr') then ($db//collection_fr/item) else ($db//collection/item)
let $dataSources := $db//sru/item
let $dataURL := $db//search/item
let $total := gd:number(sum($dataSources),$locale)
let $title := if ($locale='fr') then (concat ("Analyse de la collection par provenance &#x2014; Total : ",$total)) else 
(concat ("Analysis of the collection by provenance &#x2014; Total: ", $total))
let $subTitle := gdp:subtitle($date, $locale)
let $collsData := for $c at $position in $sources 
  let $stringData := concat('	{
				name: "',data($c),'",
				y: ',data($dataSources[$position]),',
        url: "',concat($gdp:SRU,data($dataURL[$position])),'",
				drilldown: "',data($c),'"        
        }', (if ($position != $totalData) then ',') ,codepoints-to-string(10)
    )
  return $stringData
  
let $collsDrillData := for $s at $position in $sources 
  let $stringData := concat(' {  
        name: "',data($s),'",
        id: "',data($s),'",
        dataLabels: {
                style: {
                    fontSize: ',$gdp:labelSmallSize,',
                    color: "',$gdp:labelColor,'",
                    textOutline: "', $gdp:labelOutline,'"                         
                }
            },    
        data: [ ',
           let $DBname := (if ($locale="fr") then (map:get($gdp:provNameFR2EN, $s)) else ($s))
           let $libraries := collection(concat($DBprefix,$DBname)) 
           let $totalLib := count($libraries//collection/item)
           let $tmp := for $l at $pos in (if ($locale='fr') then ($libraries//collection_fr/item) else ($libraries//collection/item))
           return concat('{ name: "',
           data($l),'",
           ',
           if (data($libraries//search/item[$pos])) then (concat('url: "',$gdp:SRU,data($libraries//search/item[$pos]),'",
           ')),
           'color: "', $gdp:provDrillColors[$pos],'", 
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
<link rel="stylesheet" type="text/css" href="/static/dataviz.css"></link>
<style>
	.highcharts-description  {{
    max-width: {$width}px;
}}
.highcharts-figure,
.highcharts-data-table  {{ 
    max-width: {$width}px;
}}
</style>
<script src="/static/he.js"></script>
<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
<script src="https://code.highcharts.com/highcharts.js"></script>
<script src="https://code.highcharts.com/modules/exporting.js"></script>
<script src="https://code.highcharts.com/modules/accessibility.js"></script>
<script src="https://code.highcharts.com/modules/export-data.js"></script>
<script src="https://code.highcharts.com/modules/drilldown.js"></script>
<script src="https://code.highcharts.com/modules/funnel.js"></script>


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
  
  
var pieColors = (function () {{
			var colors = [],
					base = "{$gdp:provColor}", 
					i;
			for (i = 0; i != 20; i += 1) {{
					colors.push(Highcharts.color(base).brighten((i - 2) / 5).get())
			}}
			return colors;
	}}());

$('#container').highcharts({{
chart: {{
	type: "pyramid",
  backgroundColor: "{$gdp:backgroundColor}",
	spacingBottom: 30,
  spacingTop: 40,
  spacingLeft: 10,
  spacingRight: 100,
  // Explicitly tell the width and height of a chart
  width:  {$width},
  height: {$height}
}},
title: {{
   margin:  {$gdp:marginTop},
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
      style: {{
                    fontSize: {$gdp:labelSmallSize},
                    color: "{$gdp:labelColor}",
                    textOutline: "{$gdp:labelOutline}"                                     
                }},
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
		name: "{$gdp:provCriteria}",
		colorByPoint: true,
    innerSize: '40%',
    dataLabels: {{
                style: {{
                    fontSize: {$gdp:labelSize},
                    textOutline: "{$gdp:labelOutline}",
                    color: "{$gdp:labelColor}"                                 
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
<figure class="highcharts-figure">
	<div >
    <div id="container"></div>
</div>
<p class="highcharts-description">
 {if ($locale='en') then (
   <small class="caption"><a class="picto-item" aria-label="Source and documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁</a>  <a class="picto-item" aria-label="This graph analyses Gallica in its different components: the BnF&#8217;s collection, that of its partners (integrated when their documents can be consulted in Gallica, harvested otherwise)." href="#">≡</a> <a  class="picto-item" aria-label="French" href="{$gdp:appPrefix}/rest?run=plotDataviz_prov.xq&amp;locale=fr">⚐</a></small>) else
  (<small class="caption"><a class="picto-item" aria-label="Source et documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁ </a>  <a class="picto-item" aria-label="Ce graphe analyse Gallica dans ses  différentes composantes : la collection de la BnF, celle de ses partenaires (intégrés lorsque leurs documents sont consultables dans Gallica, moissonnés sinon)." href="#">≡</a> <a  class="picto-item" aria-label="English" href="{$gdp:appPrefix}/rest?run=plotDataviz_prov.xq&amp;locale=en">⚐</a></small>)}
 </p>
</figure>
</body>
</html>
};


(: execution des requetes sur les bases :)
let $data := collection($DBall) 
return
    local:createOutput($data)

