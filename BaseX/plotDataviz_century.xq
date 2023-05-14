(:
  Produce a histogram by documents types and provenance
:)

import module namespace gd = "http:/gallicaviz.bnf.fr/" at "../webapp/dataviz_lib.xqm";
import module namespace gdp = "http:/gallicaviz.bnf.fr/env" at "../webapp/dataviz_env.xqm";

declare namespace functx = "http://www.functx.com";

declare option output:method 'html';

(: Arguments avec valeurs par defaut :)
(: cible de l'analyse :)
declare variable $target as xs:string external := "full"  ;  (: full, bnf_and_integrated, bnf, partners, integrated, harvested  :)
(: logarithm on y axis:)
declare variable $log as xs:string external := "false" ;
declare variable $locale as xs:string external := "fr" ; 
declare variable $era as xs:integer external := 5  ; (: 1:antiquity, 2:m-a, 3:moderne, 4: contemporary, other: full  :)

(: Parameters :)
declare variable $minWidth as xs:integer := 650  ; (: see supra :)
declare variable $height as xs:integer := 630 ;

declare variable $DBtarget as xs:string  := concat("gallica_century_", $target,"-monograph") ;
declare variable $DBprefix as xs:string := "gallica_century_" ;

          
(: construction de la page HTML :)
declare function local:createOutput($db) {
<html>
{
let $targetName := if ($locale='fr') then (data($db//source_fr)) else (data($db//source))
let $processingDate := xs:date($db//date)
let $date := gd:date($processingDate,$locale)

let $title := if ($locale='fr') then (concat ("Analyse par date de publication pour la provenance : ",$targetName)) else 
(concat ("Analysis by publication date for provenance: ",$targetName))
let $subTitle := if ($locale='fr') then (concat('Source : Gallica et API Gallica SRU (', $date,')')) else (concat('Source: Gallica and Gallica SRU API (', $date,')'))

(: data for centuries: 1th..21th :)
let $centuries :=  if ($era=4)
   then ($db//century/item[position() >18])
   else if  ($era=1) then
   ($db//century/item[position() <=5])
   else if  ($era=2) then
   ($db//century/item[position() >5  and position() <= 15])
    else if  ($era=3) then
   ($db//century/item[position() >15  and position() <= 18])
   else ($db//century/item)
         
let $totalCenturies := count($centuries)

let $centuriesString := for $c at $position in $centuries
let $stringData := concat(' "',data ($c),gdp:suffix($locale),'"',
    (if ($position != $totalCenturies) then ',') ,codepoints-to-string(10))
  return $stringData
return

(: data per document types :)
let $myTypes := gdp:types($era)
let $totalTypes := count($myTypes)
let $width := if ($era > 4) then (1300)
   else (22 * $totalTypes * $totalCenturies)

let $width := if ($width < $minWidth) then ($minWidth) else ($width)

let $collsData := for $t at $pos1 in $myTypes
  
 let $DBname := concat($DBprefix,$target,"-",$myTypes[$pos1])
 let $db := collection($DBname)
 let $centuryData :=  if ($era=4)
   then ($db//sru/item[position() >18])
   else if  ($era=1) then
   ($db//sru/item[position() <=5])
   else if  ($era=2) then
   ($db//sru/item[position() >5  and position() <= 15])
    else if  ($era=3) then
   ($db//sru/item[position() >15  and position() <= 18])
   else ($db//sru/item)
  
  let $total := $db//total
  let $totalF := $db//total_with_facet
  (: let $totalData := count($centuryData) :)
  
  let $name := if ($locale='fr') then (gdp:types_fr($era)[$pos1]) else ($t)  
  let $cover :=  $totalF div $totalCenturies
  let $urlTarget := $db//search/item
  let $stringData := concat(' {  
        name: "',$name,'",
        color: "', $gdp:gallicaTypesColors($t), '",   
        data: [ ',                             
           let $tmp := for $c at $pos2 in $centuryData 
           let $url := concat($gdp:SRU, data($urlTarget[$pos2]))
            return concat('{ y: ', data($c), 
            ', total: ', $total, ', totalF: ', $totalF, 
             ', url: "',$url, '"}',             
              (if ($pos2 != $totalCenturies) then ',') ,codepoints-to-string(10))
            return string-join($tmp,' '),        
      ']}',
      (if ($pos1 != $totalTypes) then ',') ,codepoints-to-string(10)
    )
  return string($stringData)
return


<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"></meta>
<title>{$title}</title>
<link rel="stylesheet" type="text/css" href="/static/dataviz.css"></link>
<style>
#container[data-id="1"] .highcharts-legend .highcharts-legend-item:first-child text {{
  color: black !important;
  fill: black !important;
}}
#container[data-id="1"] .highcharts-legend .highcharts-legend-item:first-child rect {{
  display: none;
}}
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
	type: "column",
  backgroundColor: "{$gdp:backgroundColor}",
  spacingBottom: 30,
  spacingTop: 30,
  spacingLeft: 10,
  spacingRight: 10,
  // Explicitly tell the width and height of a chart
  width: {$width},
  height: {$height}
}},
legend: {{                
       labelFormatter: function () {{
           if (this.name=="{gdp:show($locale)}") {{
                    return '<span style="color: gray">'+this.name+'</span>'
                  }}
                    else {{
                      return this.name
                    }}
                }}
              }},
title: {{
   margin: {$gdp:marginTop},
   style: {{
            fontWeight: 'bold'
        }},
  text: "{$title}"
}},
xAxis: {{
  categories: [
      {$centuriesString} 
 ], 
 title: {{
            text: '{gdp:century($locale)}'
        }},
        labels: {{
            style: {{
                fontWeight: 'bold'
            }}
        }}
}},
yAxis: {{
        {if ($log != 'false') then ("type: 'logarithmic',") else ()}       
        title: {{
            text: 'Documents'
        }},
        labels: {{
            formatter: function () {{            
            if (this.value == 0) {{
                return 0}}
            else if (Math.trunc(this.value / 1000000) != 0)  {{
                   return formatNumbers(this.value / 1000000.0 , 1) + "M"
               }}
            else {{return formatNumbers(this.value / 1000.0 , 0) + "k"
                        }}
                      }},
            style: {{
                fontWeight: 'bold'
            }}
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
     return  '<b style="color:' + this.series.color + '">' + this.series.name + '</b>' + '{gdp:colon($locale)}'+ '<b>' + formatNumbers(this.point.y,0) + "</b> (" + formatNumbers(this.point.y/this.point.total * 100,{$gdp:labelDigits}) + '{gdp:percent($locale)}' + ")" + "<br></br>&#x2022; total" + '{gdp:colon($locale)}' + formatNumbers(this.point.total,0)  + "<br></br>&#x2022;" + '{gdp:labelDate($locale)}' + '{gdp:colon($locale)}' + formatNumbers(this.point.totalF/this.point.total *100, 0) + '{gdp:percent($locale)}' ;
   }}
}},

plotOptions: {{
  column: {{events: {{
              legendItemClick() {{
                let chart = this.chart,
                series = chart.series;
                if (this.index === 0) {{
                  if (chart.showHideFlag) {{
                  for (let i = 1; i != 10; i++) {{                   
                      series[i].hide()                     
                   }}
                  }} else {{
                    for (let i = 1; i != 10; i++) {{                   
                      series[i].show()                     
                   }}                                   
                 }}
                chart.showHideFlag = !chart.showHideFlag;
          }}
       }}
      }},
            pointPadding: 0.05,
            borderWidth: 1,
            dataLabels: {{    // column labels
             enabled: true,
             formatter: function() {{
              return formatNumbers(this.y,0)
            }},
             style: {{
                    fontSize: {$gdp:labelTinySize},
                    color: "{$gdp:labelColor}",
                    textOutline: "{$gdp:labelOutline}" , 
                    fontWeight: 'normal'
            }},
        }}
        }},
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

}},
series: [{{
    name: '{gdp:show($locale)}',
    visible: false,
    color: 'lightgray'  
  }},
      {$collsData}      
       ]
    }});
}});
</script>
</head>
}
<body>



<figure class="highcharts-figure">
<div>
    <div id="container" data-id="1"></div>
</div>
{if ($locale='fr') then (<p class="scope-description">Collections : <a title ="Toute la collection Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_century.xq&amp;target=full&amp;era={$era}&amp;locale=fr">Complète</a> &#x2022; <a title ="Les documents numériques de la BnF et de ses partenaires consultables dans Gallica"  href="{$gdp:appPrefix}/rest?run=plotDataviz_century.xq&amp;target=bnf_and_integrated&amp;era={$era}&amp;locale=fr">BnF et intégrés</a> &#x2022; <a title="Les documents numériques de la BnF" href="{$gdp:appPrefix}/rest?run=plotDataviz_century.xq&amp;target=bnf&amp;era={$era}&amp;locale=fr">BnF</a> &#x2022; <a title ="Les documents numériques des partenaires de la BnF (intégrés et moissonnés)"  href="{$gdp:appPrefix}/rest?run=plotDataviz_century.xq&amp;target=partners&amp;era={$era}&amp;locale=fr">partenaires</a> &#x2022; <a title ="Les documents numériques des partenaires de la BnF consultables dans Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_century.xq&amp;target=integrated&amp;locale=fr">intégrés</a> &#x2022; <a title ="Les documents numériques des partenaires de la BnF référencés dans Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_century.xq&amp;target=harvested&amp;era={$era}&amp;locale=fr">moissonnés</a> </p> ) 
else
(<p class="scope-description">Collections: <a title ="All the Gallica collection" href="{$gdp:appPrefix}/rest?run=plotDataviz_century.xq&amp;target=full&amp;locale=en">All</a> &#x2022; <a title ="Digital documents from BnF and its partners available in Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_century.xq&amp;target=bnf_and_integrated&amp;era={$era}&amp;locale=en">BnF and integrated</a> &#x2022; <a title ="Digital documents from BnF" href="{$gdp:appPrefix}/rest?run=plotDataviz_century.xq&amp;target=bnf&amp;era={$era}&amp;locale=en">BnF</a> &#x2022; <a title ="Digital documents from BnF&#8217;s partners (integrated and harvested)" href="{$gdp:appPrefix}/rest?run=plotDataviz_century.xq&amp;target=partners&amp;era={$era}&amp;locale=en">partners</a> &#x2022; <a title ="Digital documents from the BnF&#8217;s partners available in Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_century.xq&amp;target=integrated&amp;era={$era}&amp;locale=en">integrated</a> &#x2022; <a title ="Digital documents from the BnF&#8217;s partners listed in Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_century.xq&amp;target=harvested&amp;era={$era}&amp;locale=en">harvested</a></p>)}

<p class="highcharts-description">
 {if ($locale='en') then (
   <small class="caption"><a class="picto-item" aria-label="Source and documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁</a>  <a class="picto-item" aria-label="This graph analyses the distribution of document types according to the publication date." href="#">≡</a> <a  class="picto-item" aria-label="French" href="{$gdp:appPrefix}/rest?run=plotDataviz_century.xq&amp;target={$target}&amp;era={$era}&amp;locale=fr">⚐</a> <a  class="picto-item" aria-label="Logarithmic scale" href="{$gdp:appPrefix}/rest?run=plotDataviz_century.xq&amp;target={$target}&amp;&amp;era={$era};&amp;locale=en&amp;log=true">&#x1f4c8;</a></small>) else
  (<small class="caption"><a class="picto-item" aria-label="Source et documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁ </a>  <a class="picto-item" aria-label="Ce graphe analyse la couverture temporelle (date de publication) de la collection par types de documents." href="#">≡</a> <a  class="picto-item" aria-label="English" href="{$gdp:appPrefix}/rest?run=plotDataviz_century.xq&amp;target={$target}&amp;era={$era}&amp;locale=en">⚐</a> <a  class="picto-item" aria-label="Echelle logarithmique" href="{$gdp:appPrefix}/rest?run=plotDataviz_century.xq&amp;target={$target}&amp;era={$era}&amp;locale=fr&amp;log=true">&#x1f4c8;</a></small>)
}
 </p>
</figure>
</body>
</html>
};


(: execution de la requete sur la base :)
let $data := collection($DBtarget) 
return
    local:createOutput($data)
