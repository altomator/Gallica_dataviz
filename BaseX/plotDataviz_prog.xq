(:
 Dataviz of the Gallica collections
:)

declare namespace functx = "http://www.functx.com";

declare option output:method 'html';

(: Arguments avec valeurs par defaut :)
(: cible de l'analyse :)
declare variable $target as xs:string external  ; (: monograph / periodical  :)
declare variable $locale as xs:string external := "fr" ; (: langue: fr/en :)
 
 
declare variable $DBall as xs:string external := concat("gallica_programs_bnf_and_integrated_", $target) ;
declare variable $DBtarget as xs:string  := concat("gallica_programs_bnf_and_integrated_ocr_", $target) ;
    
(: declare variable $currentDate as xs:date  := current-date(); :)

(: Parameters :)
(: Pie colors :)
declare variable $mainColor as xs:string := "#ae5a4d" ; (: "SlateBlue" :)
(: Drill colors :)
declare variable $innerColor as xs:string := "#3d598b" ; (: blue : ocr :)
declare variable $otherInnerColor as xs:string := "#B8B0AE" ; (: grey : no ocr :)

declare variable $criteria as xs:string :=  if ($locale='fr') then ("Programmes") else ("Programs") ; (: label of the graph criteria :)
declare variable $targetLabel := "OCR";
declare variable $other := if ($locale='fr') then ("sans OCR") else ("no OCR");

declare variable $width as xs:integer := 1000 ; (: width of the chart's frame:)

(: URL Gallica de base :)
declare variable $SRU as xs:string external := fn:escape-html-uri("https://gallica.bnf.fr/services/engine/search/sru?operation=searchRetrieve&amp;exactSearch=false&amp;collapsing=false&amp;query=");

declare function local:evalQuery($query) {
    let $hits := xquery:eval($query)
    return $hits
};

(: construction de la page HTML :)
declare function local:createOutput($db) {
  
<html>
{
let $processingDate := xs:date($db//date)
let $date := if ($locale='fr') then (format-date($processingDate, "[D]-[M]-[Y]")) else (format-date($processingDate, "[Y]-[M]-[D]"))
let $nData := count($db/root/data/query/collection/item)

let $dbTarget := collection($DBtarget)

(: URLs for the drill :) 
let $urlAll := $db//search/item 
let $urlTarget := $dbTarget//search/item
let $urlTotalTarget := $dbTarget/root/data/query/total_url 
let $noOcrUrlTotalTarget := replace(data($urlTotalTarget),'ocr.','not%20ocr.')


let $colls := if ($locale='fr') then ($db/root/data/query/collection_fr/item) else ($db/root/data/query/collection/item)
let $full := if ($locale='fr') then ($db//source_fr) else ($db//source)

let $collName := if ($locale='fr') then ($dbTarget//target_fr) else ($dbTarget//target)
(: data :)
let $data := $db//sru/item
let $rawTotal := data($db//total)
let $rawTotalP := data($db//total_p)

let $total := if ($locale='fr') then (replace(format-number($rawTotal, '9,999'),',','&#x2009;')) else (format-number($rawTotal, '9,999')) 
let $total_p := if ($locale='fr') then (replace(format-number($rawTotalP, '9,999'),',','&#x2009;')) else (format-number($rawTotalP, '9,999')) 

(: data from the sub collection : OCR :)  
let $dataTarget := $dbTarget//sru/item
let $rawTarget := data($dbTarget/root/data/query/total)
let $totalTarget := if ($locale='fr') then (replace(format-number($rawTarget, '9,999'),',','&#x2009;')) else (format-number($rawTarget, '9,999')) 
let $totalOther := $rawTotal - $rawTarget

let $title := if ($locale='fr') then (concat ("Analyse par programmes de numérisation &#x2014; Collection numérique : ",$full," (", $collName,") &#x2014; Total : ",$total_p,"/",$total)) else 
(concat ("Analysis by digitization programs &#x2014; Digital collection: ",$full," (", $collName,") &#x2014; Total: ", $total,"/",$totalTarget))
let $subTitle := if ($locale='fr') then (concat('Source : <a href="https://gallica.bnf.fr" target="_default">Gallica</a> et <a href="https://api.bnf.fr/fr/api-gallica-de-recherche" target="_default">API Gallica SRU</a> (', $date,')')) else (concat('Source: <a href="https://gallica.bnf.fr" target="_default">Gallica</a> and <a href="https://api.bnf.fr/fr/api-gallica-de-recherche" target="_default">Gallica SRU API</a> (', $date,')'))
let $collsData := for $c at $position in $colls 
  let $stringData := concat('	{ 
   ',
    (if ($c eq "Proquest")  then 'sliced: true,'  ),' 
				name: "',data($c),'",
				y: ',data($data[$position]),',
        ',
        (if ($c != "other" and $c != "autres") then (concat('		url: "',$SRU,$urlAll[$position],'",
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
          { name: "',data($other),'",',
            (if ($c != "other" and $c != "autres") then (concat('
           url: "',$SRU, $ocrUrl,'",'))),
           '
           color: "', data($otherInnerColor),'",
           y: ',data($data[$position]-$dataTarget[$position]),'
        },
          {name: "',data($targetLabel),'",',
           (if ($c != "other" and $c != "autres") then (concat('
           url: "',$SRU, $ocrUrl,'",'))),
           '
           color: "',data($innerColor),'", 
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
<script src="/static/he.js"></script>
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
					base = "{$mainColor}", //  pie color  
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
  height: 610
}},
title: {{
   margin: 30,
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
       return '<a target="_blank" href="' + this.point.url + '">'+ this.point.name + colon + Highcharts.numberFormat(this.point.percentage, 2,dec,sep) + per + '</a>';   
     }}
		}},
		showInLegend: true
	}}
}},
series: [
	{{
		name: "{$criteria}",
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
            data: [{{
                name: '{$other}',
                y: {$totalOther},
                url: '{$SRU}{data($noOcrUrlTotalTarget)}',
                color: "{$otherInnerColor}", //no ocr
            }},    
           {{ 
           		name: '{$targetLabel}',
							 y: {$rawTarget},
               url: '{$SRU}{data($urlTotalTarget)}',
               color: "{$innerColor}" // ocr
					 }}],
            center: [100, 20],
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
    font-family: Lucida Grande;
    margin: 10px auto;
    text-align: center;
    width: 100%;
    max-width: {$width}px;
}}
.highcharts-figure,
.highcharts-data-table  {{
    min-width: 320px;
    max-width: {$width}px;
    margin: 1em auto;
}}
.scope-description  {{
    font-family: Lucida Grande;
    font-weight: bold;
    background-color: #EBEBEB;
    margin: 10px auto;
    margin-top: -10px;
    padding-top : 10px;
    padding-bottom: 10px;
    text-align: center;
    width: 100%;
    max-width: {$width}px;
}}

.caption {{ color : gray }}
.flag {{ width : 20px }}
a {{ text-decoration: none }}

.picto-item {{
  position: relative;  /*les .picto-item deviennent référents*/
  cursor: help;
  border-radius: 50%;
}}

/* on génère un élément :after lors du survol et du focus :*/

.picto-item:hover:after,
.picto-item:focus:after {{
  content: attr(aria-label);  /* on affiche aria-label */
  position: absolute;
  top: -2.4em;
  left: 50%;
	transform: translateX(-50%); /* on centre horizontalement  */
  z-index: 1; /* pour s'afficher au dessus des éléments en position relative */
  white-space: nowrap;  /* on interdit le retour à la ligne*/
  padding: 5px 14px;
  background: #413219;
  color: #fff;
  border-radius: 4px;
  font-size: 0.7rem;
}}

/* on génère un second élément en :before pour la flèche */

[aria-label]:hover:before,
[aria-label]:focus:before {{
  content: "▼";
  position: absolute;
  top: -1em;
	left: 50%;
	transform: translateX(-50%); /* on centre horizontalement  */
  font-size: 14px;
  color: #413219;
}}

/* pas de contour durant le :focus */
[aria-label]:focus {{
  outline: none;
}}

.picto-item {{
  display: inline-flex;
  justify-content: center;
  align-items: center;
  margin: 0.5em .2em  0.5em  1.5e;
  width: 1.2em;
  height: 1.2em;
  color: #413219;
  background: #A0A0A0;
  font-size: 0.95rem;
  text-align: center;
  text-decoration: none;
}}
</style>

<script src="https://code.highcharts.com/highcharts.js"></script>
<script src="https://code.highcharts.com/modules/exporting.js"></script>
<script src="https://code.highcharts.com/modules/accessibility.js"></script>
<script src="https://code.highcharts.com/modules/export-data.js"></script>
<script src="https://code.highcharts.com/modules/drilldown.js"></script>
<figure class="highcharts-figure">

<div>
    <div id="container"></div>
</div>
{if ($locale='fr') then (<p class="scope-description">Programmes : <a title ="Les programmes et partenariats de numérisation portant sur les collections de monographies" href="http://localhost:8984/rest?run=plotDataviz_prog.xq&amp;target=monograph&amp;locale=fr">Monographie</a> &#x2022; <a title ="Les programmes et partenariats de numérisation portant sur les collections de périodiques" href="http://localhost:8984/rest?run=plotDataviz_prog.xq&amp;target=periodical&amp;locale=fr">Périodique</a></p> ) 
else
(<p class="scope-description">Programs: <a title ="Digitisation programmes and partnerships for monographs" href="http://localhost:8984/rest?run=plotDataviz_prog.xq&amp;target={$target}&amp;locale=en">Monograph</a> &#x2022; <a title ="Digitisation programmes and partnerships for periodicals" href="http://localhost:8984/rest?run=plotDataviz_prog.xq&amp;target={$target}&amp;locale=en">Periodical</a></p>)}

<p class="highcharts-description">
 {if ($locale='en') then (
   <small class="caption"><a class="picto-item" aria-label="Source and documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁</a>  <a class="picto-item" aria-label="This graph analyses the BnF&#8217;s digitisation programmes and partnerships for which specific conditions of access to digital documents exist." href="#">≡</a> <a  class="picto-item" aria-label="French" href="http://localhost:8984/rest?run=plotDataviz_prog.xq&amp;target={$target}&amp;locale=fr">⚐</a></small>) else
  (<small class="caption"><a class="picto-item" aria-label="Source et documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁ </a>  <a class="picto-item" aria-label="Ce graphe analyse les programmes et partenariats de numérisation de la BnF pour lesquels des conditions spécifiques d&#8217;accès aux documents numériques existent." href="#">≡</a> <a  class="picto-item" aria-label="English" href="http://localhost:8984/rest?run=plotDataviz_prog.xq&amp;target={$target}&amp;locale=en">⚐</a></small>)}
 </p>
</figure>
</body>
</html>
};


(: execution des requetes sur les bases :)
let $data := collection($DBall) 
return
    local:createOutput($data)

