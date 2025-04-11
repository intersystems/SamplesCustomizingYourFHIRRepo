Include (HS.FHIRServer, %occErrors)

/// $expunge operation
Class MyFHIRServer.Storage.ExpungeOperation
{

/// @API Enumerate the name and url of each Operation supported by this class
ClassMethod AddSupportedOperations(pMap As %DynamicObject)
{
	do pMap.%Set("expunge", "http://MyFHIRServer/fhir/OperationDefinition/Expunge")
}

/// Type-level $Expunge operation is not supported
ClassMethod FHIRTypeOpExpunge(pService As HS.FHIRServer.API.Service, pRequest As HS.FHIRServer.API.Data.Request, ByRef pResponse As HS.FHIRServer.API.Data.Response)
{
    $$$ThrowFHIR($$$GeneralError, pRequest.OperationName _ " is not allowed at type level, only at instance level", $$$OutcomeNotSupported(405))
}

/// Implementatton of instance-level $Expunge (see https://smilecdr.com/docs/fhir_repository/deleting_data.html#expunge)
/// Primary purpose is implementation of the "right to be forgotten" as per the GDPR, which applies to Patients
/// For that, $expunge supports the option to cascadeDelete, which means that CareTeam and Task resources for the Patient are also deleted
/// In the MyFHIRServer context, we only allow intance level Expunge, so syntax is:
/// POST [base]/Patient/123/$expunge
/// Content-Type: application/fhir+json
/// {
///     "resourceType": "Parameters",
///     "parameter": [
///         {
///            "name": "cascadeDelete",
///             "valueBoolean": true
///         },
///         {
///            "name": "reportOnly",
///             "valueBoolean": false
///         }
///     ]
/// }
/// This will Delete a Patient with all dependent Task & CareTeam resources completely, including all previous versions - assuming the user is authorized to do so!
ClassMethod FHIRInstanceOpExpunge(pService As HS.FHIRServer.API.Service, pRequest As HS.FHIRServer.API.Data.Request, ByRef pResponse As HS.FHIRServer.API.Data.Response)
{
    if (pRequest.VId '= "")
    {
        $$$ThrowFHIR($$$GeneralError, pRequest.OperationName _ " is not  allowed at history level, only at instance level", $$$OutcomeNotSupported(405))
    }

	#dim payload As %DynamicObject = pRequest.Json

	if (payload = "") // empty payload uses defaults
    {
        set payload = { "parameter": [ ] }
    }
    elseif payload.resourceType '= "Parameters"
	{
		$$$ThrowFHIR($$$GeneralError, "Resource type for operation " _ pRequest.OperationName _ " must be 'Parameters'", $$$OutcomeInvalid(400))
    }

	set operationOutcome = { "resourceType": "OperationOutcome" }
    #dim issues as %DynamicArray = []
	Set operationOutcome.issue = issues

	set params = ..GetExpungeParameters(payload.parameter, issues)

    if ("|Patient|Task|" '[ ("|" _ pRequest.Type _ "|")) && params.cascadeDelete
    {
        $$$ThrowFHIR($$$GeneralError, pRequest.OperationName _ " with cascadeDelete is only allowed for Patient or Task", $$$OutcomeNotSupported(405))
    }

    $$$FSLog("Using parameters=" _ params.%ToJSON())

    do ..ExpungeResourceInstance(pService.interactions, pRequest.Type, pRequest.Id, params, issues)

 	set pResponse.Json = operationOutcome
	set pResponse.Status = 200
}

/// Now Expunge!
/// If no links found / left and false, then delete / report individual record!
/// If  cascadeDelete is true, and the user is allowed to deleta all dependent CareTeams and Tasks, then these are also deleted / reported
/// Given that the use of Expunge is exceptional, we do expect that there are no new resources being created for the Patient being expunged!
/// Please note we need to iterate through dependent resources, these may be again have dependent resources (CareTeam <-Task; Task <- Task)
ClassMethod ExpungeResourceInstance(interactions As MyFHIRServer.Storage.Json.Interactions, resourceType As %String, id As %String, params As %DynamicObject, issues As %DynamicArray)
{
    $$$FSLog("Operation called for " _ $$$BuildRsrcKey(resourceType, id))

    if params.cascadeDelete
    {
        // Resource exists; find all dependent resources and check authorization 

        #dim dependentResources as %DynamicArray = ##class(MyFHIRServer.Util.RefintReverseHelper).FindDependentResourcesForCascadeDelete(interactions, resourceType, id)

        if (dependentResources.%Size() > 0)
        {
            set message = ..DeleteDependentResources(interactions, dependentResources, params.reportOnly)

            do ..LogInformational(issues, message)
        }
    }

    if params.reportOnly
    {
        set message = "With reportOnly=false, would have d"
    }
    else
    {
        do interactions.HardDelete(resourceType, id, "*")
        set message = "D"
    }

    do ..LogInformational(issues, message _ "eleted all versions for " _ $$$BuildRsrcKey(resourceType, id))
}

/// Log message and add Informational issue
ClassMethod LogInformational(issues As %DynamicArray, message As %String)
{
    $$$FSLog(message)

    do issues.%Push({
        "severity": "information",
        "code": "informational",
        "diagnostics": (message)
    })
}

/// Delete dependent resources
ClassMethod DeleteDependentResources(interactions As MyFHIRServer.Storage.Json.Interactions, dependentResources As %DynamicArray, reportOnly As %Boolean) As %String
{
    if reportOnly
    {
        set message = "With reportOnly=false, would have d" 
    }
    else
    {
        set message = "D"
    }

    set message = message _ "eleted all versions for " _ dependentResources.%Size() _ " dependent resources: "

    for index = 0:1:(dependentResources.%Size() - 1)
    {
        set dependentResource = dependentResources.%Get(index)

        if 'reportOnly
        {
            do interactions.HardDelete(dependentResource.resourceType, dependentResource.id, "*")
        }

        set message = message _ $$$BuildRsrcKey(dependentResource.resourceType, dependentResource.id) _ ", "
    }

    return $EXTRACT(message, 1, *-2)
}

/// Get the supported parameters
ClassMethod GetExpungeParameters(parameters As %DynamicArray, issues As %DynamicArray) As %DynamicObject
{
    #dim params as %DynamicObject = {       // defaults
        // "limit": -1,                     // This parameter is intended to specify the maximum number of entries (resource versions and/or resources) that will be deleted in a single batch before exiting, but not implemented
        // "expungeDeletedResources": false,// This parameter is intended to also expunge deleted resources (including all previous versions of the resource) - Not meaningfull for instance-level operation so ignored
        // "expungePreviousVersions": false,// This parameter is intended to also expunge non-current versions of the resource - Not meaningfull for GDPR so ignored
        // "expungeEverything": true,       // Expunge current version of the resource and all previous versions, Only meaningfull option for GDPR so ignored
        "cascadeDelete": false,             // This allows requesting deleting a Patient with all dependent Task and CareTeam resources. Default = true
        "reportOnly": true                  // ReportOnly creates a report of all resources that would be deleted, without actually deleting. Default = true
    }
    #dim iter as %Iterator.Array = parameters.%GetIterator()

    while iter.%GetNext(.subsc, .entry, .type)
    {
        if (params.%IsDefined(entry.name)) // Supported parameter?
        {
            do params.%Set(entry.name, entry.valueBoolean, "boolean")
        }
        else
        {
            do ..LogUnsupportedParameter(entry.name, issues)
        }
    }

    return params
}

/// Log Unuspported parameter
ClassMethod LogUnusedParameter(name As %String, issues As %DynamicArray)
{
    set message = "Parameter '" _ name _ "' is not implemented"
    $$$FSLog(message)

    do issues.%Push({
        "severity": "information",
        "code": "unsupported",
        "details": {
            "text": (message)
        },
        "diagnostics": (message)
    })
}

/// Log Unuspported parameter
ClassMethod LogUnsupportedParameter(name As %String, issues As %DynamicArray)
{
    set message = "Unsupported parameter '" _ name _ "'"
    $$$FSLog(message)

    do issues.%Push({
        "severity": "warning",
        "code": "unsupported",
        "details": {
            "coding": [
                {
                    "system": "http://terminology.hl7.org/CodeSystem/operation-outcome",
                    "code": "MSG_PARAM_UNKNOWN"
                }
            ]
        },
        "diagnostics": (message)
    })
}

}
