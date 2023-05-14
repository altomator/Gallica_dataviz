(:
 Produce a pie regarding digitisation programs  
:)

import module namespace gd = "http:/gallicaviz.bnf.fr/" at "../webapp/dataviz_lib.xqm";
import module namespace gdp = "http:/gallicaviz.bnf.fr/env" at "../webapp/dataviz_env.xqm";

declare namespace functx = "http://www.functx.com";

declare option output:method 'html';

(: Arguments avec valeurs par defaut :)
(: cible de l'analyse :)
declare variable $target as xs:string external  ; (: monograph / periodical  :)
declare variable $locale as xs:string external := "fr" ; (: langue: fr/en :)
 
(: Parameters :) 
(: DBs :)
declare variable $DBall as xs:string external := concat("gallica_programs_bnf_and_integrated_", $target) ;
declare variable $DBtarget as xs:string  := concat("gallica_programs_bnf_and_integrated_ocr_", $target) ;

declare variable $width as xs:integer := 1000 ; (: width of the chart's frame:)   
declare variable $height as xs:integer := 610 ;

(: construction de la page HTML :)
declare function local:createOutput($db) {
<html>
{
let $processingDate := xs:date($db//date)
let $date := gd:date($processingDate, $locale)
let $nData := count($db/root/data/query/collection/item)

let $dbTarget := collection($DBtarget)

(: URLs for the drill :) 
let $urlAll := $db//search/item 
let $urlTarget := $dbTarget//search/item
let $urlTotalTarget := $dbTarget//total_url 
let $noOcrUrlTotalTarget := replace(data($urlTotalTarget),'ocr.','not%20ocr.')

let $colls := if ($locale='fr') then ($db//collection_fr/item) else ($db//collection/item)
let $full := if ($locale='fr') then ($db//source_fr) else ($db//source)

let $collName := if ($locale='fr') then ($dbTarget//target_fr) else ($dbTarget//target)
(: data :)
let $data := $db//sru/item
let $rawTotal := data($db//total)
let $rawTotalP := data($db//total_p)

let $total := gd:number($rawTotal,$locale)
let $total_p := gd:number($rawTotalP,$locale) 

(: data from the sub collection : OCR :)  
let $dataTarget := $dbTarget//sru/item
let $rawTarget := data($dbTarget//total)
let $totalTarget := gd:number($rawTarget,$locale)
let $totalOther := $rawTotal - $rawTarget

let $title := if ($locale='fr') then (concat ("Analyse par programmes de numérisation &#x2014;  Collection : ",$full," (", $collName,") &#x2014; Total : ",$total_p,"/",$total)) else 
(concat ("Analysis by digitization programs &#x2014; Collection: ",$full," (", $collName,") &#x2014; Total: ", $total,"/",$totalTarget))
let $subTitle := gdp:subtitle($date, $locale)

let $collsData := for $c at $position in $colls 
  let $stringData := concat('	{ 
   ',
    (if ($c eq "Proquest")  then 'sliced: true,'  ),' 
				name: "',data($c),'",
				y: ',data($data[$position]),',
        ',
        (if ($position != $nData)  then (concat('  url: "',$gdp:SRU,$urlAll[$position],'",
        '))),
      'drilldown: "',data($c),'"        
        }', (if ($position != $nData) then ',') ,codepoints-to-string(10)
    )
  return $stringData
  
let $collsDrillData := for $c at $position in $colls
  let $ocrUrl :=  data($urlTarget[$position])
  let $noOcrUrl := replace($ocrUrl,'ocr.','not%20ocr.')
  let $stringData := concat('	{  
        name: "',data($c),'",
        id: "',data($c),'",    
        data: [       
          { name: "',data(gdp:noOCR ($locale)),'",',
            (if ($c != "other" and $c != "autres") then (concat('
           url: "',$gdp:SRU, $ocrUrl,'",'))),
           '
           color: "', data($gdp:otherInnerColor),'",
           y: ',data($data[$position]-$dataTarget[$position]),'
        },
          {name: "OCR",',
           (if ($c != "other" and $c != "autres") then (concat('
           url: "',$gdp:SRU, $ocrUrl,'",'))),
           '
           color: ',data($gdp:partnersColors($gdp:partnersList[3])),', 
          y: ',data($dataTarget[$position]),'
        }
       ]     
        }', (if ($position != $nData) then ',') ,codepoints-to-string(10)
    )
  return $stringData
return
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"></meta>
<title>{$title}</title>
<link rel="stylesheet" type="text/css" href="/static/dataviz.css"></link>
<style>.highcharts-drilldown-data-label text{{
  text-decoration:none !important;
}};
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
<script src="https://code.highcharts.com/modules/drilldown.js"></script>

<script type="text/javascript">

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

$(function () {{
	var pieColors = (function () {{
			var colors = [],
					base = "{$gdp:progColor }",  
					i;
			for (i = 0; i != 20; i += 1) {{
					colors.push(Highcharts.color(base).brighten((i - 1) / 10).get())
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
  // Explicitly tell the width and height of the chart
  width:  {$width},
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
		startAngle: 0,
		allowPointSelect: true,
		cursor: "pointer",
		colors: pieColors,
		dataLabels: {{
			enabled: true,
			formatter: function () {{
       return '<a target="_blank" href="' + this.point.url + '">'+ this.point.name + '{gdp:colon($locale)}' + formatNumbers(this.point.percentage,{$gdp:labelDigits}) + '{gdp:percent($locale)}' + '</a>';   
     }}
		}},
		showInLegend: true
	}}
}},
series: [
	{{
		name: "{gdp:programsCriteria($locale)}",
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
	}}, {{ // small pie on top left corner
            type: 'pie',
            name: 'Ratio', 
            startAngle: 90,      
            data: [{{
                name: '{gdp:noOCR ($locale)}',
                y: {$totalOther},
                url: '{$gdp:SRU}{data($noOcrUrlTotalTarget)}',
                color: "{$gdp:otherInnerColor}", //no ocr
            }},    
           {{ 
           		name: 'OCR',
							 y: {$rawTarget},
               url: '{$gdp:SRU}{data($urlTotalTarget)}',
               color: {data($gdp:partnersColors($gdp:partnersList[3]))} // bnf_and_integrated color
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
                distance: 0,
                enabled: true
                
            }}
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
<div>
    <div id="container"></div>
</div>
{if ($locale='fr') then (<p class="scope-description">Programmes : <a title ="Les programmes et partenariats de numérisation portant sur les collections de monographies" href="{$gdp:appPrefix}/rest?run=plotDataviz_prog.xq&amp;target=monograph&amp;locale=fr">Monographie</a> &#x2022; <a title ="Les programmes et partenariats de numérisation portant sur les collections de périodiques" href="{$gdp:appPrefix}/rest?run=plotDataviz_prog.xq&amp;target=periodical&amp;locale=fr">Périodique</a></p> ) 
else
(<p class="scope-description">Programs: <a title ="Digitisation programmes and partnerships for monographs" href="{$gdp:appPrefix}/rest?run=plotDataviz_prog.xq&amp;target=monograph&amp;locale=en">Monograph</a> &#x2022; <a title ="Digitisation programmes and partnerships for periodicals" href="{$gdp:appPrefix}/rest?run=plotDataviz_prog.xq&amp;target=periodical&amp;locale=en">Periodical</a></p>)}

<p class="highcharts-description">
 {if ($locale='en') then (
   <small class="caption"><a class="picto-item" aria-label="Source and documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁</a>  <a class="picto-item" aria-label="This graph analyses the BnF&#8217;s digitisation programmes and partnerships for which specific conditions of access to digital documents exist." href="#">≡</a> <a  class="picto-item" aria-label="French" href="{$gdp:appPrefix}/rest?run=plotDataviz_prog.xq&amp;target={$target}&amp;locale=fr">⚐</a></small>) else
  (<small class="caption"><a class="picto-item" aria-label="Source et documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁ </a>  <a class="picto-item" aria-label="Ce graphe analyse les programmes et partenariats de numérisation de la BnF pour lesquels des conditions spécifiques d&#8217;accès aux documents numériques existent." href="#">≡</a> <a  class="picto-item" aria-label="English" href="{$gdp:appPrefix}/rest?run=plotDataviz_prog.xq&amp;target={$target}&amp;locale=en">⚐</a></small>)}
 </p>
</figure>
</body>
</html>
};


(: execution des requetes sur les bases :)
let $data := collection($DBall) 
return
    local:createOutput($data)

