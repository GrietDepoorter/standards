xquery version "3.0";

module namespace rf = "http://clarin.ids-mannheim.de/standards/recommended-formats";

import module namespace spec = "http://clarin.ids-mannheim.de/standards/specification" at "../model/spec.xqm";
import module namespace format = "http://clarin.ids-mannheim.de/standards/format" at "../model/format.xqm";
import module namespace centre = "http://clarin.ids-mannheim.de/standards/centre" at "../model/centre.xqm";
import module namespace domain = "http://clarin.ids-mannheim.de/standards/domain" at "../model/domain.xqm";
import module namespace recommendation = "http://clarin.ids-mannheim.de/standards/recommendation-model"
at "../model/recommendation-by-centre.xqm";

import module namespace app = "http://clarin.ids-mannheim.de/standards/app" at "app.xql";
import module namespace dm = "http://clarin.ids-mannheim.de/standards/domain-module" at "../modules/domain.xql";

import module namespace functx = "http://www.functx.com" at "../resources/lib/functx-1.0-doc-2007-01.xq";

declare variable $rf:pageSize := 50;
declare variable $rf:searchMap := rf:getSearchMap();
    
declare function rf:getSearchMap(){
    let $fids := distinct-values(($recommendation:format-ids, $format:ids))
    let $fabbrs := distinct-values(($recommendation:format-abbrs,$format:abbrs))
    
    (: $centre:names problematic:)
    let $formatIdMap := for $item in $fids return map:entry($item,"fid")
    let $formatAbbrMap := for $item in $fabbrs return map:entry($item,"fabbr")
    let $formatNameMap := for $item in $format:titles return map:entry($item,"fname")
    let $centreIdMap := for $item in $centre:ids return map:entry($item,"cid")
    let $domainMap := for $item in $domain:names return map:entry($item,"dname")
    let $searchMap := map:merge(($formatIdMap,$formatAbbrMap,$formatNameMap,$centreIdMap, $domainMap))
    return $searchMap
    (:map:get($searchMap,"DANS"):)
};

declare function rf:countFid(){
    (count($recommendation:format-ids),
    count(distinct-values(($recommendation:format-ids, $format:ids))))
};

declare function rf:listSearchSuggestions(){
    (: $centre:names problematic:)
    let $fids := distinct-values(($recommendation:format-ids, $format:ids))
    let $fabbrs := distinct-values(($recommendation:format-abbrs,$format:abbrs))
    
    let $union := 
        for $item in ($fids,$fabbrs,$format:titles,$centre:ids,$domain:names) 
        order by fn:lower-case($item) 
        return $item 

    return fn:string-join($union,",")
};

declare function rf:searchFormat($searchItem){
    let $category := map:get($rf:searchMap,$searchItem)
    return 
    if ($category eq "fid")
        then rf:print-centre-recommendation($searchItem)
    else if ($category eq "fabbr")
        then rf:searchFormatByAbbr($searchItem)
    else if ($category eq "fname")
        then rf:searchFormatByName($searchItem)
    else if ($category eq "cid") 
        then rf:print-centre-recommendation($searchItem,'','','')
    else if ($category eq "dname")
        then rf:searchFormatByDomain($searchItem)
    else ()
};

declare function rf:searchFormatByAbbr($abbr){
    let $fid := data(format:get-format-by-abbr($abbr)/@id)
    let $fid := if ($fid) then $fid else concat("f",$abbr)
    return rf:print-centre-recommendation($fid)
};

declare function rf:searchFormatByName($name){
    let $fid := data($format:formats[titleStmt/title=$name]/@id)
    return rf:print-centre-recommendation($fid)
};


declare function rf:searchFormatByDomain($searchItem){
    let $domainId := domain:get-id-by-name($searchItem)
    return rf:print-centre-recommendation('',$domainId,'','')
};

declare function rf:print-page-links($numOfRows, $sortBy, $domainId, $recommendationLevel, $centre, $page as xs:int) {
    let $numberOfPages := xs:integer(fn:ceiling($numOfRows div $rf:pageSize))
    
    for $i in (1 to $numberOfPages)
    let $pageLink := <a
        href="{
                app:link(concat("views/recommended-formats-with-search.xq?sortBy=",
                $sortBy, "&amp;domain=", $domainId, "&amp;level=", $recommendationLevel,
                "&amp;centre=", $centre, "&amp;page=", $i, "#searchRecommendation"))
            }">{$i}</a>
    return
        if ($i = $page) then
            $page
        else
            if ($i < $page)
            then
                ($pageLink, " < ")
            else
                (" > ", $pageLink)

};

declare function rf:paging($rows, $page as xs:int) {
    let $numOfRows := count($rows)
    
    let $max := fn:min(($numOfRows, $page * $rf:pageSize)) + 1
    let $min := if ($page > 1) then
        (($page - 1) * $rf:pageSize)
    else
        1
    
    return
        $rows[position() >= $min and position() < $max]
};

declare function rf:print-centres($centre) {
    let $depositing-centres := $centre:centres[@deposition = "1" or @deposition = "true"]
    for $c in data($depositing-centres/@id)
        order by fn:lower-case($c)
    return
        if ($c eq $centre)
        then
            (<option
                value="{$c}"
                selected="selected">{$c}</option>)
        else
            (<option
                value="{$c}">{$c}</option>)
};

declare function rf:print-domains($domains) {
    for $d in $domain:domains
    let $id := $d/@id
        order by fn:lower-case($d/name/text())
    return
        if (functx:is-value-in-sequence($id,$domains))
        then
            <option
                value="{$id}"
                selected="selected"
                title="{$d/desc/text()}">{$d/name/text()}</option>
        else
            <option
                value="{$id}"
                title="{$d/desc/text()}">{$d/name/text()}</option>
};

declare function rf:print-keywords($keyword) {
    let $keywords := $format:formats/keyword
    for $k in fn:distinct-values($keywords)
        order by fn:lower-case($k)
    return
        if ($k eq $keyword)
        then
            (<option
                value="{$k}"
                selected="selected">{$k}</option>)
        else
            (<option
                value="{$k}">{$k}</option>)
};

declare function rf:print-option($selected, $value, $label) {
    if(empty($selected))
    then
        <option value="{$value}">{$label}</option>
    else
        for $s in $selected
        return
            if ($s eq $value)
            then
                <option
                    value="{$value}"
                    selected="selected">{$label}</option>
            else
                <option
                    value="{$value}">{$label}</option>
};

declare function rf:print-centre-recommendation($requestedFormatId){
    for $r in $recommendation:centres
        let $centre := $r/header/filter/centre/text()
        for $format in $r/formats/format
            let $format-id := data($format/@id)
            let $format-abbr := $format:formats[@id=$format-id]/titleStmt/abbr/text()
            
            let $domainName := $format/domain/text()
            let $domain := 
                if ($domainName) then
                    dm:get-domain-by-name($domainName)
                else ()
            
            order by (if ($format-abbr) then fn:lower-case($format-abbr) else fn:lower-case(fn:substring($format-id,2))) (:abbr:)
        return 
            if ($format-id eq $requestedFormatId)
            then rf:print-recommendation-row($format, $centre, $domain)
            else ()
};

declare function rf:print-centre-recommendation($requestedCentre, $requestedDomain,
$requestedLevel, $sortBy) {
    
    for $r in $recommendation:centres
    let $centre := $r/header/filter/centre/text()
    
    for $format in $r/formats/format
    let $domainName := $format/domain/text()
    let $domain := if ($domainName) then
        dm:get-domain-by-name($domainName)
    else
        ()
    
    let $level := $format/level/text()
    let $format-id := data($format/@id)
    let $format-abbr := $format:formats[@id=$format-id]/titleStmt/abbr/text()
    let $format-info := $format/info/text()
        
        order by
        if ($sortBy = 'centre') then
            $centre
        else
            if ($sortBy = 'domain') then
                $domainName
            else
                if ($sortBy = 'recommendation') then
                    $level
                else
                    (if ($format-abbr) then fn:lower-case($format-abbr) else fn:lower-case(fn:substring($format-id,2))) (:abbr:)
    
    return
        if ($requestedCentre)
        then
        (
            if ($requestedCentre eq $centre)
            then
                (
                if (not(empty($requestedDomain)))
                then
                    (rf:checkRequestedDomain($requestedDomain, $requestedLevel,
                    $format, $centre, $domain))
                else
                    (
                    if ($requestedLevel)
                    then
                        (rf:checkRequestedLevel($requestedLevel, $format, $centre, $domain))
                    else
                        (rf:print-recommendation-row($format, $centre, $domain))
                    )
                )
            else
                ()
         )
        else
        (
            if (not(empty($requestedDomain)))
            then
                (rf:checkRequestedDomain($requestedDomain, $requestedLevel,
                $format, $centre, $domain))
            else
                (
                if ($requestedLevel)
                then
                    (rf:checkRequestedLevel($requestedLevel, $format, $centre, $domain))
                else
                    (rf:print-recommendation-row($format, $centre, $domain))
                )
        )

};

declare function rf:checkRequestedDomain($requestedDomain, $requestedLevel,
$format, $centre, $domain) {
    
    if (functx:is-value-in-sequence(data($domain/@id),$requestedDomain))
    then
        (
        
        if ($requestedLevel)
        then
            (rf:checkRequestedLevel($requestedLevel, $format, $centre, $domain))
        else
            (rf:print-recommendation-row($format, $centre, $domain))
        )
    else
        ()
};

declare function rf:checkRequestedLevel($requestedLevel, $format, $centre, $domain) {
    
    if ($requestedLevel eq $format/level/text())
    then
        (rf:print-recommendation-row($format, $centre, $domain))
    else
        ()

};

declare function rf:print-recommendation-row($format, $centre, $domain) {
    rf:print-recommendation-row($format, $centre, $domain, fn:true(), fn:true())

};

declare function rf:print-recommendation-row($format, $centre, $domain, $includeFormat,$includeCentre) {
    
    let $format-id := data($format/@id)
    let $format-obj := format:get-format($format-id)
    let $format-abbr := $format-obj/titleStmt/abbr/text()
    let $format-link :=
        if ($format-obj) then (
            <a href="{app:link(concat("views/view-format.xq?id=", $format-id))}">
            {if ($format-abbr) then $format-abbr else $format-id}
            </a>
        )
        else rf:print-missing-format-link($format-id)
        
    let $level := $format/level/text()
    let $format-comment := $format/comment
    
    let $domainId := data($domain/@id)
    let $domainName := $domain/name/text()
    let $domainDesc := $domain/desc/text()
    
    return
        <tr>
            {
                if ($includeFormat) then
                    <td
                        class="recommendation-row"
                        id="{$format-id}">
                        {$format-link}
                    </td>
                else
                    ()
            }
            {
                if ($includeCentre)
                then
                <td
                    class="recommendation-row">{$centre}</td>
                else ()
            }
            <td
                class="recommendation-row"
                id="{$domainId}">
                <span class="tooltip">{$domainName}
                    <span
                        class="tooltiptext" style="left:20%">{$domainDesc}
                    </span>
                </span>
                </td>
            <td
                class="recommendation-row">{$level}</td>
            {
                if ($includeFormat and $includeCentre) 
                then (
                    <td class="tooltip">{
                            if ($format-comment) then
                                (
                                <img
                                    src="{app:resource("info.png", "img")}"
                                    height="17"/>,
                                <span
                                    class="tooltiptext"
                                    style="width:200px;">{$format-comment}
                                </span>)
                            else
                                ()
                        }
                    </td>(:,
                    <td>
                    {
                    if ($format-obj) 
                        then () 
                        else
                        <a href="{concat('https://github.com/clarin-eric/standards/issues/new?assignees=&amp;labels=SIS%3Aformats%2C+templatic&amp;template=incorrect-missing-format-description.md&amp;title=','Suggestion of a format description for ID="',
                        $format-id,'"')}">
                             <img src="{app:resource("plus.png", "img")}" height="15"/> </a>
                    }
                    </td>:)
                )
                else
                    <td
                        class="recommendation-row">
                        {$format-comment}
                    </td>
            }
        </tr>
};

declare function rf:print-missing-format-link($format-id){
    (fn:substring($format-id,2), 
    <span class="tooltip">
        <a style="margin-left:5px;" href="{app:getGithubIssueLink($format-id)}">
            <img src="{app:resource("plus.png", "img")}" height="15"/> </a>
        <span
            class="tooltiptext"
            style="width:300px;">Click to add or suggest missing format information
        </span>
    </span>)
};

declare function rf:export-table($centre, $domainId, $requestedLevel, $nodes, $filename, $page) {
    let $domain := dm:get-domain($domainId)
    let $domainName := $domain/name/text()
    let $filter :=
    (if ($centre) then
        <centre>{$centre}</centre>
    else
        (),
    if ($domainName) then
        <domain>{$domainName}</domain>
    else
        (),
    if ($requestedLevel) then
        <level>{$requestedLevel}</level>
    else
        ())
    
    let $rows :=
    for $row in $nodes
    return
        <format id="{$row/td[1]/@id}">
            {
                if ($centre eq "") then
                    <centre>{$row/td[2]/text()}</centre>
                else
                    (),
                if ($domainId eq "") then
                    (:<domain
                            id="{$row/td[3]/@id}">{$row/td[3]/text()}</domain>:)
                    <domain>{$row/td[3]/span/text()}</domain>
                else
                    (),
                if ($requestedLevel eq "") then
                    (<level>{$row/td[4]/text()}</level>)
                else
                    ()
            }
        
        </format>
        
        (:let $isExportSuccessful := file:serialize($data, $filename,fn:false()):)
    let $quote := "&#34;"
    let $header1 := response:set-header("Content-Disposition", concat("attachment; filename=",
    $quote, $filename, $quote))
    let $header2 := response:set-header("Content-Type", "text/xml;charset=utf-8")
    
    return
        <recommendation xsi:noNamespaceSchemaLocation="https://clarin.ids-mannheim.de/standards/schemas/recommendation.xsd">
            <header>
                <title>CLARIN Standards Information System (SIS) export</title>
                <url>{app:link($page)}</url>
                <exportDate>{fn:current-dateTime()}</exportDate>
                <filter>{$filter}</filter>
            </header>
            <formats>{$rows}</formats>
        </recommendation>

};

declare function rf:download-template($centre-id,$filename){
    let $quote := "&#34;"
    let $header1 := response:set-header("Content-Disposition", concat("attachment; filename=",
    $quote, $filename, $quote))
    let $header2 := response:set-header("Content-Type", "text/xml;charset=utf-8")
    let $recommendation := recommendation:get-recommendations-for-centre($centre-id)

    return 
    
        <recommendation xsi:noNamespaceSchemaLocation="https://clarin.ids-mannheim.de/standards/schemas/recommendation.xsd">
            <header>
                <title>CLARIN Standards Information System (SIS) export</title>
                <url>{app:link(concat("/views/view-centre.xq?id=",$centre-id))}</url>
                <exportDate>{fn:current-dateTime()}</exportDate>
                <filter>
                   <centre>{$centre-id}</centre>
                </filter>
            </header>
            {$recommendation/formats}    
        </recommendation>
};
