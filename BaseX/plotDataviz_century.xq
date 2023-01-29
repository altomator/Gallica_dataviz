(:
 Recherche de pages illustrees par les annotations
:)

declare namespace functx = "http://www.functx.com";

declare option output:method 'html';

(: Arguments avec valeurs par defaut :)
(: cible de l'analyse :)
declare variable $target as xs:string external := "full"  ;  (: full, bnf_and_integrated, bnf, partners, integrated, harvested  :)
declare variable $log as xs:string external := "false" ;

declare variable $types  := ("periodical", "monograph", "image", "manuscript", "music" )  ;
declare variable $types_fr  := ("fascicule", "monographie", "image", "manuscrit", "partition")  ;

declare variable $DBtarget as xs:string  := concat("gallica_century_", $target,"-monograph") ; 
declare variable $DBprefix as xs:string := "gallica_century_" ;


declare variable $locale as xs:string external := "fr" ; 

(: convert source category to DB name:)
declare variable $sourceName := map{
    "BnF":"bnf", 
    "intégrés":"integrated", 
    "moissonnés":"harvested"
   };
      
(: declare variable $currentDate as xs:date  := current-date(); :)

(: Parameters :)
(: Pie colors :)
declare variable $mainColor as xs:string := "#3b9db3" ; (: green  :) 
declare variable $otherInnerColor as xs:string := "#B8B0AE" ; (: gray :)
declare variable $innerColor := "red";
declare variable $gallicaColors := map{
    "periodical":"#128799", 
    "monograph":"#149BB1", 
    "manuscript":"#78B7B7", 
    "music score":"#D6E9E9 ", 
    "map":"#d5c6ba ", 
    "image":"#a5846b", 
    "object":"#c2ab9b", 
    "sound":"#89A2B4", 
    "video":"#D2E1EC"};
            
declare variable $other  as xs:string := if ($locale='fr') then ("autres") else ("other");
declare variable $criteria as xs:string :=  if ($locale='fr') then ("Types") else ("Types") ; (: label of the graph criteria :)
declare variable $width as xs:integer := 1250 ;
 
(: URL Gallica SRU de base :)
declare variable $SRU as xs:string external := fn:escape-html-uri("https://gallica.bnf.fr/services/engine/search/sru?operation=searchRetrieve&amp;exactSearch=false&amp;collapsing=false&amp;query=");

declare function local:evalQuery($query) {
    let $hits := xquery:eval($query)
    return $hits
};

(: return a color for a given document type:)
declare function local:columnColors($doc_type) {
    let $foo := map:get( $gallicaColors, $doc_type)
    return $foo
};

(: construction de la page HTML :)
declare function local:createOutput($db) {
<html>
{
let $targetName := if ($locale='fr') then (data($db//source_fr)) else (data($db//source))
let $processingDate := xs:date($db//date)
let $date := if ($locale='fr') then (format-date($processingDate, "[D]-[M]-[Y]")) else (format-date($processingDate, "[Y]-[M]-[D]"))



let $title := if ($locale='fr') then (concat ("Analyse par date de publication pour la provenance : ",$targetName)) else 
(concat ("Analysis by publication date for provenance: ",$targetName))
let $subTitle := if ($locale='fr') then (concat('Source : <a href="https://gallica.bnf.fr" target="_default">Gallica</a> et <a href="https://api.bnf.fr/fr/api-gallica-de-recherche" target="_default">API Gallica SRU</a> (', $date,')')) else (concat('Source: <a href="https://gallica.bnf.fr" target="_default">Gallica</a> and <a href="https://api.bnf.fr/fr/api-gallica-de-recherche" target="_default">Gallica SRU API</a> (', $date,')'))

(: data :)
let $centuries := $db//century/item
let $totalData := count($centuries)

let $dataCentury := for $c at $position in $centuries
 let $stringData := concat(' "',data ($c),'"',
    (if ($position != $totalData) then ',') ,codepoints-to-string(10))
  return $stringData
return

let $collsData := for $t at $pos1 in $types
  let $totalTypes := count($types)
  let $DBname := concat($DBprefix,$target,"-",$types[$pos1])
  let $db := collection($DBname)
  let $centuryData := $db//sru/item 
  let $total := $db//total
  let $totalF := $db//total_with_facet
  let $totalData := count($centuryData)  
  let $name := if ($locale='fr') then ($types_fr[$pos1]) else ($t)     
  let $cover :=  $totalF div $totalData
  let $urlTarget := $db//search/item
  let $stringData := concat(' {  
        name: "',$name,'",
        color: "', local:columnColors($t), '",   
        data: [ ',                             
           let $tmp := for $c at $pos2 in $centuryData 
           let $url := concat($SRU, data($urlTarget[$pos2]))
            return concat('{ y: ', data($c), 
            ', total: ', $total, ', totalF: ', $totalF, 
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
<script src="/static/he.js"></script>
<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
<script type="text/javascript">
$(function () {{
  

$('#container').highcharts({{
chart: {{
	type: "column",
  backgroundColor: "#EBEBEB",
	spacingBottom: 30,
  spacingTop: 30,
  spacingLeft: 10,
  spacingRight: 10,
  // Explicitly tell the width and height of a chart
  width: {$width},
  height: 630
}},
title: {{
   margin: 50,
   style: {{
            fontWeight: 'bold'
        }},
  text: "{$title}"
}},
xAxis: {{
  categories: [
      {$dataCentury} 
 ], 
 title: {{
            text: 'Siècles'
        }}
}},
yAxis: {{
        {if ($log != 'false') then ("type: 'logarithmic',") else ()}
        
        title: {{
            text: 'Documents'
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
       cv = " couverture date : "      
     }} else {{
       sep = ',' 
       txt = " on "
       cv = " date coverage: "
     }}     
     return  '<b style="color:' + this.series.color + '">' + this.series.name + '</b>' + ' : '+ '<b>' + Highcharts.numberFormat(this.point.y, 0, ',',sep) + "</b> (" + Highcharts.numberFormat(this.point.y/this.point.total * 100, 2, ',',sep) + " %)" + "<br></br>&#x2022; total: " + Highcharts.numberFormat(this.point.total, 0, ',',sep)  + "<br></br>&#x2022;" + cv + Highcharts.numberFormat(this.point.totalF/this.point.total *100, 0, ',',sep) + " %" ;
   }}
}},

plotOptions: {{
  column: {{
            pointPadding: 0.05,
            borderWidth: 1,
            dataLabels: {{
            enabled: true,
            style: {{
            fontWeight: 'normal',
            fontSize: 8
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
  margin: 3em 2em  1.5em  2e;
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
<figure class="highcharts-figure">
	<div>
    <div id="container"></div>
</div>
{if ($locale='fr') then (<p class="scope-description">Collections : <a title ="Toute la collection Gallica" href="http://localhost:8984/rest?run=plotDataviz_century.xq&amp;target=full&amp;locale=fr">Tout</a> &#x2022; <a title ="Les documents numériques de la BnF et de ses partenaires consultables dans Gallica"  href="http://localhost:8984/rest?run=plotDataviz_century.xq&amp;target=bnf_and_integrated&amp;locale=fr">BnF et intégrés</a> &#x2022; <a title="Les documents numériques de la BnF" href="http://localhost:8984/rest?run=plotDataviz_century.xq&amp;target=bnf&amp;locale=fr">BnF</a> &#x2022; <a title ="Les documents numériques des partenaires de la BnF (intégrés et moissonnés)"  href="http://localhost:8984/rest?run=plotDataviz_century.xq&amp;target=partners&amp;locale=fr">partenaires</a> &#x2022; <a title ="Les documents numériques des partenaires de la BnF consultables dans Gallica" href="http://localhost:8984/rest?run=plotDataviz_century.xq&amp;target=integrated&amp;locale=fr">intégrés</a> &#x2022; <a title ="Les documents numériques des partenaires de la BnF référencés dans Gallica" href="http://localhost:8984/rest?run=plotDataviz_century.xq&amp;target=harvested&amp;locale=fr">moissonnés</a> </p> ) 
else
(<p class="scope-description">Collections: <a title ="All the Gallica collection" href="http://localhost:8984/rest?run=plotDataviz_century.xq&amp;target=full&amp;locale=en">Full</a> &#x2022; <a title ="Digital documents from BnF and its partners available in Gallica" href="http://localhost:8984/rest?run=plotDataviz_century.xq&amp;target=bnf_and_integrated&amp;locale=en">BnF and integrated</a> &#x2022; <a title ="Digital documents from BnF" href="http://localhost:8984/rest?run=plotDataviz_century.xq&amp;target=bnf&amp;locale=en">BnF</a> &#x2022; <a title ="Digital documents from BnF&#8217;s partners (integrated and harvested)" href="http://localhost:8984/rest?run=plotDataviz_century.xq&amp;target=partners&amp;locale=en">partners</a> &#x2022; <a title ="Digital documents from the BnF&#8217;s partners available in Gallica" href="http://localhost:8984/rest?run=plotDataviz_century.xq&amp;target=integrated&amp;locale=en">integrated</a> &#x2022; <a title ="Digital documents from the BnF&#8217;s partners listed in Gallica" href="http://localhost:8984/rest?run=plotDataviz_century.xq&amp;target=harvested&amp;locale=en">harvested</a></p>)}

<p class="highcharts-description">
 {if ($locale='en') then (
   <small class="caption"><a class="picto-item" aria-label="Source and documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁</a>  <a class="picto-item" aria-label="This graph analyses the distribution of document types according to the different provenances that make up Gallica." href="#">≡</a> <a  class="picto-item" aria-label="French" href="http://localhost:8984/rest?run=plotDataviz_century.xq&amp;target={$target}&amp;locale=fr">⚐</a> <a  class="picto-item" aria-label="Logarithmic scale" href="http://localhost:8984/rest?run=plotDataviz_century.xq&amp;target={$target}&amp;locale=en&amp;log=true">&#x1f4c8;</a></small>) else
  (<small class="caption"><a class="picto-item" aria-label="Source et documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁ </a>  <a class="picto-item" aria-label="Ce graphe analyse la répartition par types de documents en fonction des différentes provenances constituant Gallica." href="#">≡</a> <a  class="picto-item" aria-label="English" href="http://localhost:8984/rest?run=plotDataviz_century.xq&amp;target={$target}&amp;locale=en">⚐</a> <a  class="picto-item" aria-label="Echelle logarithmique" href="http://localhost:8984/rest?run=plotDataviz_century.xq&amp;target={$target}&amp;locale=fr&amp;log=true">&#x1f4c8;</a></small>)
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
