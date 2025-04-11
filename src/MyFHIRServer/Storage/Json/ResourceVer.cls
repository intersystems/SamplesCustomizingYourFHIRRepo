/// Override for ResourceVersion SuperClass
Class MyFHIRServer.Storage.Json.ResourceVer Extends HS.FHIRServer.Storage.Json.ResourceVer
{

Storage Default
{
<Data name="ResourceVerDefaultData">
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
<Value>LastModified</Value>
</Value>
<Value name="7">
<Value>Verb</Value>
</Value>
<Value name="8">
<Value>Format</Value>
</Value>
<Value name="9">
<Value>Deleted</Value>
</Value>
<Value name="10">
<Value>ResourceStream</Value>
</Value>
<Value name="11">
<Value>ResourceString</Value>
</Value>
</Data>
<DataLocation>^HS.Local.FHIRSEC11.ResourceVerD</DataLocation>
<DefaultData>ResourceVerDefaultData</DefaultData>
<IdLocation>^HS.Local.FHIRSEC11.ResourceVerD</IdLocation>
<IndexLocation>^HS.Local.FHIRSEC11.ResourceVerI</IndexLocation>
<StreamLocation>^HS.Local.FHIRSEC11.ResourceVerS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
