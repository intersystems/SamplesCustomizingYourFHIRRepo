Include HS.FHIRServer

/// Check for Uniqueness of Identifiers
Class MyFHIRServer.Util.IdentifierHelper
{

/// Make sure that each of the identifiers in the object are unique!
ClassMethod EnsureUniqueIdentifiersBeforeWrite(interactions As HS.Local.FHIRServer.Storage.Json.Interactions, resource As %DynamicObject)
{
    set searchTable = interactions.getTableForResourceType(resource.resourceType)
    
    for index = 0:1:resource.identifier.%Size() - 1
    {
        set identifier = resource.identifier.%Get(index)

        do ..ValidateIdentifier(searchTable, resource.id, identifier, "identifier[" _ index _ "]")
    }
}

/// Make sure this identifier is unique!
ClassMethod ValidateIdentifier(searchTable As %String, id As %String, identifier As %DynamicObject, location As %String)
{
    set query = "SELECT _id as resourceId FROM "_searchTable_" WHERE FOR SOME %ELEMENT(identifier) (%VALUE = '"_identifier.system _ "|" _ identifier.value _ "') and _id <> '" _ id _ "'"

    #dim rset as %SQL.StatementResult = ##Class(HS.FHIRServer.Util.RunSQLQuery).runQuery(query)

    if (rset.%Next())
    {
        set error = "Identifier with system='" _ identifier.system _ "' and value='" _ identifier.value _ "' already used by resource with id='" _ rset.%Get("resourceId") _ "'"
        $$$ThrowFHIR($$$GeneralError, error, $$$OutcomeIs(422,"error", "duplicate"))
    }
}

}
