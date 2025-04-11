/// Helper for Patient Resource
Class HS.Local.FHIRServer.Resources.Patient Extends HS.Local.FHIRServer.Resources.Person
{

/// Get narrative for the patient
ClassMethod GenerateText(patient As %DynamicObject) As %String [ Language = python ]
{
    import iris
    import jinja2
    
    t = jinja2.Environment( 
                loader = jinja2.FileSystemLoader('./')      
                ).get_template('patientDiv.html')
    lastname = patient._Get("name")._Get(0)._Get("family")
    firstname = patient._Get("name")._Get(0)._Get("given")._Get(0)
    #; address = patient._Get("address")._Get(0)._Get("line")._Get(0)
    #; address = address + ", " + patient._Get("address")._Get(0)._Get("city")
    #; address = address + ", " + patient._Get("address")._Get(0)._Get("state")
    #; address = address + ", " + patient._Get("address")._Get(0)._Get("country")
    phone = patient._Get("telecom")._Get(0)._Get("value")
    idnum = patient._Get("identifier")._Get(0)._Get("value")
    
    ret = t.render(firstname = firstname, lastname = lastname, address = "", phone = phone, idnum = idnum)

    return ret
}

}
