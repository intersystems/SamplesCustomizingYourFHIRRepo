/// Interactions strategy
Class MyFHIRServer.Storage.Json.InteractionsStrategy Extends HS.FHIRServer.Storage.Json.InteractionsStrategy
{

Parameter StrategyKey As STRING = "MyJson";

Parameter InteractionsClass As STRING = "MyFHIRServer.Storage.Json.Interactions";

Parameter ResourceSuperclass As STRING = "MyFHIRServer.Storage.Json.Resource";

Parameter ResourceVersionSuperclass As STRING = "MyFHIRServer.Storage.Json.ResourceVer";

/// @API<br>
/// Return a CapabilityStatement metadata resource. The returned content is derived from
/// a strategy-specific means of formulating a CapabilityStatement. An example use of the
/// output might be to store the CapabilityStatement for a given Service.<br>
/// This method should not be confused with the Interactions class LoadMetadata() method,
/// which retrieves the stored CapabilityStatement for the current Service.
Method GetMetadataResource() As %DynamicObject
{
	#dim capabilityConfig as %DynamicObject = ..GetCapabilityConfig()
	set metadata = ##super()

	// Override searchInclude and searchRevInclude for resources
    set rest = metadata.rest.%Get(0)
    for index = 0:1:(rest.resource.%Size() - 1)
    {
		do ..OverrideIncludeOrRevInclude(rest.resource.%Get(index), capabilityConfig.resourceOverrides) 
    }

	return metadata
}

/// Replace Include And/Or RevInclude
ClassMethod OverrideIncludeOrRevInclude(resource As %DynamicObject, pConfigObj As %DynamicObject)
{
	#dim overrides as %DynamicObject = pConfigObj.%Get(resource.type)

	if overrides '= ""
	{
		do ..OverrideIfSet(resource, overrides, "searchInclude")
		do ..OverrideIfSet(resource, overrides, "searchRevInclude")
	}
}

/// Override property in resource if set in overrides
ClassMethod OverrideIfSet(resource As %DynamicObject, overrides As %DynamicObject, name As %String)
{
	Set overrideValue = overrides.%Get(name)

	if overrideValue '= ""
	{
		w "Processing " _ resource.type _ "; found " _ name _ " with size " _ overrideValue.%Size(),!

		if (overrideValue.%Size() > 0)
		{
			do resource.%Set(name, overrideValue)
		}
		else
		{
			do resource.%Remove(name)
		}
	}
	else
	{
		w "Processing " _ resource.type _ "; did not find " _ name,!
	}
}

/// Get Capability Template
Method GetCapabilityTemplate() As %DynamicObject
{
	Set json = {
		  "resourceType": "CapabilityStatement",
		  "id": "MyFHIRServer",
		  "meta": {
		    "versionId": "1",
	    	"lastUpdated": ($zdatetime($horolog,3,7))  //replaced at runtime, but must match 'instant' syntax
		  },
		  "url": "http://myfhirserver/fhir/CapabilityStatement/MyFHIRServer",
		  "version": "1",
		  "name": "My FHIR Server CapabilityStatement",
		  "status": "active",
		  "experimental": false,
		  "date": ($zdate($horolog, 3)),
		  "publisher": "VZVZ",
		  "kind": "instance",
		  "software": {
		    "name": "MyFHIRServer based on InterSystems IRIS for Health",
		    "version": (##class(%ZHSLIB.HealthShareMgr).VersionInfo())
		  },
		  "implementation": {
		    "description": "My FHIR Server",
		    "url": "<replaced-at-runtime>"
		  },
		  "fhirVersion": "<replaced-by-builder>",
		  "format": [
		    "xml",
		    "json"
		  ],
		  "patchFormat": [
		  	"application/json-patch+json"
		  ],
		  "rest": [
		  ]
	}
	return json
}

/// GetCapabilityConfig
/// updateCreate must be set to true to allow Conditional updates
Method GetCapabilityConfig() As %DynamicObject
{
	Set json = {
		"general-Documentation": [
			"This object controls the generation of a Metadata resource"
		],
		
		"paramExclude-Documentation": [
			"Each Entry represents a search parameter in the form of:"
			, "   <ResourceType>.<paramName> "
			, "that we do NOT want to support in the generated Metadata resource."
		],

		"paramExclude": [
			"Resource._content",
			"Resource._query"
		],
		
		"resourceDefaults-Documentation": [
			"These are the default values to apply to each resource added to the",
			"Metadata resource."
		],
		
		"resourceDefaults": {
			"profile": "",
			"interactions": [
				"read",
				"vread",
				"create",
				"update",
				"patch",
				"delete",
				"history-instance",
				"search-type"
			],
			"versioning": "versioned-update",
			"readHistory": false,
			"updateCreate": true, // Needs to be true for Conditional update to work
			"conditionalCreate": true,
			"conditionalRead": "not-supported",
			"conditionalUpdate": true,
			"conditionalDelete": "multiple"
		},
		
		"resourceOverrides-Documentation": [
			"Add an object with a resource name as a key.  Properties of the object",
			"will overrides the default value for all resources.  The first use is",
			"an overrides to the CapabilityStatement resource to indicate that only READ is allowed"
		],
		
		"resourceOverrides": {
			"Resource": {
				"interactions": [
					"transaction"
				]
			},
			"ActivityDefinition": {
				"searchRevInclude": [
					"Task.instantiates-canonical",
					"ActivityDefinition.composed-of",
					"ActivityDefinition.depends-on",
					"ActivityDefinition.derived-from",
					"ActivityDefinition.predecessor",
					"ActivityDefinition.successor"
				]
			},
			"Patient": {
				"searchRevInclude": [
					"Patient.link",
					"Task.owner",
					"Task.patient",
					"Task.requester",
					"Task.focus",
					"Task.subject"
				]
			},
			"Practitioner": {
				"searchRevInclude": [
					"Patient.general-practitioner",
					"Task.owner",
					"Task.requester",
					"Task.focus",
					"Task.subject"
				]
			},
			"Task": {
				"searchInclude": [
					"Task.based-on",
					"Task.focus",
					"Task.instantiates-canonical",
					"Task.owner",
					"Task.part-of",
					"Task.patient",
					"Task.requester",
					"Task.subject"
				],
				"searchRevInclude": [
					"Task.part-of",
					"Task.based-on",
					"Task.focus",
					"Task.subject"
				]
			}
		},
		
		"resourceList-Documentation": [
			"If present, this is the inclusive list of Resources to be supported by this",
			"Metadata object.  If not present, all resources in the schema are included"
		],
		"resourceList": (..GetResourceList())
	}

	return json
}

/// Get list of supported resources
ClassMethod GetResourceList() As %DynamicArray
{
	return [
			"ActivityDefinition",
			"Organization",
			"Patient",
			"Practitioner",
			"Task"
		]
}

}
