/// Helper for Organization Resource
Class HS.Local.FHIRServer.Resources.Organization Extends HS.Local.FHIRServer.Resources.Humanname
{

/// Generate Text
ClassMethod GenerateText(resource As %DynamicObject) As %String
{
    return resource.resourceType _ " named " _ resource.name
}

/// GetDisplayForReference
ClassMethod GetDisplayForReference(resource As %DynamicObject) As %String
{
    return resource.name
}

}
