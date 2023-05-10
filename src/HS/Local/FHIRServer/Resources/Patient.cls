/// Helper for Patient Resource
Class HS.Local.FHIRServer.Resources.Patient Extends HS.Local.FHIRServer.Resources.Person
{

/// Generate Text
ClassMethod GenerateText(pResourceObj As %DynamicObject) As %String
{
    #; return resource.resourceType _ " named " _ ..FindAndFormatFullName(resource.name) _ " born at " _ resource.birthDate _ " with gender " _ resource.gender

    return ##class(MyFHIRServer.Util.NarrativeGenerator).GetPatientNarrative(pResourceObj)
}

}
