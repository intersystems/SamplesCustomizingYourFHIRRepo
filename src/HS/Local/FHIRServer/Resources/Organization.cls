/// Helper for Organization Resource
Class MyFHIRServer.Resources.Organization Extends MyFHIRServer.Resources.Humanname
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
