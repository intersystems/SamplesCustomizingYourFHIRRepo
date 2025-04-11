Include HS.FHIRServer

/// FHIR Interactions handler
Class MyFHIRServer.Storage.Json.Interactions Extends (HS.FHIRServer.Storage.Json.Interactions, MyFHIRServer.Util.IdentifierHelper)
{

Parameter OperationHandlerClass = "MyFHIRServer.Storage.BuiltInOperations";

Parameter BatchHandlerClass As STRING = "HS.FHIRServer.Storage.Json.BundleProcessor";

Parameter ResourceValidatorClass As STRING = "MyFHIRServer.Util.ResourceValidator";

Parameter OAuth2TokenHandlerClass As STRING = "HS.FHIRServer.Util.OAuth2Token";

Property strategy As MyFHIRServer.Storage.Json.InteractionsStrategy;

/// Handle create interaction
Method Add(pResourceObj As %DynamicObject, pResourceIdToAssign As %String = "", pHttpMethod As %String = "POST") As %String
{
	$$$FSLog("Add resource type: "_pResourceObj.resourceType_", HTTP method: " _ pHttpMethod)

	set pResourceIdToAssign = $ZCONVERT($System.Util.CreateGUID(), "L")

	do ##class(MyFHIRServer.Util.RefIntHelper).ValidateReferences(pResourceObj, ..strategy)

	if $ISOBJECT(pResourceObj.identifier)
	{
		// Check for identifier uniqueness
		do ..EnsureUniqueIdentifiersBeforeWrite($THIS, pResourceObj)
	}

	set id = ##super(pResourceObj, pResourceIdToAssign, pHttpMethod)

	do ..PostProcessResource(pResourceObj, 1)
	
	return id
}

/// Handle Update interaction
Method Update(pResourceObj As %DynamicObject) As %String
{
	$$$FSLog("Update resource type: "_ pResourceObj.resourceType _ " with id " _ pResourceObj.id)
	
	do ##class(MyFHIRServer.Util.RefIntHelper).ValidateReferences(pResourceObj, ..strategy)

	if $ISOBJECT(pResourceObj.identifier)
	{
		// Check for identifier uniqueness
		do ..EnsureUniqueIdentifiersBeforeWrite($THIS, pResourceObj)
	}
	
	set id = ##super(pResourceObj)

	do ..PostProcessResource(pResourceObj, 1)

	return id
}

/// Read interaction handler, orders the properties!
Method Read(pResourceType As %String, pResourceId As %String, pVersionId As %String = "") As %DynamicObject
{
	return ..PostProcessResource(##super(pResourceType, pResourceId, pVersionId))
}

/// Process resource before return
Method PostProcessResource(resource As %DynamicObject, modifyOriginalObject As %Boolean = 0) As %DynamicObject
{
	do ..SetDisplayFor4References(resource)
	do ..AddOrUpdateText(resource)

	return ##class(MyFHIRServer.Util.ResourceProperties).FHIROrderResourceProperties(resource, modifyOriginalObject)
}

/// Add or update Text
Method AddOrUpdateText(resource As %DynamicObject)
{
	if (resource.text = "") || (resource.text.status = "generated")
	{
		try
		{
			set text = $CLASSMETHOD("MyFHIRServer.Resources." _ resource.resourceType, "GenerateText", resource)
			set resource.text = {
				"status": "generated",
				"div": ("<div xmlns=""http://www.w3.org/1999/xhtml""><p><b>Generated</b></p>" _  text _ "</div>")
			}
		}
		catch ex
		{
			$$$FSLog("Failed to get text for " _ resource.resourceType _ "/" _ resource.id _ ": " _ $system.Status.GetErrorText(ex.AsStatus()))
		}
	}
}

/// Set display for references
Method SetDisplayFor4References(resource As %DynamicObject)
{
	set visitContext("schema") = ..strategy.schema
	set visitContext("callbackInstance") = $THIS
	set visitContext("callbackMethod") = "AddDisplayForReference"

	do ##class(HS.FHIRServer.Util.ReferenceVisitor).VisitAll(resource, .visitContext)
}

/// Add display for a single reference
Method AddDisplayForReference(ByRef context, reference As %DynamicObject)
{
	#; set propName = context("_va", "curPropName")
	set resourceType = $PIECE(reference.reference, "/", 1)

	try
	{
		set resourceClass = ..strategy.GetResourceClass(resourceType)
		set reference.display = "(not-found)"

		if $classmethod(resourceClass, "KeyIdxExists", reference.reference) // resource exists?
		{
			set storageObject = $classmethod(resourceClass, "KeyIdxOpen", reference.reference, -1, .tSC)

			if (storageObject.Deleted = 0) // Not deleted
			{
				set reference.display = $CLASSMETHOD("MyFHIRServer.Resources." _ resourceType, "GetDisplayForReference", storageObject.ResourceObject)
			}
		}
	}
	catch ex
	{
		$$$FSLog("Failed to get display for " _ reference.reference _ ": " _ $system.Status.GetErrorText(ex.AsStatus()))
	}
}

/// Check referential integrity before delete
Method Delete(pResourceType As %String, pResourceId As %String) As %String
{
	do ..CheckDelete(pResourceType, pResourceId)

	return ##super(pResourceType, pResourceId)
}

/// Check if the caller is allowed to delete the specified resource
Method CheckDelete(pResourceType As %String, pResourceId As %String) As %Boolean
{
	set exists = ..GetResourceFromDB(pResourceType, pResourceId, , .url, .version)

	if exists
	{
		if (pResourceType = "ActivityDefinition")
		{
			do ##class(MyFHIRServer.Util.ActivityDefinitionHelper).EnsureNoBreakingLinks($THIS, pResourceId, url, version)
		}
		else
		{
			do ##class(MyFHIRServer.Util.RefintReverseHelper).EnsureNoLinksBeforeDelete($THIS, pResourceType, pResourceId)
		}

		$$$FSLog("It is allowed to delete resource " _ $$$BuildRsrcKey(pResourceType, pResourceId) _ "!")
	}

	return exists
}

/// Get the ResourceOrigin from the stored resource using the resource type and id
Method GetResourceFromDB(resourceType As %String, id As %String, Output versionId As %String, Output url As %String, Output version As %String, Output patient As %String) As %Boolean
{
	set versionId = ""
	set url = ""
	set version = ""
	set patient = ""
	set tableName = ..getTableForResourceType(resourceType)
	
	set query = "SELECT VersionId"

	if (resourceType = "ActivityDefinition")
	{
		set query = query _ ", url, version"
	}
	elseif (resourceType = "Task")
	{
		set query = query _ ", patient"
	}

	set query = query _ " FROM "_tableName_" WHERE _id = '" _ id _ "'"

	#dim result As %SQL.StatementResult = ##class(HS.FHIRServer.Util.RunSQLQuery).runQuery(query)

	if result.%Next()
	{
		set versionId = result.%Get("VersionId")

		if (resourceType = "ActivityDefinition")
		{
			set url = result.%Get("url")
			set version = result.%Get("version")
		}
		elseif (resourceType = "Task")
		{
			set patient = result.%Get("patient")
		}

		return 1 // record found
	}
	
	return 0 // record not found
}

}
