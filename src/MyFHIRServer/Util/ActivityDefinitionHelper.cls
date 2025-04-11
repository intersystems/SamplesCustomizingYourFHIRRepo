/// Special logic for ActivityDefinition resource
Class MyFHIRServer.Util.ActivityDefinitionHelper Extends HS.FHIRServer.Util.FHIRQueryUtils
{

Parameter ResourceName = "ActivityDefinition";

/// Get ActivityDefinition url for Key - as used in _revinclude
/// Please note that there are 2 types of Tasks:instantiates-canonical that might match:
/// - Those with specific version in the instantiates-canonical url
/// - Those without version, as log as this ActivityDefinition is the newest (with the highest version!) 
ClassMethod GetActivityDefinitionUrlByKey(strategy As MyFHIRServer.Storage.Json.InteractionsStrategy, key As %String, Output version As %String, Output isHighestVersion As %Boolean) As %String
{
    set tSQL = "Select url, version from " _ strategy.GetSearchTable(..#ResourceName) _ " where Key=?"
    set tSQLParams = 0
    set tSQLParams($I(tSQLParams)) = key
    set result = ..runQuery(tSQL, .tSQLParams)

    if result.%Next()
    {
        set url = result.%Get("url")
        set version = result.%Get("version")
        set isHighestVersion = (..GetHighestVersion(strategy, url) = version) 

        return url
    }

    return ""
}

/// Get higestversion for the specific URL
ClassMethod GetHighestVersion(strategy As MyFHIRServer.Storage.Json.InteractionsStrategy, url As %String) As %Status
{
    set tSQLParams = 0
    set tSQL = "Select version from " _ strategy.GetSearchTable(..#ResourceName) _ " where url=? ORDER BY version DESC"
    set tSQLParams($I(tSQLParams)) = url
    set result = ..runQuery(tSQL, .tSQLParams)

    if result.%Next()
    {
        return result.%GetData(1)
    }

    return ""
}

/// Get Key for Activitydefinition Url - as used in _include
/// Please note that the url may have a version postfix!
ClassMethod GetActivityDefinitionKeyByUrl(strategy As MyFHIRServer.Storage.Json.InteractionsStrategy, url As %String) As %String
{
    set version = $PIECE(url, "|", 2)
    set url = $PIECE(url, "|", 1)
    set tSQLParams = 0
    set tSQL = "Select Key from " _ strategy.GetSearchTable(..#ResourceName) _ " where url=?"
    set tSQLParams($I(tSQLParams)) = url

    if (version '= "")
    {
        set tSQL = tSQL _ " AND version=?"
        set tSQLParams($I(tSQLParams)) = version
    }
    else
    {
        set tSQL = tSQL _ " ORDER BY version DESC"
    }

    set result = ..runQuery(tSQL, .tSQLParams)

    if result.%Next()
    {
        return result.%GetData(1)
    }
    return ""
}

/// Ensure uniqueness of Activitydefinition during create
ClassMethod EnsureUniqueness(interactions As MyFHIRServer.Storage.Json.Interactions, url As %String, version As %String)
{
	set tableName = interactions.getTableForResourceType(..#ResourceName)

    if (version = "")
    {
        set versionClause = "is null"
    }
    else
    {
        set versionClause = "= '" _ version _ "'"
    }

    #dim result As %SQL.StatementResult = ##class(HS.FHIRServer.Util.RunSQLQuery).runQuery("SELECT count(*) as aantal FROM "_ tableName _" WHERE url = '" _ url _ "' AND version " _ versionClause)

	if result.%Next()
    {
		set aantal = result.%Get("aantal")

		if (aantal > 0)
		{
            $$$ThrowFHIR($$$GeneralError, "Cannot create " _ ..#ResourceName _ " due to duplicate url + version combination" , $$$OutcomeIs(409, "error", "conflict"))
		}
	}
}

/// The (canonical) url or version has changed
/// Ensure that the update of ActivityDefinition breaks no links!!
ClassMethod EnsureUpdateisValid(interactions As MyFHIRServer.Storage.Json.Interactions, pResourceObj As %DynamicObject, oldUrl As %String, oldVersion As %String)
{
    $$$FSLog("ActivityDefinition key changed from '" _ oldUrl _ "|" _ oldVersion _ "' to '" _ pResourceObj.url _ "|" _ pResourceObj.version _ "'")

    // One of url or version has changed, the new combination must still be unique! 
    do ..EnsureUniqueness(interactions, pResourceObj.url, pResourceObj.version)

    // We must now ensure that there are no Tasks referring to this ActivityDefinition via the original url + version

    do ..EnsureNoBreakingLinks(interactions, pResourceObj.id, oldUrl, oldVersion, "update 'url' for")
}

/// Ensure that no Task resources are linked via instantiatesCanonical
ClassMethod EnsureNoBreakingLinks(interactions As MyFHIRServer.Storage.Json.Interactions, id As %String, url As %String, version As %String, reason As %String = "delete")
{
    set resourceKey = $$$BuildRsrcKey(..#ResourceName, id)

    if (version '= "") // Ensure there is no explicit link to the current version
    {
        do ##class(MyFHIRServer.Util.RefintReverseHelper).EnsureNoRecourcesForTypeAreLinked(interactions, resourceKey, "Task:instantiates-canonical", url _ "|" _ version, reason)
    }

    // If this is the only ActivityDefinition with this url, then Ensure that no Task links to this url!

    if ..IsLastWithThisUrl(interactions, id, url)
    {
        do ##class(MyFHIRServer.Util.RefintReverseHelper).EnsureNoRecourcesForTypeAreLinked(interactions, resourceKey, "Task:instantiates-canonical", url, reason)
        do ##class(MyFHIRServer.Util.RefintReverseHelper).EnsureNoRecourcesForTypeAreLinked(interactions, resourceKey, "Task:instantiates-canonical", url _ "|", reason)
    }
}

/// Is this the Last ActivityDefinition with this url?
ClassMethod IsLastWithThisUrl(interactions As MyFHIRServer.Storage.Json.Interactions, id As %String, url As %String) As %Boolean
{
    set tSQLParams = 0
    set tSQL = "Select count(*) as aantal from " _ interactions.getTableForResourceType(..#ResourceName) _ " where url = ? AND _id <> ?"
    set tSQLParams($I(tSQLParams)) = url
    set tSQLParams($I(tSQLParams)) = id

    set result = ..runQuery(tSQL, .tSQLParams)

    if result.%Next()
    {
		set aantal = result.%Get("aantal")

		return (aantal = 0)
    }

    return 1 // Should never occur
}

}
