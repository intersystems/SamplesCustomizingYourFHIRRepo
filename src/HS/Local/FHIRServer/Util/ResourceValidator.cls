Include HS.FHIRServer

/// Local validator, only need to validate CapabilityStatement; skip validation for other types
Class HS.Local.FHIRServer.Util.ResourceValidator Extends HS.FHIRServer.Util.ResourceValidator
{

/// Validate CapabilityStatement; skip validation for other types
Method ValidateResource(pResourceObject As %DynamicObject)
{
    if (pResourceObject.resourceType = "CapabilityStatement")
    {
        do ##super(pResourceObject)
    }
}

}
