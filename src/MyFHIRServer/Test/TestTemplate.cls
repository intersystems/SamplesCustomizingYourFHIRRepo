Class MyFHIRServer.Test.TestTemplate
{

/// Description
ClassMethod Test1() As %Status [ Language = python ]
{
        import jinja2
        title = 'Hi this is my title'
        outputfile = 'myfile.html'
        subs = jinja2.Environment( 
                    loader=jinja2.FileSystemLoader('./')      
                    ).get_template('template.html').render(title=title) 
        # lets write the substitution to a file
        with open(outputfile,'w') as f: f.write(subs)
}

ClassMethod Test2() As %String [ Language = python ]
{
        from jinja2 import Template
        t = Template("Hello {{ something }}!")
        ret = t.render(something="World")

        return ret

        #t = Template("My favorite numbers: {% for n in range(1,10) %}{{n}} " "{% endfor %}")
        #t.render()
}

ClassMethod Test3() As %String [ Language = python ]
{
        from jinja2 import Template
        t = Template("<div xmlns=\"http://www.w3.org/1999/xhtml\">\n\t\t\t" +
           " <table>\n\t\t\t\t"+
            "<tbody>\n\t\t\t\t\t" +
          "<tr>\n\t\t\t\t\t\t" +
          "	<td>Name</td>\n\t\t\t\t\t\t" +
          "	<td>{{firstname}} \n              <b>{{lastname}}</b> \n            </td>\n\t\t\t\t\t" +
          "</tr>\n\t\t\t\t\t" +
          "<tr>\n\t\t\t\t\t\t" +
          "	<td>Address</td>\n\t\t\t\t\t\t" +
          "	<td>{{address}}}}</td>\n\t\t\t\t\t" +
          "</tr>\n\t\t\t\t\t" +
          "<tr>\n\t\t\t\t\t\t" +
	          "<td>Contacts</td>\n\t\t\t\t\t\t" +
	          "<td>Home: {{phone}}}}</td>\n\t\t\t\t\t" +
          "</tr>\n\t\t\t\t\t" +
          "<tr>\n\t\t\t\t\t\t" +
	          "<td>Id</td>\n\t\t\t\t\t\t" +
	          "<td>{{idtype}}}}: {{idnum}} ({{idsource}})</td>\n\t\t\t\t\t" +
          "</tr>\n\t\t\t\t" +
          "</tbody>\n\t\t\t" +
          "</table>\n\t\t" +
          "</div>")
        ret = t.render(firstname="Max",lastname="Smith")

        return ret

        #t = Template("My favorite numbers: {% for n in range(1,10) %}{{n}} " "{% endfor %}")
        #t.render()
}

ClassMethod Test4() As %String [ Language = python ]
{
        import jinja2
        
        t = jinja2.Environment( 
                    loader=jinja2.FileSystemLoader('./')      
                    ).get_template('patientDiv.html')

        
        ret = t.render(firstname="Max",lastname="Smith")

        return ret

        #t = Template("My favorite numbers: {% for n in range(1,10) %}{{n}} " "{% endfor %}")
        #t.render()
}

}
