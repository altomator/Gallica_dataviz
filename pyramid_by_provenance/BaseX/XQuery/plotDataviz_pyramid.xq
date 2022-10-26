(:
 Recherche de pages illustrees par les annotations
:)

declare namespace functx = "http://www.functx.com";

declare option output:method 'html';

(: Arguments avec valeurs par defaut :)

(: nom de la base BaseX :)
declare variable $DBall as xs:string external := "gallica_prov" ;
declare variable $locale as xs:string external := "fr" ; (: langue: fr/en :)
   
(: declare variable $currentDate as xs:date  := current-date(); :)
 
(: URL Gallica de base :)
declare variable $rootURL as xs:string external := 'http://gallica.bnf.fr/ark:/12148/';

declare function local:evalQuery($query) {
    let $hits := xquery:eval($query)
    return $hits
};

(: construction de la page HTML :)
declare function local:createOutput($data) {
  
<html>
{
let $myColors := ("#00495E",   "#05657B",   "#1E8197",   "#3A9EB3",   "#57BACF","#72D6EB", "#90F2FF", "#BD9268", "#e3af7d")
let $processingDate := xs:date($data//date)
let $date := if ($locale='fr') then (format-date($processingDate, "[D]-[M]-[Y]")) else (format-date($processingDate, "[Y]-[M]-[D]"))
let $other := if ($locale='fr') then ("autres") else ("other")
let $DBbnf := "gallica_types_bnf" 
let $DBint := "gallica_types_integrated" 
let $DBhar := "gallica_types_harvested"
 
(: data of provenances :)
let $totalData := count($data/root/data/query/source/item)
let $sources := if ($locale='fr') then ($data/root/data/query/source_fr/item) else ($data/root/data/query/source/item)
let $dataSources := $data//sru/item

(: data for the drill from 3 DB: bnf, integrated, harvested :) 
let $dataBnF := collection($DBbnf)//sru/item
let $dataInt := collection($DBint)//sru/item
let $dataHar := collection($DBhar)//sru/item

let $totalTypes := count($dataBnF)
let $types := if ($locale='fr') then (collection($DBbnf)//collection_fr/item) 
else (collection($DBbnf)//collection/item)

let $total := if ($locale='fr') then (replace(format-number(sum($dataSources), '9,999'),',','&#x2009;')) else (format-number(sum($dataSources), '9,999')) 
let $title := if ($locale='fr') then (concat ("Analyse de la collection par provenance &#x2014; Total : ",$total)) else 
(concat ("Analysis of the collection by provenance &#x2014; Total: ", $total))
let $subTitle := if ($locale='fr') then (concat('Source : <a href="https://gallica.bnf.fr" target="_default">Gallica</a> et <a href="https://api.bnf.fr/fr/api-gallica-de-recherche" target="_default">Gallica SRU API</a> (', $date,')')) else (concat('Source: <a href="https://gallica.bnf.fr" target="_default">Gallica</a> and <a href="https://api.bnf.fr/fr/api-gallica-de-recherche" target="_default">Gallica SRU API</a> (', $date,')'))
let $collsData := for $c at $position in $sources 
  let $stringData := concat('	{
				name: "',data($c),'",
				y: ',data($dataSources[$position]),',
				drilldown: "',data($c),'"        
        }', (if ($position != $totalData) then ',') ,codepoints-to-string(10)
    )
  return $stringData
  
let $collsDrillData := for $s at $position in $sources 
  let $stringData := concat(' {  
        name: "',data($s),'",
        id: "',data($s),'",    
        data: [ ',
           let $tmp := for $c at $pos in $types
           return concat('{ name: "',
           data($c),'",
           color: "', $myColors[$pos],'", 
           y: ',(if ($s="BnF") then (data($dataBnF[$pos])) else if ($s="intégrés") then (data($dataInt[$pos])) else (data($dataHar[$pos]))),'
         }', (if ($pos != $totalTypes) then ',') ,codepoints-to-string(10))
         return string-join($tmp,' '),
      
       ']     
       }', (if ($position != $totalData) then ','), codepoints-to-string(10)
    )
  return string($stringData)
return
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"></meta>
<title>{$title}</title>
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
					base = "#0092ca", 
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
  spacingRight: 10,
  // Explicitly tell the width and height of a chart
  width: 700,
  height: 600
}},
title: {{
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
       return this.point.name + colon + Highcharts.numberFormat(this.point.percentage, 2,dec,sep)+per; 
     }}
		}},
		showInLegend: true
	}}
}},
series: [
	{{
		name: "Provenances",
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
    font-family: sans-serif;
    margin: 10px auto;
    text-align: center;
    width: 100%;
    max-width: 500px;
}}
.highcharts-figure,
.highcharts-data-table  {{
    min-width: 320px;
    max-width: 650px;
    margin: 1em auto;
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
	<div style="width: 1000px">
    <div id="container"></div>
</div>
<p class="highcharts-description">

 {if ($locale='en') then (<small>This pie chart has been produced using the Gallica SRU API. <br></br>See this <a href="https://github.com/altomator/Gallica_Dataviz" target="_blank">github</a> for more information.</small>) else (<small>Ce graphe a été produit avec les API Gallica SRU. <br></br>Pour plus d'information, consulter ce <a href="https://github.com/altomator/Gallica_Dataviz" target="_blank">github</a>.</small>)}</p>
</figure>
</body>
</html>
};


(: execution des requetes sur les bases :)
let $data := collection($DBall) 
return
    local:createOutput($data)

