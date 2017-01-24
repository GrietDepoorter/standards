xquery version "3.0";

declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare option exist:serialize "method=xhtml media-type=text/html indent=yes doctype-system=about:legacy-compat";

import module namespace menu = "http://clarin.ids-mannheim.de/standards/menu" at "../modules/menu.xql";
import module namespace app = "http://clarin.ids-mannheim.de/standards/app" at "../modules/app.xql";

    <html>
        <head>
        	<title>Registration Confirmation</title>
        	<link rel="stylesheet" type="text/css" href="{app:resource("style.css","css")}"/>
        </head>
        <body>
        <div id="all">
            <div class="logoheader"/>
            {menu:view()}
            <div class="content">
                <div class="navigation">
                    &gt; <a href="registration.xq">Registration</a>
                    &gt; Confirmation
                </div>
                <div><span class="heading">Registration Confirmation</span></div>
                <div>
                    <p>You have been succesfully registered to CLARIN IDS Mannheim.</p>
                    <p>Please <a href="login.xq">login</a> using your email and password.</p>                    
                </div>
             </div>
        		<div class="footer">{app:footer()}</div>
        	</div>
        </body>
    </html>