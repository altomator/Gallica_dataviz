(:
 Produce a pie regarding document types ratios and drilldown by provenances
:)

import module namespace gd = "http:/gallicaviz.bnf.fr/" at "../webapp/dataviz_lib.xqm";
import module namespace gdp = "http:/gallicaviz.bnf.fr/env" at "../webapp/dataviz_env.xqm";

declare namespace functx = "http://www.functx.com";

declare option output:method 'html';

(: Arguments avec valeurs par defaut :)
declare variable $locale as xs:string external := "fr" ; (: langue: fr/en :)

(: Parameters :)
declare variable $width as xs:integer := 850 ;
declare variable $height as xs:integer := 630 ;

(: the full collection :)
declare variable $DBall as xs:string external := "gallica_types_full" ;
(: the DB for the targeted collection :)
declare variable $DBtarget1 as xs:string  := "gallica_types_bnf" ; 
declare variable $DBtarget2 as xs:string  := "gallica_types_integrated" ; 
declare variable $DBtarget3 as xs:string  := "gallica_types_harvested" ; 


(: construction de la page HTML :)
declare function local:createOutput($data) { 
<html>
{
let $processingDate := xs:date($data//date)
let $date := gd:date($processingDate, $locale)

let $totalData := count($data//collection/item)
let $colls := if ($locale='fr') then ($data//collection_fr/item) else ($data//collection/item)
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
let $total := gd:number($rawTotal,$locale)

(: data from the sub collections :)  
let $dataDrill1 := collection($DBtarget1)//sru/item
let $rawTarget1 := sum($dataDrill1)

let $dataDrill2 := collection($DBtarget2)//sru/item
let $rawTarget2 := sum($dataDrill2)

let $dataDrill3 := collection($DBtarget3)//sru/item
let $rawTarget3 := sum($dataDrill3)

let $title := if ($locale='fr') then (concat ("Analyse par type de documents et provenance &#x2014; Total : ",$total)) else 
(concat ("Analysis by document type and provenance &#x2014; Documents: ", $total))
let $subTitle := gdp:subtitle($date, $locale)

let $collsData := for $c at $position in $colls 
  let $stringData := concat('	{
    ',
    (if ($c eq "video")   then 'sliced: true,' 
    else (if (($c eq "sonore") or ($c eq "sound"))  then 'sliced: true, ' )),'
				name: "',data($c),'",
				y: ',data($data[$position]),',
        url: "',concat($gdp:SRU,data($urlAll[$position])),'",
				drilldown: "',data($c),'"        
        }', (if ($position != $totalData) then ',') ,codepoints-to-string(10)
    )
  return $stringData
let $collsDrillData := for $c at $position in $colls 
  let $stringData := concat('	{  
        name: "',data($c),'",
        id: "',data($c),'",
        dataLabels: {
              style: {
                    fontSize:', $gdp:labelSize,',
                    color: "',$gdp:labelColor,'",
                    textOutline: "',$gdp:labelOutline,'"   
                }, 
                distance: 30 
            },    
        data: [       
          { name: "',
           data($targetName1),'",
            url: "',concat($gdp:SRU, data($urlTarget1[$position])),'",
            color: ',data($gdp:partnersColors("bnf")),',  
           y: ',data($dataDrill1[$position]),'
        },
          {name: "',
           data($targetName2),'",
           url: "',concat($gdp:SRU, data($urlTarget2[$position])),'",
          color: ',data($gdp:partnersColors($gdp:partnersList[1])),',  
          y: ',data($dataDrill2[$position]),'
        },
        {name: "',
           data($targetName3),'",
           url: "',concat($gdp:SRU, data($urlTarget3[$position])),'",
          color: ',data($gdp:partnersColors($gdp:partnersList[2])),',  
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

.highcharts-drilldown-data-label text{{
  text-decoration:none !important;
}};
}}
</style>
<script src="/static/he.js"></script>
<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
<script src="https://code.highcharts.com/highcharts.js"></script>
<script src="https://code.highcharts.com/modules/exporting.js"></script>
<script src="https://code.highcharts.com/modules/accessibility.js"></script>
<script src="https://code.highcharts.com/modules/export-data.js"></script>
<script src="https://code.highcharts.com/modules/drilldown.js"></script>
<script src="https://highcharts.github.io/pattern-fill/pattern-fill.js"></script>
<script type="text/javascript">
$(function () {{

 var pieColors = [
  {{
    pattern: '/static/img/bpt6k701453s.JPEG', 
    width: 512,
    height: 742
  }},
  {{
    pattern: '/static/img/bpt6k1049566j-21.JPEG', 
    width: 622,
    height: 426
  }},                       
{{
   pattern: '/static/img/btv1b84489742-f7.JPEG',
                            width: 600,
                            height: 604
  }},
   {{
   pattern: '/static/img/btv1b8495644b.JPEG',
                            width: 650,
                            height: 576
  }},
  {{
   pattern: '/static/img/btv1b53024261w.jpg',
                            width: 620,
                            height: 575
  }},
   {{
   pattern: '/static/img/btv1b10455135w-f2.JPEG',
                            width: 650,
                            height: 580
  }},
   {{
   pattern: '/static/img/btv1b53095162g.JPEG',
                            width: 681,
                            height: 681
  }},
  {{
   pattern: '/static/img/bpt6k1080644m.JPEG',
                            width: 610,
                            height: 611
  }},
   {{
   pattern: '/static/img/bpt6k13219337.JPEG',
                            width: 680,
                            height: 609
  }}
    ];

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
    patterns: [
       {{
      'id': 'custom-pattern-img',
      image:
        'https://gallica.bnf.fr/ark:/12148/bpt6k1523583v/f123.medres'
      
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
    colors: pieColors,
		dataLabels: {{
      //connectorColor: 'grey',
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
                distance: 20 
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
	<div>
    <div id="container">
  </div>
</div>
<p class="highcharts-description">
 {if ($locale='en') then (
   <small class="caption"><a class="picto-item" aria-label="Source and documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁</a>  <a class="picto-item" aria-label="This graph describes the share of the different types of documents in the Gallica collection, with a breakdown by provenance for each." href="#">≡</a> <a  class="picto-item" aria-label="French" href="{$gdp:appPrefix}/rest?run=plotDataviz_types_drill.xq&amp;target=bnf_and_integrated&amp;locale=fr">⚐</a></small>) else
  (<small class="caption"><a class="picto-item" aria-label="Source et documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁ </a>  <a class="picto-item" aria-label="Ce graphe décrit la part des différents types de document de la collection Gallica, avec pour chacun la répartition par provenance." href="#">≡</a> <a  class="picto-item" aria-label="English" href="{$gdp:appPrefix}/rest?run=plotDataviz_types_drill.xq&amp;target=bnf_and_integrated&amp;locale=en">⚐</a></small>)}
 </p>
</figure>
</body>
</html>
};


(: execution des requetes sur les bases :)
let $data := collection($DBall) 
return
    local:createOutput($data)

