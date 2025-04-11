Include (HS.FHIRServer, %occErrors)

/// $truncate operation - removes all resources from the dev respoitory
Class MyFHIRServer.Storage.TruncateOperation
{

/// Is $truncate available in this environment?
ClassMethod IsTruncateAllowed(throwErrorIfNotAllowed As %Boolean = 0) As %Boolean
{
    set systemMode = $system.Version.SystemMode()
    set allowed = (systemMode = "TEST") || (systemMode = "DEVELOPMENT")
    set enabled = $GET(^AllowTruncate)

    if allowed && enabled
    {
        return 1
    }

    if throwErrorIfNotAllowed
    {
        if ('allowed)
        {
            $$$ThrowFHIR($$$GeneralError, "$truncate not allowed for " _ systemMode _ " system", $$$OutcomeNotSupported(400))
        }

        $$$ThrowFHIR($$$GeneralError, "$truncate is not enabled", $$$OutcomeNotSupported(400))
    }

    return 0
}

/// @API Enumerate the name and url of each Operation supported by this class
ClassMethod AddSupportedOperations(pMap As %DynamicObject)
{
    if ..IsTruncateAllowed()
    {
    	do pMap.%Set("truncate", "http://MyFHIRServer/fhir/OperationDefinition/Truncate")
    }
}

/// System-level $truncate is the only level supported
ClassMethod FHIRSystemOpTruncate(pService As HS.FHIRServer.API.Service, pRequest As HS.FHIRServer.API.Data.Request, ByRef pResponse As HS.FHIRServer.API.Data.Response)
{
    if ..IsTruncateAllowed(1)
    {
        do ..TruncateAllresourceTables(pService.interactions)

        set pResponse.Json = ##class(HS.FHIRServer.Util.Outcome).Create("information", "All resources from this instance have been removed", "informational")
        set pResponse.Status = 200
    }
}

/// Truncate all resource tables
ClassMethod TruncateAllresourceTables(interactions As MyFHIRServer.Storage.Json.Interactions)
{
    $$$FSLog("Truncating all resource tables: ")

    #dim resourceList as %DynamicArray = ##class(MyFHIRServer.Storage.Json.InteractionsStrategy).GetResourceList()

    do ..TruncateTable(interactions.strategy.GetResourceTable(""))
    do ..TruncateTable(interactions.strategy.GetResourceVersionTable(""))

    for index = 0:1:(resourceList.%Size() - 1)
    {
        set resourceType = resourceList.%Get(index)

        do ..TruncateTable(interactions.strategy.GetSearchTable(resourceType))
    }
}

/// Truncate Table
ClassMethod TruncateTable(tableName As %String)
{
	#dim st as %SQL.Statement = ##class(%SQL.Statement).%New()
    set query = "truncate table " _ tableName
    set sc = st.%Prepare(query)

    if $$$ISERR(sc)
    {
        $$$FSLog("Prepare failed: " _ $System.Status.GetErrorText(sc))
    }
    else
    {
        #dim result as %SQL.StatementResult = st.%Execute()
        $$$FSLog(query _ ": " _ result.%Message )
    }
}

}
