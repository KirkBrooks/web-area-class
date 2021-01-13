/*  webArea ()
	 Created by: Kirk as Designer, Created: 12/21/20, 14:49:29
	 ------------------
	On the Form: 
	instantiate in context of a form containing the web area:
	     Form.grid_WA:=cs.webArea.new("grid_wa")

	The open_template() function is useful when working with html templates
	All params are passed in the $params object

*/

Class constructor($name : Text)
	If (Count parameters>0)
		This.name:=String($name)  //  the name of the web area
		This.url:=""
		
		//  prefs
		This.prefs:=New object
		This.prefs.contextualMenu:=True
		This.prefs.inspector:=True
		This.prefs.javaApplets:=False
		This.prefs.javaScript:=True
		This.prefs.plugins:=False
		This.prefs.urlDrop:=False
		This.setPref()
		
		This.urlFiltering:=False
		This.fliters:=New collection()
	End if 
	
Function setPref($pref : Text; $flag : Boolean)
	/* sets the pref to true|false */
	If (Count parameters=2)
		This[$pref]:=$flag
	End if 
	
	WA SET PREFERENCE(*; This.name; WA enable contextual menu; This.prefs.contextualMenu)
	WA SET PREFERENCE(*; This.name; WA enable Java applets; This.prefs.javaApplets)
	WA SET PREFERENCE(*; This.name; WA enable JavaScript; This.prefs.javaScript)
	WA SET PREFERENCE(*; This.name; WA enable plugins; This.prefs.plugins)
	WA SET PREFERENCE(*; This.name; WA enable URL drop; This.prefs.urlDrop)
	WA SET PREFERENCE(*; This.name; WA enable Web inspector; This.prefs.inspector)
	
Function set_url_filtering($flag : Boolean)
	If (Count parameters>0)
		This.urlFiltering:=$flag
		
		ARRAY LONGINT($aEvents; 1)
		$aEvents{1}:=On URL Filtering
		
		If ($flag)
			OBJECT SET EVENTS(*; This.name; $aEvents; Enable events others unchanged)
		Else 
			OBJECT SET EVENTS(*; This.name; $aEvents; Disable events others unchanged)
		End if 
		
	End if 
	
Function set_url_filters
	/*  $1 is collection: [{ filter: ""; allow: bool }, ... ]
		enables URL filtering
	*/
	var $1 : Collection
	var $o : Object
	ARRAY TEXT($filters; 0)
	ARRAY BOOLEAN($AllowDeny; 0)
	
	If (Count parameters>0)
		This.filters:=$1
		This.set_url_filtering(True)
		
		For each ($o; This.filters)
			APPEND TO ARRAY($filters; $o.filter)
			APPEND TO ARRAY($AllowDeny; $o.allow)
		End for each 
		
		WA SET URL FILTERS(This.name; $filters; $AllowDeny)
	End if 
	
	// --------------------------------------------------------
Function set_url($params : Object)
	/*  */
	
	If (Count parameters=1)
		Case of 
			: (String($params.url)#"")
				This.url:=$params.url
				
			: (Value type($params.file)=Is object)
				This.url:="File:///"+$params.file.path
				
			: (Value type($params.file)=Is text)
				This.url:=$params.file
				
		End case 
		
		WA OPEN URL(*; This.name; This.url)
		
	End if 
	
Function open_template($params : Object)
	/*  
		template: text|object    //  template to open
		  either 4D File object or system path to file
		head:   pointer or text for <head>
		body:   pointer or text for <body>
		footer: pointer or text for <footer>
			
		target: optional; system path to file | file object
		name:   name for the target template file
			
		target and name are optional. 
		Without either one the file will be 'temp.html'
		if target is specified the setText() is used
		if name is specified the template will be written to the wa_html folder with that name
			
		--------------
		1) get the template file object
		2) PROCESS TAGS on it if $1 or $2 
		3) put file at target
		     default target is wa_html/  next to RESOURCES
		4) open the file in the WA
	*/
	var $template_o; $htmlFile_o : Object
	var $html_text; $temp_t; $head_t; $body_t; $footer_t : Text
	
	If (Count parameters>0)
		If (Value type($params.template)=Is object)
			$template_o:=$params.template
		Else 
			$template_o:=File($params.template; fk platform path)
		End if 
		
		If ($template_o.exists)
			
			$head_t:=This._get_params_text("head"; $params)
			$body_t:=This._get_params_text("body"; $params)
			$footer_t:=This._get_params_text("footer"; $params)
			
			// --------------------------------------------------------
			// get the html_text
			$temp_t:=$template_o.getText()
			
			PROCESS 4D TAGS($temp_t; $html_text; $body_t; $head_t; $footer_t)
			
			// --------------------------------------------------------
			//   the destination file
			Case of 
				: (Value type($params.target)=Is object)
					$htmlFile_o:=$params.target
					
				: (Value type($params.target)=Is text)
					$htmlFile_o:=File(This._get_default_wa_folder().path+$params.target; fk posix path)
					
				Else   //  default
					$htmlFile_o:=File(This._get_default_wa_folder().path+"temp.html"; fk posix path)
					
			End case 
			
			$htmlFile_o.setText($html_text)
			This.set_url(New object("file"; $htmlFile_o))
			
		Else 
			ALERT("The HTML template can't be found.")
		End if 
		
	End if 
	
Function _get_params_text($key : Text; $params : Object)
	/* extracts and returns as text data from $params */
	var $0; $key : Text
	
	Case of 
		: (Count parameters#2)
		: ($key="")
		: (Value type($params[$key])=Is undefined)
			
		: (Value type($params[$key])=Is pointer)
			$0:=String($params[$key]->)
			
		: (Value type($params[$key])=Is text)
			$0:=$params[$key]
			
		: (Value type($params[$key])=Is object) | (Value type($params[$key])=Is collection)
			$0:=JSON Stringify($params[$key])
			
		Else 
			$0:=String($params[$key])
			
	End case 
	
	// --------------------------------------------------------
Function _get_default_wa_folder
	// folder object for the wa_html folder
	// by default it is on the same level as RESOURCES
	var $0 : Object
	$0:=Folder(Folder(Folder(fk resources folder).platformPath; fk platform path).parent.path+"wa_html/")
	
Function _get_css_folder
	var $0 : Object
	$0:=Folder(fk resources folder).folder("css")
