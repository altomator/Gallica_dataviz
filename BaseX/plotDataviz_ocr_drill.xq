(:
 Produce a pie regarding ocerised documents types 
:)

import module namespace gd = "http:/gallicaviz.bnf.fr/" at "../webapp/dataviz_lib.xqm";
import module namespace gdp = "http:/gallicaviz.bnf.fr/env" at "../webapp/dataviz_env.xqm";

declare namespace functx = "http://www.functx.com";

declare option output:method 'html';

(: Arguments avec valeurs par defaut :)
(: cible de l'analyse :)
declare variable $target as xs:string external := "bnf_and_integrated"  ; (: full, bnf_and_integrated, bnf, partners, integrated, harvested  :)
declare variable $locale as xs:string external := "fr" ; (: langue: fr/en :)


(: Parameters :)
(: DBs :)
declare variable $DBall as xs:string external := concat("gallica_ocr_", $target) ;
declare variable $DBtarget as xs:string  := concat("gallica_ocr_", $target,"-ocr") ; 

declare variable $width as xs:integer := 900 ;
declare variable $height as xs:integer := 610 ;

(: construction de la page HTML :)
declare function local:createOutput($db) {
<html>
{
let $processingDate := xs:date($db//date)
let $date := gd:date($processingDate, $locale)
let $nData := count($db//collection/item)

let $colls := if ($locale='fr') then ($db//collection_fr/item) else ($db//collection/item)

let $dbTarget := collection($DBtarget)
let $targetName := if ($locale='fr') then ($dbTarget//source_fr) else ($dbTarget//source)

(: URLs  :) 
let $urlAll := $db//search/item 
let $urlTarget := $dbTarget//search/item 
let $urlTotalTarget := $dbTarget//total_url 
let $noOcrUrlTotalTarget := replace(data($urlTotalTarget),'ocr.','not%20ocr.')

(: data from the whole collection :)
let $data := $db//sru/item
let $rawTotal := data($db//total)
let $total := gd:number($rawTotal,$locale) 

(: data from the targeted collection ()  :)  
let $dataTarget := $dbTarget//sru/item
let $rawTarget := data($dbTarget//total)
let $totalTarget := gd:number($rawTarget,$locale)
let $totalOther := $rawTotal - $rawTarget

let $title := if ($locale='fr') then (concat ("Analyse des collections avec OCR &#x2014; Collection numérique : ",$targetName, " &#x2014; Total : ",$totalTarget,"/",$total)) else 
(concat ("Analysis of the OCRed collections &#x2014; Digital collection: ",$targetName," &#x2014; Documents: ", $totalTarget,"/",$total))
let $subTitle := gdp:subtitle($date, $locale)

let $collsData := for $c at $position in $colls 
  let $stringData := concat('	{
     ',
    (if ($c eq "partition")  then 'sliced: true,'  ),'
				name: "',data($c),'",
				y: ',data($data[$position]),',
        url: "',concat($gdp:SRU,data($urlAll[$position])),'", 
				color: "',data($gdp:gallicaTypesColors($c)),'",        
        }', (if ($position != $nData) then ',') ,codepoints-to-string(10)
    )
  return $stringData
let $collsDrillData := for $c at $position in $colls 
  let $ocr := xs:float(data($dataTarget[$position*2]))
  let $noOcr := xs:float(data($dataTarget[($position *2) - 1]))
  let $total :=   $ocr + $noOcr
  let $perOcr := ($ocr div $total)*100
  let $perNoOcr := ($noOcr div $total)*100
  let $noOcrUrl := replace(data($urlTarget[$position]),'ocr.','not%20ocr.')  
  let $stringData := concat('      
          {      
          name: "',data(gdp:noOCR($locale)),'",
           url: "',concat($gdp:SRU, $noOcrUrl),'",      
           y: ',$noOcr,',
           z: ',$perNoOcr,',
           color: "',data($gdp:otherInnerColor),'",  
            },
          {name: "OCR",
          url: "',concat($gdp:SRU, data($urlTarget[$position])),'", 
          y: ',$ocr,',
          z: ',$perOcr,',
          color: ''url(#custom-pattern-',data($position),')''
        }', (if ($position != $nData) then ',') ,codepoints-to-string(10)
    )
  return $stringData
return
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"></meta>
<title>{$title}</title>
<link rel="stylesheet" type="text/css" href="/static/dataviz.css"></link>
<style>
.highcharts-drilldown-data-label text{{
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
<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.3/jquery.min.js"></script>
<script src="https://code.highcharts.com/highcharts.js"></script>
<script src="https://code.highcharts.com/modules/exporting.js"></script>
<script src="https://code.highcharts.com/modules/accessibility.js"></script>
<script src="https://code.highcharts.com/modules/export-data.js"></script>
<script src="https://highcharts.github.io/pattern-fill/pattern-fill-v2.js"></script>
<script type="text/javascript">
$(function () {{
// not used anymore
var main = ["#2993a3", "#2ba5b8","#7dbed4","#c7e3ed" ]
var ocrColors = (function () {{
			var colors = [],
					i;
			for (i = 0; i != 4; i += 1) {{
					colors.push(Highcharts.color("{$gdp:otherInnerColor}").get())
          colors.push(Highcharts.color(main[i]).brighten(0.1).get())     
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
  backgroundColor: "#EBEBEB",
	spacingBottom: 50,
  spacingTop: 30,
  spacingLeft: 10,
  spacingRight: 10,
  // Explicitly tell the width and height of a chart
  width:  {$width},
  height: {$height}
}},
title: {{
   margin: {$gdp:marginTop}, // margin before the graph
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
// patterns for OCR parts
defs: {{
    patterns: [{{
      'id': 'custom-pattern-1',
      'path': {{
        d: 'M 0 0 L 10 10 M 9 -1 L 11 1 M -1 9 L 1 11',
        stroke: '{$gdp:gallicaTypesColors("periodical")}',
        strokeWidth: 4
      }}
    }}, {{
      'id': 'custom-pattern-2',
      'path': {{
        d: 'M 0 0 L 10 10 M 9 -1 L 11 1 M -1 9 L 1 11',
        stroke:  '{$gdp:gallicaTypesColors("monograph")}',
        strokeWidth: 4
      }}
 }}, {{
      'id': 'custom-pattern-3',
      'path': {{
        d: 'M 0 0 L 10 10 M 9 -1 L 11 1 M -1 9 L 1 11',
        stroke:  '{$gdp:gallicaTypesColors("manuscript")}',
        strokeWidth: 4
      }}
    }}, 
      {{
      'id': 'custom-pattern-4',
      'path': {{
        d: 'M 0 0 L 10 10 M 9 -1 L 11 1 M -1 9 L 1 11',
        stroke:  '{$gdp:gallicaTypesColors("music score")}',
        strokeWidth: 3
      }},
}}]
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
     return  '<a target="_blank" href="' + this.point.url + '">'+ this.point.name  + '{gdp:colon($locale)}' + formatNumbers(this.point.percentage,{$gdp:labelDigits}) +  '{gdp:percent($locale)}' + '</a>'    
     }}
		}}
	}}
}},
series: [
	{{
		name: "{gdp:typesCriteria($locale)}",
    size: '70%',
    showInLegend: false,
    dataLabels: {{
              style: {{
                    fontSize: {$gdp:labelSize},
                    color: "{$gdp:labelColor}",
                    textOutline: "{$gdp:labelOutline}"   
                }}, 
                distance: 60 
            }},
		data: [
         {$collsData}   
    ]
	}},
  	{{
		name: "ocr",
    showInLegend: false,  
    id: 'ocr',
    size: '90%',
    innerSize: '70%',
    //colors: ocrColors, 
    dataLabels: {{
       style: {{
        textOutline: "{$gdp:labelOutline}",
        color: "{$gdp:labelColor}",
        fontSize: {$gdp:labelSmallSize}
      }},
      distance: -30,                      
      formatter: function () {{
       if (String('{$locale}') == 'fr') {{
       per = " %"
       colon = ' : '
     }} else {{
       per = "%"
       colon = ': '
     }}    
     return Math.round(this.point.percentage/1) != 0 ? ' '+ '<a target="_blank" href="' + this.point.url + '">'+ this.point.name  + colon + formatNumbers(this.point.z,{$gdp:labelDigits}) + per+ '</a>' : null ;
                  }}
                  }},
		data: [
       {$collsDrillData}        
    ]
	}}, {{  // small pie on top left corner
            type: 'pie',
            name: 'Ratio', 
            startAngle: 90,      
            data: [{{
                name: '{gdp:noOCR($locale)}',
                y: {$totalOther},
                color: "{$gdp:otherInnerColor}"
            }},    
           {{ 
           		name: 'OCR',
							 y: {$rawTarget},
               url: '{$gdp:SRU}{data($urlTotalTarget)}',           
               color: {$gdp:partnersColors(data($targetName))}   
					 }}],
            center: [80, -10],
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
{if ($locale='fr') then (<p class="scope-description">Collections :  <a  title ="Complète" href="{$gdp:appPrefix}/rest?run=plotDataviz_ocr_drill.xq&amp;target=full&amp;locale=fr">Complète</a> &#x2022; <a  title ="Les documents numériques de la BnF et de ses partenaires consultables dans Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_ocr_drill.xq&amp;target=bnf_and_integrated&amp;locale=fr">BnF et intégrés</a> &#x2022; <a title="Les documents numériques de la BnF" href="{$gdp:appPrefix}/rest?run=plotDataviz_ocr_drill.xq&amp;target=bnf&amp;locale=fr">BnF</a> &#x2022; <a title ="Les documents numériques des partenaires de la BnF (intégrés et moissonnés)" href="{$gdp:appPrefix}/rest?run=plotDataviz_ocr_drill.xq&amp;target=partners&amp;locale=fr">partenaires</a> &#x2022; <a title ="Les documents numériques des partenaires de la BnF consultables dans Gallica"  href="{$gdp:appPrefix}/rest?run=plotDataviz_ocr_drill.xq&amp;target=integrated&amp;locale=fr">intégrés</a> &#x2022; <a  title ="Les documents numériques des partenaires de la BnF référencés dans Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_ocr_drill.xq&amp;target=harvested&amp;locale=fr">moissonnés</a></p> ) 
else
 <p class="scope-description">Collections:  <a  title ="All" href="{$gdp:appPrefix}/rest?run=plotDataviz_ocr_drill.xq&amp;target=full&amp;locale=en">All</a> &#x2022; <a title ="The whole digital collection" href="{$gdp:appPrefix}/rest?run=plotDataviz_ocr_drill.xq&amp;target=bnf_and_integrated&amp;locale=en">BnF and integrated</a> &#x2022; <a title ="Digital documents from BnF" href="{$gdp:appPrefix}/rest?run=plotDataviz_ocr_drill.xq&amp;target=bnf&amp;locale=en">BnF</a> &#x2022; <a title ="Digital documents from BnF&#8217;s partners (integrated and harvested)" href="{$gdp:appPrefix}/rest?run=plotDataviz_ocr_drill.xq&amp;target=partners&amp;locale=en">partners</a> &#x2022; <a title ="Digital documents from the BnF&#8217;s partners available in Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_ocr_drill.xq&amp;target=integrated&amp;locale=en">integrated</a> &#x2022; <a title ="Digital documents from the BnF&#8217;s partners listed in Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_ocr_drill.xq&amp;target=harvested&amp;locale=en">harvested</a></p>}

<p class="highcharts-description">
 {if ($locale='en') then (
   <small class="caption"><a class="picto-item" aria-label="Source and documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁</a>  <a class="picto-item" aria-label="This graph describes the share of the different collections making up Gallica in relation to the complete collection." href="#">≡</a> <a  class="picto-item" aria-label="French" href="{$gdp:appPrefix}/rest?run=plotDataviz_ocr_drill.xq&amp;target={$target}&amp;locale=fr">⚐</a></small>) else
  (<small class="caption"><a class="picto-item" aria-label="Source et documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁ </a>  <a class="picto-item" aria-label="Ce graphe décrit la part océrisée des collections textuelles." href="#">≡</a> <a  class="picto-item" aria-label="English" href="{$gdp:appPrefix}/rest?run=plotDataviz_ocr_drill.xq&amp;target={$target}&amp;locale=en">⚐</a></small>)}
 </p>
</figure>
</body>
</html>
};


(: execution des requetes sur les bases :)
let $data := collection($DBall) 
return
    local:createOutput($data)

