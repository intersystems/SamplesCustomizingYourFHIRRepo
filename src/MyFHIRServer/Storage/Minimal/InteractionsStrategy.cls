/// Interactions strategy
Class MyFHIRServer.Storage.Minimal.InteractionsStrategy Extends HS.FHIRServer.Storage.Json.InteractionsStrategy
{

Parameter StrategyKey As STRING = "Minimal";

Parameter InteractionsClass As STRING = "MyFHIRServer.Storage.Minimal.Interactions";

Parameter ResourceSuperclass As STRING = "MyFHIRServer.Storage.Minimal.Resource";

Parameter ResourceVersionSuperclass As STRING = "MyFHIRServer.Storage.Minimal.ResourceVer";

}
