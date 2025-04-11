/// Helper for Organization Resource
Class MyFHIRServer.Resources.Task
{

/// Generate Text
ClassMethod GenerateText(resource As %DynamicObject) As %String
{
    return resource.resourceType _ " with description '" _ resource.description _ "' for Patient named " _ resource.for.display
}

/// GetDisplayForReference
ClassMethod GetDisplayForReference(resource As %DynamicObject) As %String
{
    return resource.description
}

}
