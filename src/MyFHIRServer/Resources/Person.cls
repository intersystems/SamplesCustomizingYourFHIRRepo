/// Helper for Patient and Resource
Class MyFHIRServer.Resources.Person Extends MyFHIRServer.Resources.Humanname
{

/// Generate Text
ClassMethod GenerateText(resource As %DynamicObject) As %String
{
    return resource.resourceType _ " named " _ ..FindAndFormatFullName(resource.name) _ " born at " _ resource.birthDate _ " with gender " _ resource.gender
}

/// GetDisplayForReference
ClassMethod GetDisplayForReference(resource As %DynamicObject) As %String
{
    return ..FindAndFormatFullName(resource.name)
}

}
