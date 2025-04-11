/// Override for Resource SuperClass
/// This adds a ResourceReferences property where we will store all used references
Class HS.Local.FHIRServer.Storage.Json.Resource Extends HS.FHIRServer.Storage.Json.Resource
{

/// All references to other resources
Property ResourceReferences As list Of %String(MAXLEN = "");

/// Index on references
Index ReferencesIdx On ResourceReferences(ELEMENTS);

/// Make sure that the ResourceReferences are all updated
Method %OnAddToSaveSet(depth As %Integer, insert As %Integer, callcount As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
    if (callcount = 1)
    {
        do ..ResourceReferences.Clear()

        if ('..Deleted)
        {
            set visitContext("schema") = ##class(HS.FHIRServer.Schema).LoadSchema("R4") 
            set visitContext("callbackInstance") = $THIS
            set visitContext("callbackMethod") = "AddReference"

            do ##class(HS.FHIRServer.Util.ReferenceVisitor).VisitAll(..ResourceObject, .visitContext)
        }

        return ..%AddToSaveSet(1, 1)
    }

    return $$$OK
}

/// Add reference - if not already there
Method AddReference(ByRef context, reference As %DynamicObject)
{
    for index = 1:1:..ResourceReferences.Count()
    {
        if reference.reference = ..ResourceReferences.GetAt(index)
        {
            return
        }
    }

    do ..ResourceReferences.Insert(reference.reference)
}

Storage Default
{
<Data name="ResourceDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Key</Value>
</Value>
<Value name="3">
<Value>ResourceType</Value>
</Value>
<Value name="4">
<Value>ResourceId</Value>
</Value>
<Value name="5">
<Value>VersionId</Value>
</Value>
<Value name="6">
<Value>ServiceId</Value>
</Value>
<Value name="7">
<Value>LastModified</Value>
</Value>
<Value name="8">
<Value>Verb</Value>
</Value>
<Value name="9">
<Value>Format</Value>
</Value>
<Value name="10">
<Value>Deleted</Value>
</Value>
<Value name="11">
<Value>ResourceStream</Value>
</Value>
<Value name="12">
<Value>ResourceString</Value>
</Value>
<Value name="13">
<Value>Compartments</Value>
</Value>
<Value name="14">
<Value>ResourceReferences</Value>
</Value>
</Data>
<DataLocation>^HS.Local.FHIRServEC11.ResourceD</DataLocation>
<DefaultData>ResourceDefaultData</DefaultData>
<IdLocation>^HS.Local.FHIRServEC11.ResourceD</IdLocation>
<IndexLocation>^HS.Local.FHIRServEC11.ResourceI</IndexLocation>
<StreamLocation>^HS.Local.FHIRServEC11.ResourceS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
