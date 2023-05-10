/// Interactions strategy
Class HS.Local.FHIRServer.Storage.Minimal.InteractionsStrategy Extends HS.FHIRServer.Storage.Json.InteractionsStrategy
{

Parameter StrategyKey As %String = "Minimal";

Parameter InteractionsClass As %String = "HS.Local.FHIRServer.Storage.Minimal.Interactions";

Parameter ResourceSuperclass As %String = "HS.Local.FHIRServer.Storage.Minimal.Resource";

Parameter ResourceVersionSuperclass As %String = "HS.Local.FHIRServer.Storage.Minimal.ResourceVer";

}
