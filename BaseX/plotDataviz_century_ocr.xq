(:
   Produce a histogram by documents types and ocr 
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

(: Parameters :)
declare variable $width as xs:integer := 1250 ;
declare variable $height as xs:integer := 630 ;
declare variable $DBtarget as xs:string  := concat("gallica_century_", $target,"-monograph") ;
declare variable $DBprefix as xs:string := "gallica_century_" ;
declare variable $begin_OCR as xs:integer := 15 ;
         

(: construction de la page HTML :)
declare function local:createOutput($db) {
<html>
{
let $targetName := if ($locale='fr') then (data($db//source_fr)) else (data($db//source))
let $processingDate := xs:date($db//date)
let $date := gd:date($processingDate,$locale)

let $title := if ($locale='fr') then (concat ("Analyse par date de publication et OCR pour la provenance : ",$targetName)) else 
(concat ("Analysis by publication date for provenance: ",$targetName))
let $subTitle := gdp:subtitle($date, $locale)

(: data :)
let $centuries := $db//century/item[position()>=$begin_OCR]
let $totalData := count($centuries)
let $categoriesData := for $c at $position in $centuries
 let $stringData := concat(' "',data($c),gdp:suffix($locale),'"',
    (if ($position != $totalData) then ',') ,codepoints-to-string(10))
  return $stringData
return

let $collsData := for $t at $pos1 in $gdp:ocrTypes
  let $totalTypes := count($gdp:ocrTypes)
  let $DBname := concat($DBprefix,$target,"-",$gdp:ocrTypes[$pos1])
  let $DBOCRname := concat($DBprefix,$target,"-",$gdp:ocrTypes[$pos1],"-ocr")
  let $db := collection($DBname)
  let $dbOCR := collection($DBOCRname)
  let $data := $db//sru/item[position()>=$begin_OCR] 
  let $OCRdata := $dbOCR//sru/item[position()>=$begin_OCR] 
  let $total := $db//total
  let $totalOCR := $dbOCR//total
  let $totalF := $db//total_with_facet
  let $nData := count($data)  
  let $name := if ($locale='fr') then ($gdp:ocrTypes_fr[$pos1]) else ($t)     
  let $cover :=  $totalF div $totalData
  let $urlTargetOCR := $dbOCR//search/item[position()>=$begin_OCR]
  (: no OCR :)
  let $stringData := concat(' {  
        name: "',$name,' ',gdp:noOCR($locale), '",
        stack: "',$name,'",
        color: "',$gdp:otherInnerColor,'",         
        data: [ ',                             
          let $tmp := for $c at $pos2 in $data 
            let $value := data($c - $OCRdata[$pos2])
            let $url := concat($gdp:SRU, data($urlTargetOCR[$pos2]))
            let $noOCRurl := replace($url,'ocr.','not%20ocr.') 
            return concat('{ y: ', if ($value <= 0) then (0) else ($value), 
            ', totalT: ', $total, ', totalF: ', $totalF, 
            ', colorType: "',$gdp:gallicaTypesColors($name),'"',  
             ', url: "',$noOCRurl, '"}',            
              (if ($pos2 != $totalData) then ',') ,codepoints-to-string(10))
            return string-join($tmp,' '),        
      ']},
      {  
        name: "', gdp:OCR($locale), '",
        stack: "',$name,'",
        color: "url(#custom-pattern-',data($pos1),')",   
        // color: "',$gdp:gallicaTypesColors($t),'",
        data: [ ',                             
           let $tmp := for $c at $pos2 in $OCRdata 
           let $url := concat($gdp:SRU, data($urlTargetOCR[$pos2]))
            return concat('{ y: ', $c, 
            ', totalT: ', $total, ', totalF: ', $totalF, 
            ', colorType: "',$gdp:gallicaTypesColors($t),'"',  
             ', url: "',$url, '"}',
              
              (if ($pos2 != $totalData) then ',') ,codepoints-to-string(10))
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
	type: "column",
  backgroundColor: "{$gdp:backgroundColor}",
	spacingBottom: 30,
  spacingTop: 30,
  spacingLeft: 10,
  spacingRight: 10,
  // Explicitly tell the width and height of a chart
  width: {$width},
  height: {$height},
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
      {$categoriesData} 
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
     return  '<b style="color:' + this.point.colorType + '">' + this.series.name + '</b>' + '{gdp:colon($locale)}' + '<b>' + formatNumbers(this.point.y, 0) + "</b> (" + formatNumbers(this.point.y/this.point.total * 100, {$gdp:labelDigits}) + '{gdp:percent($locale)}' + ")" + "<br></br>&#x2022; total" +'{gdp:colon($locale)}' + formatNumbers(this.point.total, 0)  + "<br></br>&#x2022;" + '{gdp:labelDate($locale)}' +'{gdp:colon($locale)}'+ formatNumbers(this.point.totalF/this.point.totalT *100, 0) + '{gdp:percent($locale)}' ;
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
        stroke:  '{$gdp:gallicaTypesColors("")}',
        strokeWidth: 4
      }}
}}]
}},
plotOptions: {{
  column: {{            
      stacking: 'normal',
            pointPadding: 0.05,
            borderWidth: 1,
            dataLabels: {{
              enabled: true,
              formatter: function() {{
              return formatNumbers(this.y,0)
             }},
              style: {{
                    fontSize: {$gdp:labelSmallSize},
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
series: [
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
    <div id="container"></div>
</div>
{if ($locale='fr') then (<p class="scope-description">Collections : <a title ="Toute la collection Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_century_ocr.xq&amp;target=full&amp;locale=fr">Complète</a> &#x2022; <a title ="Les documents numériques de la BnF et de ses partenaires consultables dans Gallica"  href="{$gdp:appPrefix}/rest?run=plotDataviz_century_ocr.xq&amp;target=bnf_and_integrated&amp;locale=fr">BnF et intégrés</a> &#x2022; <a title="Les documents numériques de la BnF" href="{$gdp:appPrefix}/rest?run=plotDataviz_century_ocr.xq&amp;target=bnf&amp;locale=fr">BnF</a>  &#x2022; <a title ="Les documents numériques des partenaires de la BnF consultables dans Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_century_ocr.xq&amp;target=integrated&amp;locale=fr">intégrés</a> </p> ) 
else
(<p class="scope-description">Collections: <a title ="All the Gallica collection" href="{$gdp:appPrefix}/rest?run=plotDataviz_century_ocr.xq&amp;target=full&amp;locale=en">All</a> &#x2022; <a title ="Digital documents from BnF and its partners available in Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_century_ocr.xq&amp;target=bnf_and_integrated&amp;locale=en">BnF and integrated</a> &#x2022; <a title ="Digital documents from BnF" href="{$gdp:appPrefix}/rest?run=plotDataviz_century_ocr.xq&amp;target=bnf&amp;locale=en">BnF</a> &#x2022;  <a title ="Digital documents from the BnF&#8217;s partners available in Gallica" href="{$gdp:appPrefix}/rest?run=plotDataviz_century_ocr.xq&amp;target=integrated&amp;locale=en">integrated</a> &#x2022; </p>)}

<p class="highcharts-description">
 {if ($locale='en') then (
   <small class="caption"><a class="picto-item" aria-label="Source and documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁</a>  <a class="picto-item" aria-label="This graph analyses the distribution of document types with OCR according to the publication date." href="#">≡</a> <a  class="picto-item" aria-label="French" href="{$gdp:appPrefix}/rest?run=plotDataviz_century_ocr.xq&amp;target={$target}&amp;locale=fr">⚐</a>  </small>) else
  (<small class="caption"><a class="picto-item" aria-label="Source et documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁ </a>  <a class="picto-item" aria-label="Ce graphe analyse la couverture temporelle (date de publication) de la collection pour les types de documents océrisés." href="#">≡</a> <a  class="picto-item" aria-label="English" href="{$gdp:appPrefix}/rest?run=plotDataviz_century_ocr.xq&amp;target={$target}&amp;locale=en">⚐</a> </small>)}
 </p>
</figure>
</body>
</html>
};


(: execution de la requete sur la base :)
let $data := collection($DBtarget) 
return
    local:createOutput($data)
