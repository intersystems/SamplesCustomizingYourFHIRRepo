/// Locally defined Operations
Class MyFHIRServer.Storage.BuiltInOperations Extends (HS.FHIRServer.Storage.BuiltInOperations, MyFHIRServer.Storage.ExpungeOperation, MyFHIRServer.Storage.TruncateOperation)
{

/// @API Enumerate the name and url of each Operation supported by this class
ClassMethod AddSupportedOperations(pMap As %DynamicObject)
{
	do ##class(HS.FHIRServer.Storage.BuiltIn.Validate).AddSupportedOperations(pMap)
	do ##class(MyFHIRServer.Storage.ExpungeOperation).AddSupportedOperations(pMap)
	do ##class(MyFHIRServer.Storage.TruncateOperation).AddSupportedOperations(pMap)
}

}
