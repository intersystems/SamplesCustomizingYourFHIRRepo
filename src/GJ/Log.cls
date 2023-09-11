/// Display FHIR server Log from ^FSLOG
/// Author: Gertjan Klein
Class GJ.Log Extends %CSP.Page
{

/// Quick'n'Dirty
/// http://localhost:52773/csp/healthshare/fhir/GJ.Log.cls
/// enabled using: set ^FSLogChannel("all") = 1
ClassMethod OnPage() As %Status [ ServerOnly = 1 ]
{
	&html<<html>
<head><title>FSLOG</title>
#(..Style())#
</head><body><header>
<form method=post action=""><button name=clear type=submit>Clear</button></form>
<h1>FSLOG contents</h1></header>
>
	If $Order(^FSLOG("")) = "" {
		&html<<div>FSLOG global is empty.</div>>
	}
	
	;CurrentMethod^CurrentClass|LogType|LogMessage|DateTime
	Set Key = ""
	For  {
		Set Key = $Order(^FSLOG(Key), -1, Record)
		If Key = ""
		{
			Quit
		}
		
		Set Where = $Piece(Record, "|", 1)
		Set Type = $Piece(Record, "|", 2)
		Set Message = $Piece(Record, "|", 3, *-1)
		Set TimeStamp = $Piece(Record, "|", *)
		Set jobNumber = $Piece(Where, "^", 3)
		Set Class = $Piece(Where, "^", 2)
		Set Method = $Piece(Where, "^", 1)
		
		If TimeStamp '= "" {
			Set TimeStamp = $ZDateTimeH(TimeStamp, , 3)
			Set TimeStamp = $ZDateTime(TimeStamp, 3, 1, 3)
		}

		&html<
<div class=where>
<span>[#(Key)#]</span>
<span>#(TimeStamp)# at #($ZConvert(Class_":"_Method, "O", "HTML"))#, job #(jobNumber)#,
type #($ZConvert(Type, "O", "HTML"))#</span>
</div>
<div class=msg>#(..Escape(Message))#</div>
>
	}
	
	Write "</body></html>",!
	return $$$OK
}

/// Escape 
ClassMethod Escape(Text As %String) As %String
{
	Set Text = $ZConvert(Text, "O", "HTML")

	For i = 1:1:31
	{
		Set Hex = $ZHex(i)

		If $Length(Hex) = 1
		{
			Set Hex = "0" _ Hex
		}
		Set Text = $Replace(Text, $Char(i), "<span title=Binair>" _ Hex _ "</span>")
	}
	
	return Text
}

/// Style
ClassMethod Style() As %String
{
	&html<<style>
header {
  background-color: #eee;
  border-radius: 5px;
  padding: 0 0.5em;
  margin: 0 0 1em 0;
}
h1 { margin: 0; }
form { float:right; margin-top:0.5em; }
div { font-family: Cambria; }
.where { color: #999; }
.msg {
  margin-bottom: 0.3em;
}
.msg span {
  font-family: monospace;
  color: #fff;
  background-color: #c66;
  padding: 0 1px 1px 0;
  margin: 0 1px;
}
.msg span::before { content: '(' }
.msg span::after { content: ')' }
</style>>
	return ""
}

/// OnPreHTTP
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	#dim %request As %CSP.Request
	#dim %response As %CSP.Response
	
	If %request.Method = "POST" {
		If %request.IsDefined("clear") {
			Kill ^FSLOG
			; So F5 keeps working
			Set %response.Redirect = ..%ClassName(1)_".cls"
		}
	}
	
	return 1
}

}
