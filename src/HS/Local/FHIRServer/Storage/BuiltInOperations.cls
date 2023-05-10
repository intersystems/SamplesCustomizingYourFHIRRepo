/// Locally defined Operations
Class HS.Local.FHIRServer.Storage.BuiltInOperations Extends (HS.FHIRServer.Storage.BuiltInOperations, HS.Local.FHIRServer.Storage.ExpungeOperation)
{

/// @API Enumerate the name and url of each Operation supported by this class
ClassMethod AddSupportedOperations(pMap As %DynamicObject)
{
	Do ##class(HS.FHIRServer.Storage.BuiltIn.Validate).AddSupportedOperations(pMap)
	Do ##class(HS.Local.FHIRServer.Storage.ExpungeOperation).AddSupportedOperations(pMap)
}

}
