(:
  Produce a map of the partners
:)

import module namespace gd = "http:/gallicaviz.bnf.fr/" at "../webapp/dataviz_lib.xqm";
import module namespace gdp = "http:/gallicaviz.bnf.fr/env" at "../webapp/dataviz_env.xqm";

declare namespace functx = "http://www.functx.com";

declare option output:method 'html';

(: Arguments avec valeurs par defaut :)
declare variable $locale as xs:string external := "fr" ; 

(: Parameters :)
declare variable $width as xs:integer := 800 ;
declare variable $height as xs:integer := 680 ;
 
(: construction de la page HTML :)
declare function local:createOutput() {
<html>
{
let $title := if ($locale='fr') then ("Carte des partenaires Gallica") else 
("Map of the Gallica's partners")
let $todayDate := current-date()
let $date := gd:date($todayDate,$locale)
let $subTitle := gdp:subtitle($date, $locale)

return
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"></meta>
<title>{$title}</title>
<script src="https://code.highcharts.com/maps/highmaps.js"></script>
<script src="https://code.highcharts.com/modules/exporting.js"></script>
<script src="https://code.highcharts.com/modules/accessibility.js"></script>
<script src="https://code.highcharts.com/modules/export-data.js"></script>
<script src="https://code.highcharts.com/modules/marker-clusters.js"></script>
<script src="/static/he.js"></script>

<script type="text/javascript">
(async () => {{
    const topology = await fetch(
      'https://code.highcharts.com/mapdata/countries/fr/custom/fr-all-mainland.topo.json'
    ).then(response => response.json());

    const dataReg = await fetch(
      '/static/data_regions.json'
    ).then(response => response.json());   

   const dataI = await fetch(
      '/static/data_partnersI.json'
    ).then(response => response.json());
    
   const dataCit = await fetch(
      '/static/data_cities.json'
    ).then(response => response.json());
    
  Highcharts.getJSON('/static/data_partnersH.json',
   function (dataH) {{
      
    Highcharts.mapChart('container', {{
      chart: {{
        map: topology,
        backgroundColor: "{$gdp:backgroundColor}",
        spacingBottom: 30,
        spacingTop: 30,
        spacingLeft: 10,
        spacingRight: 10,
      // Explicitly tell the width and height of a chart
      width: {$width},
    	height: {$height}
      }},
      title: {{
        margin: {$gdp:marginTop},
        style: {{
            fontWeight: 'bold'
        }},
         text: "{$title}"
      }},
     subtitle: {{
        style: {{
            fontWeight: 'bold'
        }},
        text: '{$subTitle}'
      }},
      mapNavigation: {{
        enabled: true
      }},
     
     tooltip: {{
          headerFormat: '',
          pointFormat: '<b style="color:{{point.color}}">{{point.name}}</b>' +  '<br></br>' + '{gdp:openInGallica($locale)}'      
      }},
      
      
      plotOptions: {{
        series: {{
            cursor: 'pointer',
            point: {{
                events: {{
                    click: function () {{
                      if(this.options.url) {{
                        myURL = this.options.url  ; 
                        console.log(myURL)  ;                          
                        window.open(he.decode("{$gdp:SRU}" + myURL,'_blank' ));
                      }} else{{                   
                      }}                     
                    }}
                }}
            }}
        }},
        mappoint: {{
          cluster: {{
            enabled: true,
            allowOverlap: false,
            animation: {{
              duration: 450
            }},
            layoutAlgorithm: {{
              type: 'grid',
              gridSize: 70
            }},
            zones: [{{
              from: 1,
              to: 2,
              marker: {{
                radius: 14
              }}
            }}, {{
              from: 3,
              to: 4,
              marker: {{
                radius: 16
              }}
            }}, {{
              from: 5,
              to: 6,
              marker: {{
                radius: 18
              }}
            }}, {{
              from: 16,
              to: 20,
              marker: {{
                radius: 20
              }}
            }}]
          }}
        }}
      }},
      series: [{{
        name: 'Regions',
        data: dataReg,
        joinBy: ['hc-key', 'name'],
        accessibility: {{
          exposeAsGroupOnly: true
        }},
        tooltip: {{
         headerFormat: '',
          pointFormat: '<b style="font-size:7pt">{{point.name}}</b> :'+'<br></br>' + '<span style="font-size:7pt">{{point.x}} {gdp:partnersCriteria($locale)}</span>'
        }},
        dataLabels: {{
            enabled: false,
            format: '{{point.name}}',
            style: {{
              fontWeight: 'normal',
              fontSize: 7,
              color: "rgb(51,75,128)",
              textOutline: "0px"
            }}
        }},
        states: {{
            hover: {{
                color: '{$gdp:regionHoverColor}' ,
                textOutline: "4px"
            }}
        }},
        borderColor: 'lightgray',
        nullColor: 'lightgray',
        showInLegend: false
      }},{{
        type: 'mappoint',
        enableMouseTracking: true,       
        name: 'cities',
        data: dataCit,
        color: '{$gdp:cityColor}',
        marker: {{
          lineWidth: 0,
          lineColor: '#fff',        
          radius: 4
        }},
        showInLegend: false,
        dataLabels: {{
          verticalAlign: 'top',
          style: {{
              fontWeight: 'normal',
              fontSize: 7,
              color: "{$gdp:cityColor}",
              textOutline: "0px"
            }}
        }}
      }},{{
        type: 'mappoint',
        enableMouseTracking: true,
        accessibility: {{
          point: {{
            descriptionFormatter: function (point) {{
              if (point.isCluster) {{
                return 'Grouping of ' + point.clusterPointsAmount + ' points.';
              }}
              return point.name + ', country code: ' + point.country + '.';
            }}
          }}
        }},
        
        colorKey: 'clusterPointsAmount',
        name: "{gdp:provName($gdp:partnersList[1],$locale)}",
        data: dataI,
        color: {$gdp:partnersColors($gdp:partnersList[1])},
        marker: {{
          lineWidth: 1,
          lineColor: '#fff',
          symbol: 'mapmarker',
          radius: 8
        }},
        dataLabels: {{
          verticalAlign: 'top'
        }}
      }},
       {{
        type: 'mappoint',
        enableMouseTracking: true,
        accessibility: {{
          point: {{
            descriptionFormatter: function (point) {{
              if (point.isCluster) {{
                return 'Grouping of ' + point.clusterPointsAmount + ' points.';
              }}
              return point.name + ', country code: ' + point.region + '.';
            }}
          }}
        }},      
        colorKey: 'clusterPointsAmount',
        name: "{gdp:provName($gdp:partnersList[2],$locale)}",
        data: dataH,
        color: {$gdp:partnersColors($gdp:partnersList[2])},
        marker: {{
          lineWidth: 1,
          lineColor: '#fff',
          symbol: 'mapmarker',
          radius: 8
        }},
        dataLabels: {{
          verticalAlign: 'top'
        }}
      }}
    
  ]
    }});
  }});

}})();
</script>
</head>
}
<body>
<style>
.highcharts-description  {{
    font-family: Lucida Grande, sans-serif;
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
    font-family: Lucida Grande, sans-serif;
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


<figure class="highcharts-figure">
	<div>
    <div id="container"></div>
</div>


<p class="highcharts-description">
 {if ($locale='en') then (
   <small class="caption"><a class="picto-item" aria-label="Source and documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁</a>  <a class="picto-item" aria-label="This map shows the partners of the Gallica digital collection." href="#">≡</a> <a  class="picto-item" aria-label="French" href="{$gdp:appPrefix}/rest?run=plotDataviz_partners_map.xq&amp;locale=fr">⚐</a></small>) else
  (<small class="caption"><a class="picto-item" aria-label="Source et documentation" href="https://github.com/altomator/Gallica_Dataviz" target="_blank">☁ </a>  <a class="picto-item" aria-label="Cette carte montre les partenaires contribuant à la collection numérique Gallica." href="#">≡</a> <a  class="picto-item" aria-label="English" href="{$gdp:appPrefix}/rest?run=plotDataviz_partners_map.xq&amp;locale=en">⚐</a></small>)}
 </p>
</figure>
</body>
</html>
};


(: execution de la requete sur la base :)
let $data := "foo" 
return
    local:createOutput()
