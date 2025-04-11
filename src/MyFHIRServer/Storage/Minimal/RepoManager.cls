/// RepoManager override
Class MyFHIRServer.Storage.Minimal.RepoManager Extends HS.FHIRServer.Storage.Json.RepoManager
{

Parameter StrategyClass As STRING = "MyFHIRServer.Storage.Minimal.InteractionsStrategy";

Parameter StrategyKey As STRING = "Minimal";

}
