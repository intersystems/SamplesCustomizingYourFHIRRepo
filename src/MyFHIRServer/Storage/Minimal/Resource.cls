/// Override for Resource SuperClass
Class MyFHIRServer.Storage.Minimal.Resource Extends HS.FHIRServer.Storage.Json.Resource
{

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
</Data>
<DataLocation>^HS.Local.FHIRServEBEC.ResourceD</DataLocation>
<DefaultData>ResourceDefaultData</DefaultData>
<IdLocation>^HS.Local.FHIRServEBEC.ResourceD</IdLocation>
<IndexLocation>^HS.Local.FHIRServEBEC.ResourceI</IndexLocation>
<StreamLocation>^HS.Local.FHIRServEBEC.ResourceS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
