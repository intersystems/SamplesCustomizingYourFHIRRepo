/// Locally defined Operations
Class HS.Local.FHIRServer.Storage.BuiltInOperations Extends (HS.FHIRServer.Storage.BuiltInOperations, HS.Local.FHIRServer.Storage.ExpungeOperation, HS.Local.FHIRServer.Storage.TruncateOperation)
{

/// @API Enumerate the name and url of each Operation supported by this class
ClassMethod AddSupportedOperations(pMap As %DynamicObject)
{
	do ##class(HS.FHIRServer.Storage.BuiltIn.Validate).AddSupportedOperations(pMap)
	do ##class(HS.Local.FHIRServer.Storage.ExpungeOperation).AddSupportedOperations(pMap)
	do ##class(HS.Local.FHIRServer.Storage.TruncateOperation).AddSupportedOperations(pMap)
}

}
