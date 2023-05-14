(: library of functions to be used with the gallica dataviz XQuery app :)

module namespace gd = "http:/gallicaviz.bnf.fr/";


(: eval a query on a BaseX database :)
declare function gd:evalQuery($query) {
    let $hits := xquery:eval($query)
    return $hits
};

(: localize dates :)
declare function gd:date($date as xs:date?, $locale as xs:string?
)  as xs:string {
  if ($locale='fr') then (format-date($date, "[D]/[M]/[Y]")) 
  else (format-date($date, "[Y]/[M]/[D]"))
};

(: localize numbers :)
declare function gd:number($n as xs:double?, $locale as xs:string?
)  as xs:string {
  if ($locale='fr') then (replace(format-number($n, '9,999'),',','&#x2009;'))
  else (format-number($n, '9,999')) 
};

(: avoiding Server-side request forgery :)
declare  function gd:isAlphaNum($string as xs:string) as xs:boolean { 
  matches($string, '^([a-z]|[A-Z]|\d)+$')
};

declare function gd:is-a-number
  ( $value as xs:anyAtomicType? )  as xs:boolean {

   string(number($value)) != 'NaN'
 } ;
 
(: Conversion de formats de date
   Date formats conversion       :)
declare function gd:mmddyyyy-to-date
  ( $dateString as xs:string? )  as xs:date? {

   if (empty($dateString))
   then ()
   else if (not(matches($dateString,
                        '^\D*(\d{2})\D*(\d{2})\D*(\d{4})\D*$')))
   then error(xs:QName('functx:Invalid_Date_Format'))
   else xs:date(replace($dateString,
                        '^\D*(\d{2})\D*(\d{2})\D*(\d{4})\D*$',
                        '$3-$2-$1'))
 } ;

