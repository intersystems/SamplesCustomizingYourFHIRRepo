Include (HS.FHIRServer, Ensemble)

/// Referential Integrity Helper
Class MyFHIRServer.Util.RefIntHelper Extends HS.FHIRServer.Util.ReferenceVisitor
{

/// Validate references for the resource
ClassMethod ValidateReferences(resource As %DynamicObject, strategy As MyFHIRServer.Storage.Json.InteractionsStrategy)
{
	set context("strategy") = strategy // Used to check whether a resource exists
	set context("schema") = strategy.schema
	set context("callbackClass") = $CLASSNAME()
	set context("callbackMethod") = "ValidateReference"
	set context("path") = resource.resourceType

	do ..VisitAll(resource, .context)
}

/// Add References from Object
/// Replaces method in HS.FHIRServer.Util.ReferenceVisitor
ClassMethod AddReferencesFromObject(pObj As %DynamicObject, pFHIRType As %String, ByRef context) [ Private ]
{
	#dim meta as HS.FHIRMeta.API = context("schema")
	#dim iter as %Iterator.Object = pObj.%GetIterator()
    set start = $GET(context("path"))

	while iter.%GetNext(.propName, .propValue)
    {
    	set context("path") = start _ "." _ propName

		set fhirType = meta.GetPropertyFHIRType(pFHIRType, propName)

		if (meta.GetPropertyJSONType(pFHIRType, propName) '= "o") && (fhirType '= "canonical")
        {
            continue
        }
		
		if meta.IsPropertyArray(pFHIRType, propName)
        {
            for index = 1:1:propValue.%Size()
            {
                do ..AddReferenceObj(propValue.%Get(index - 1), propName, fhirType, .context)
			}			
		}
        else
        {
            do ..AddReferenceObj(propValue, propName, fhirType, .context)
		}
	}
}

/// Add Reference
/// Replaces method in HS.FHIRServer.Util.ReferenceVisitor
ClassMethod AddReferenceObj(obj As %DynamicObject, propName As %String, fhirType As %String, ByRef context)
{
    if (fhirType = "canonical")
    {
        set obj = { "reference": (obj) }
    }

    if (fhirType = "Reference") || (fhirType = "canonical")
    {
        set context("_va", "curPropName") = propName
        set context("_va", "curFHIRType") = fhirType

        if $D(context("callbackInstance")) = 1
        {
            do $Method(context("callbackInstance"), context("callbackMethod"), .context, obj)
        }
        elseif $D(context("callbackClass")) = 1 
        {
            do $ClassMethod(context("callbackClass"), context("callbackMethod"), .context, obj)
        }

        kill context("_va", "curFHIRType")
        kill context("_va", "curPropName")

        if (obj.reference '= "")
        {
            do ..AddBackReference(.context, obj.reference, context("_va", "curId"), context("_va", "curIdIsShared"))
        }
    }
    else
    {
        do ..AddReferencesFromObject(obj, fhirType, .context)
    }
}

/// Validate a single Reference
ClassMethod ValidateReference(ByRef context, reference As %DynamicObject)
{
    set propName = context("_va", "curPropName")

    if reference.reference '= "" // Check canonical, conditional or literal reference
    {
        if (context("_va", "curFHIRType") = "canonical")
        {
            if propName = "profile" // ignore profile reference
            {
                return
            }

            do ..ValidateReferenceValue(context("strategy"), "canonical", "ActivityDefinition", "url", reference.reference, context("path"))
        }
        elseif (reference.reference [ "?") // conditional reference: Patient?identifier=system|value
        {
            set identifier = $PIECE(reference.reference, "=", 2)
            set reference.reference = ..ValidateIdentifierValue(context("strategy"), "conditional", $PIECE(reference.reference, "?", 1), $PIECE(identifier, "|", 1), $PIECE(identifier, "|", 2), context("path"))
        }
        else
        {
            do ..ValidateReferenceValue(context("strategy"), "literal", $PIECE(reference.reference, "/", 1), "Key", reference.reference, context("path"))
        }
    }
    elseif $ISOBJECT(reference.identifier) // Logical reference
    {
        set reference.reference = ..ValidateIdentifierValue(context("strategy"), "logical", reference.type, reference.identifier.system, reference.identifier.value, context("path"))
    }
}

/// Check if the  resource with the specified identifier exists
ClassMethod ValidateIdentifierValue(strategy As MyFHIRServer.Storage.Json.InteractionsStrategy, referenceType As %String, targetResourceType As %String, system As %String, value As %String, location As %String) As %String
{
    if (targetResourceType = "") // Can't check without type
    {
        $$$ThrowFHIR($$$GeneralError, "No type specified for " _ referenceType _ " reference " _ location _ " with system '" _ system _ "' and value '" _ value _ "'", $$$OutcomeIs(422, "error", "invalid"))
    }

    set query = "SELECT _id as resourceId FROM "_ strategy.GetSearchTable(targetResourceType) _ " WHERE FOR SOME %ELEMENT(identifier) (%VALUE = '"_system _ "|" _ value _ "')"

    #dim rset as %SQL.StatementResult = ##Class(HS.FHIRServer.Util.RunSQLQuery).runQuery(query)

    if (rset.%Next())
    {
        return targetResourceType _ "/" _ rset.%Get("resourceId")
    }

    $$$ThrowFHIR($$$GeneralError, referenceType _ " " _ targetResourceType _ " reference " _ location _ " with system '" _ system _ "' and value '" _ value _ "' cannot be resolved", $$$OutcomeIs(422, "error", "invalid"))
}

/// Check if the specified reference can be resolved
ClassMethod ValidateReferenceValue(strategy As MyFHIRServer.Storage.Json.InteractionsStrategy, referenceType As %String, targetResourceType As %String, column As %String, referenceValue As %String, location As %String)
{
    set version = ""
    set value = referenceValue

    if (column = "url") && (referenceValue [ "|") // There is a version in the reference
    {
        set version = $PIECE(referenceValue, "|", 2)
        set value = $PIECE(referenceValue, "|", 1)
    }

    set query = "SELECT ID1 FROM " _ strategy.GetSearchTable(targetResourceType) _ " WHERE "_column_" = '"_value_"'"

    if (version '= "")
    {
        set query = query _ " AND version = '" _ version _ "'"
    }

    #dim rset as %SQL.StatementResult = ##Class(HS.FHIRServer.Util.RunSQLQuery).runQuery(query)

    if ('rset.%Next())
    {
        $$$ThrowFHIR($$$GeneralError, referenceType _ " reference " _ location _ " with value '" _ referenceValue _ "' cannot be resolved", $$$OutcomeIs(422, "error", "invalid"))
    }
}

}
