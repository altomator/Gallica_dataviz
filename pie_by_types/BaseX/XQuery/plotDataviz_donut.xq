(:
 Recherche de pages illustrees par les annotations
:)

declare namespace functx = "http://www.functx.com";

declare option output:method 'html';

(: Arguments avec valeurs par defaut :)

(: nom de la base BaseX :)
declare variable $DBall as xs:string external := "gallica_types_full" ;
declare variable $target as xs:string external  ; (: full, gallica, bnf, partners, integrated, harvested  :)
declare variable $DBtarget as xs:string  := concat("gallica_types_", $target) ; 
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
let $processingDate := xs:date($data//date)
let $date := if ($locale='fr') then (format-date($processingDate, "[D]-[M]-[Y]")) else (format-date($processingDate, "[Y]-[M]-[D]"))
let $totalData := count($data/root/data/query/collection/item)

let $other := if ($locale='fr') then ("autres") else ("other")
let $colls := if ($locale='fr') then ($data/root/data/query/collection_fr/item) else ($data/root/data/query/collection/item)
let $full := if ($locale='fr') then ("tout Gallica") else ("full Gallica")
let $targetName := if ($locale='fr') then (collection($DBtarget)//source_fr) else (collection($DBtarget)//source)

let $data := $data//sru/item
let $rawTotal := sum($data)
let $total := if ($locale='fr') then (replace(format-number($rawTotal, '9,999'),',','&#x2009;')) else (format-number(sum($data), '9,999')) 

(: data from the sub collection :)  
let $dataDrill := collection($DBtarget)//sru/item
let $rawTarget := sum($dataDrill)
let $totalDrill := if ($locale='fr') then (replace(format-number($rawTarget, '9,999'),',','&#x2009;')) else (format-number(sum($dataDrill), '9,999')) 
let $totalOther := $rawTotal - $rawTarget

let $title := if ($locale='fr') then (concat ("Analyse par types de document &#x2014; Collections numériques : ",$full,"/",$targetName," &#x2014; Total : ",$total,"/",$totalDrill)) else 
(concat ("Analysis by document type &#x2014; Digital collections: ",$full,"/",$targetName,"&#x2014; Documents: ", $total,"/",$totalDrill))
let $subTitle := if ($locale='fr') then (concat('Source : <a href="https://gallica.bnf.fr" target="_default">Gallica</a> et <a href="https://api.bnf.fr/fr/api-gallica-de-recherche" target="_default">Gallica SRU API</a> (', $date,')')) else (concat('Source: <a href="https://gallica.bnf.fr" target="_default">Gallica</a> and <a href="https://api.bnf.fr/fr/api-gallica-de-recherche" target="_default">Gallica SRU API</a> (', $date,')'))
let $collsData := for $c at $position in $colls 
  let $stringData := concat('	{
    ',
    (if ($c eq "video")   then 'sliced: true, color:"#e3af7d",' 
    else (if (($c eq "sonore") or ($c eq "sound"))  then 'sliced: true, color:"#bd9268",' )),'
				name: "',data($c),'",
				y: ',data($data[$position]),',
				drilldown: "',data($c),'"        
        }', (if ($position != $totalData) then ',') ,codepoints-to-string(10)
    )
  return $stringData
let $collsDrillData := for $c at $position in $colls 
  let $stringData := concat('	{  
        name: "',data($c),'",
        id: "',data($c),'",    
        data: [       
          { name: "',
           data($other),'",
           color: "SlateBlue", 
           y: ',data($data[$position]-$dataDrill[$position]),'
        },
          {name: "',
           data($targetName),'",
           color: "DarkSlateBlue", 
          y: ',data($dataDrill[$position]),'
        }
       ]     
        }', (if ($position != $totalData) then ',') ,codepoints-to-string(10)
    )
  return $stringData
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
					base = "#3b9db3", //Highcharts.getOptions().colors[4],
					i;
			for (i = 0; i != 20; i += 1) {{
					colors.push(Highcharts.color(base).brighten((i - 3) / 9).get())
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
  width: 1200,
  height: 650
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
	pie: {{
		startAngle: 130,
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
		name: "Types",
		colorByPoint: true,
    innerSize: '40%',
    dataLabels: {{
                style: {{
                    fontSize: 13,
                    textOutline: "none",
                                        
                }}
            }},
		data: [
      {$collsData}     
		]
	}}, {{
            type: 'pie',
            name: 'Ratio',       
            data: [{{
                name: '{$other}',
                y: {$totalOther},
                color: "#B8B0AE",
            }},    
           {{ 
           		name: '{$targetName}',
							 y: {$rawTarget},
               color: "#FF5733"
					 }}],
            center: [100, 75],
            size: 70,
            showInLegend: false,
            dataLabels: {{
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
<style>
	.highcharts-description  {{
    font-family: sans-serif;
    margin: 10px auto;
    text-align: center;
    width: 100%;
    max-width: 1200px;
}}
.highcharts-figure,
.highcharts-data-table  {{
    min-width: 320px;
    max-width: 1200px;
    margin: 1em auto;
}}
</style>

<script src="https://code.highcharts.com/highcharts.js"></script>
<script src="https://code.highcharts.com/modules/exporting.js"></script>
<script src="https://code.highcharts.com/modules/accessibility.js"></script>
<script src="https://code.highcharts.com/modules/export-data.js"></script>
<script src="https://code.highcharts.com/modules/drilldown.js"></script>
<figure class="highcharts-figure">
	<div style="width: 1200px">
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

