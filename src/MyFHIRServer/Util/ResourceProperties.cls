/// Resource properties helper
Class MyFHIRServer.Util.ResourceProperties
{

/// Order FHIR resource properties according to the spec
/// With modifyOriginalObject = 1, also the original resource is re-ordered 
/// This is a "shallow" method as it only looks at a few common attributes, and only orders the outer level of the object
/// This is however 40-50 times faster than the deep method, it only takes around 0.04 milliseconds
/// With modifyOriginalObject = 1 it takes around twice as much and so is "only" 20 times faster than the deep method
ClassMethod FHIROrderResourceProperties(resource As %DynamicObject, modifyOriginalObject As %Boolean = 0) As %DynamicObject
{
    set newresource = ..JsonOrderProperties(resource, [ "resourceType", "id", "meta", "text", "extension" ])

    if (modifyOriginalObject)
    {
        do ..CopyFromResource(resource, newresource) 
    }

    return newresource
}

/// Order FHIR resource properties according to the spec
/// With modifyOriginalObject = 1, also the original resource is re-ordered 
/// This is implemented by converting to XML and back so orders also deeper levels
/// This is 40-50 times slower than the shallow method, it takes 1.5 - 2 milliseconds 
/// With modifyOriginalObject = 1 it is "only" 20 times slower than the shallow method
ClassMethod FHIROrderResourcePropertiesDeep(schema As HS.FHIRServer.Schema, resource As %DynamicObject, modifyOriginalObject As %Boolean = 0) As %DynamicObject
{
    do ##class(HS.FHIRServer.Util.JSONToXML).JSONToXML(resource, .pOutStream, schema)
    set newresource = ##class(HS.FHIRServer.Util.XMLToJSON).XMLToJSON(.pOutStream, schema)

    if (modifyOriginalObject)
    {
        do ..CopyFromResource(resource, newresource) 
    }

    return newresource
}

/// Copy one json object and replace properties in the other
ClassMethod CopyFromResource(object As %DynamicObject, newobject As %DynamicObject)
{
    // First remove all original properties
    #dim iterator As %Iterator.Object = object.%GetIterator()
    while iterator.%GetNext(.name1, .value, .type)
    {
        do object.%Remove(name1)
    }

    // Properties are added back in at the last known empty slot in the object, so we end up with everything in reverse order
    // That is why we explicitly reverse that
    #dim reversedorder as %ListOfDataTypes = ##Class(%ListOfDataTypes).%New()
    #dim newiterator As %Iterator.Object = newobject.%GetIterator()
    while newiterator.%GetNext(.name, .value, .type)
    {
        do reversedorder.Insert(name)
    }

    // Now add back all properties from the new object in reverse order!!
    for index = reversedorder.Count():-1:1
    {
        set name = reversedorder.GetAt(index)
        set value = newobject.%Get(name)
        set type = newobject.%GetTypeOf(name)

        if (type = "boolean") || (type = "number") || (type = "null")
        {
            do object.%Set(name, value, type)
        }
        else
        {
            do object.%Set(name, value)
        }
    }
}

/// Create a new json object with its properties in the specified order
ClassMethod JsonOrderProperties(object As %DynamicObject, order As %DynamicArray) As %DynamicObject
{
    #dim newObject as %DynamicObject = {}

    // First set the ordered properties in the new object 

    for index = 0:1:order.%Size() - 1
    {
        set name = order.%Get(index)
        set done(name) = 1
        set type = object.%GetTypeOf(name)

        if $EXTRACT(type, 1, 2) '= "un" // unassigned
        {
            do newObject.%Set(name, object.%Get(name)) 
        }
    }
    
    // Now copy remaining attributes not specified
    #dim iterator As %Iterator.Object = object.%GetIterator()

    while iterator.%GetNext(.name, .value, .type)
    {
        if '$DATA(done(name))
        {
            set type = object.%GetTypeOf(name)

            if (type = "boolean") || (type = "number") || (type = "null")
            {
                do newObject.%Set(name, value, type)
            }
            else
            {
                do newObject.%Set(name, value)
            }
        }
    }

    return newObject
}

}
