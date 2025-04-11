Include HS.FHIRServer

/// Check references for a resource about to te deleted
Class MyFHIRServer.Util.RefintReverseHelper
{

/// Ensure that no resources are linked to this resourse before delete
ClassMethod EnsureNoLinksBeforeDelete(interactions As MyFHIRServer.Storage.Json.Interactions, fromResourceType As %String, id As %String)
{
    set fromResourceKey = $$$BuildRsrcKey(fromResourceType, id)
    set resourceTable = interactions.strategy.GetResourceTable(fromResourceType)
    set query = "SELECT count(*) as countLinked FROM " _ resourceTable _ " WHERE FOR SOME %ELEMENT(ResourceReferences) (%VALUE = ?)"
    set tSQLParams = 0
    set tSQLParams($INCREMENT(tSQLParams)) = fromResourceKey

	#dim result As %SQL.StatementResult = ##class(HS.FHIRServer.Util.RunSQLQuery).runQuery(query, .tSQLParams)

	if result.%Next()
    {
		set count = result.%Get("countLinked")

		if (count > 0)
		{
	        $$$ThrowFHIR($$$GeneralError, "Cannot delete " _ fromResourceKey _ ": Found " _ count _ " linked resources", $$$OutcomeIs(409, "error", "conflict"))
		}
	}
}

/// Ensure that no resources of the specified type are linked via the specified column
ClassMethod EnsureNoRecourcesForTypeAreLinked(interactions As MyFHIRServer.Storage.Json.Interactions, fromResourceKey As %String, referencePath As %String, value As %String, reason As %String = "delete")
{
    set fromClause = ..GetFromClauseForReferencePath(interactions, referencePath, value, .targetResourceType, .targetColumn)
	#dim result As %SQL.StatementResult = ##class(HS.FHIRServer.Util.RunSQLQuery).runQuery("SELECT count(*) as countLinked" _ fromClause)

	if result.%Next()
    {
		set count = result.%Get("countLinked")

		if (count > 0)
		{
	        $$$ThrowFHIR($$$GeneralError, "Cannot " _ reason _ " " _ fromResourceKey _ ": First found " _ count _ " linked resources of type " _ targetResourceType _ " with " _ targetColumn _ "=" _ value, $$$OutcomeIs(409, "error", "conflict"))
		}
	}
}

/// Find dependent resources for cascade-delete
ClassMethod FindDependentResourcesForCascadeDelete(interactions As MyFHIRServer.Storage.Json.Interactions, fromResourceType As %String, id As %String) As %DynamicArray
{
    set dependentResources = []

    do ..AddDependentResourcesForCascadeDelete(interactions, fromResourceType, id, dependentResources)

    return dependentResources
}

/// Add dependent resources for cascade-delete in the context of a single Patient.
ClassMethod AddDependentResourcesForCascadeDelete(interactions As MyFHIRServer.Storage.Json.Interactions, fromResourceType As %String, id As %String, dependentResources As %DynamicArray)
{
    set fromResourceKey = $$$BuildRsrcKey(fromResourceType, id)
    set resourceTable = interactions.strategy.GetResourceTable(fromResourceType)
    set tSQLParams = 0
    set tSQLParams($INCREMENT(tSQLParams)) = fromResourceKey

    $$$FSLog("Adding dependent resources for " _ fromResourceKey _ ":")

	#dim result As %SQL.StatementResult = ##class(HS.FHIRServer.Util.RunSQLQuery).runQuery("SELECT Key FROM " _ resourceTable _ " WHERE FOR SOME %ELEMENT(ResourceReferences) (%VALUE = ?)", .tSQLParams)

	while result.%Next()
    {
        set key = result.%Get("Key")
        set targetResourceType = $PIECE(key, "/", 1)
        set id =  $PIECE(key, "/", 2)

        if ('..FindKey(dependentResources, targetResourceType, id))
        {
            // Now check for nested depending resources
            do ..AddDependentResourcesForCascadeDelete(interactions, targetResourceType, id, dependentResources)

            // Finally add resource!
            do dependentResources.%Push( { "resourceType": (targetResourceType), "id": (id) } )
        }
	}
}

/// has this resource already been added?
ClassMethod FindKey(dependentResources As %DynamicArray, targetResourceType As %String, id As %String) As %Boolean
{
    for index = 0:1:(dependentResources.%Size() - 1)
    {
        set dependentResource = dependentResources.%Get(index)

        if (dependentResource.resourceType = targetResourceType) && (dependentResource.id = id)
        {
            return 1
        }
    }

    return 0
}

/// Get TableName and SearchColumn for ReferencePath
ClassMethod GetFromClauseForReferencePath(interactions As MyFHIRServer.Storage.Json.Interactions, referencePath As %String, value As %String, Output targetResourceType As %String, Output columnName As %String) As %String
{
    set targetResourceType = $PIECE(referencePath, ":", 1)
    set columnName = $PIECE(referencePath, ":", 2)

    if columnName = ""
    {
        $$$ThrowFHIR($$$GeneralError, "Invalid referencePath '" _ referencePath _ "' in lookup table ReverseReferences; ':' missing?", $$$OutcomeIs(500, "error", "exception"))
    }

    #dim searchColumn As HS.FHIRServer.Storage.Json.SearchColumn = interactions.getSearchColumn(targetResourceType, columnName)

    if searchColumn = "" // Not found
    {
        $$$ThrowFHIR($$$GeneralError, "Found non-existing search Column '" _ columnName _ "' in lookup table ReverseReferences", $$$OutcomeIs(500, "error", "exception"))
    }

	set tableName = interactions.getTableForResourceType(targetResourceType)

    if searchColumn.isMultiValue
    {
        return " FROM "_ tableName _" WHERE FOR SOME %ELEMENT("_searchColumn.ColumnName _") (%VALUE = '" _ value _ "')"
    }

    return " FROM "_ tableName _" WHERE " _ searchColumn.ColumnName _ " = '" _ value _ "'"
}

}
