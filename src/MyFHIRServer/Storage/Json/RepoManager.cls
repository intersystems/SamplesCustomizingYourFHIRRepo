/// RepoManager override
Class MyFHIRServer.Storage.Json.RepoManager Extends HS.FHIRServer.Storage.Json.RepoManager
{

Parameter StrategyClass As STRING = "MyFHIRServer.Storage.Json.InteractionsStrategy";

Parameter StrategyKey As STRING = "MyJson";

}
