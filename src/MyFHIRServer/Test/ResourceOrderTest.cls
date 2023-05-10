/// test for moving/inserting id and extensions ate the start of the resource
Class MyFHIRServer.Test.ResourceOrderTest
{

/// Test2
ClassMethod Test2()
{
    #dim r as %DynamicObject = { "tag1": "1", "tag2": "2", "tag3": "3"}
    do r.%Remove("tag1")
    do r.%Remove("tag2")
    set r.tag4 = "4"
    set r.tag5 = "5"
    set r.tag6 = "6"
    w r.%ToJSON(),! // Result: {"tag5":"5","tag4":"4","tag3":"3","tag6":"6"}
}

/// Test
ClassMethod Test()
{
    #dim resource as %DynamicObject = {
        "resourceType": "Patient",
        "meta": {
            "lastUpdated": "2022-10-17T13:41:29Z",
            "versionId": "1"
        },
        "identifier": [
            {
                "value": "bertabotje01@vzvz.nl",
                "system": "http://irma"
            }
        ],
        "active": true,
        "name": [
            {
                "family": "Botje",
                "given": [
                    "Berta"
                ]
            }
        ],
        "telecom": [
            {
                "system": "email",
                "value": "bertabotje01@vzvz.nl",
                "use": "home"
            }
        ],
        "gender": "female",
        "birthDate": "1972-11-12",
        "contact": [
            {
                "relationship": [
                    {
                        "coding": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/v2-0131",
                                "code": "E",
                                "display": "Employer"
                            }
                        ]
                    }
                ],
                "name": {
                    "use": "official",
                    "text": "Internationalization"
                }
            }
        ],
        "extension": [
            {
                "valueReference": {
                    "reference": "Device/c3923294-0c11-4d9d-be19-cefc9cea7618",
                    "type": "Device"
                },
                "url": "http://xxx.nl/fhir/StructureDefinition/resource-origin"
            }
        ],
        "id": "202",
        "text": {
            "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p><b>Generated Narrative with Details</b></p><p><b>id</b>: f001</p><p><b>identifier</b>: 738472983 (USUAL), ?? (USUAL)</p><p><b>active</b>: true</p><p><b>name</b>: Pieter van de Heuvel </p><p><b>telecom</b>: ph: 0648352638(MOBILE), p.heuvel@gmail.com(HOME)</p><p><b>gender</b>: male</p><p><b>birthDate</b>: 17/11/1944</p><p><b>deceased</b>: false</p><p><b>address</b>: Van Egmondkade 23 Amsterdam 1024 RJ NLD (HOME)</p><p><b>maritalStatus</b>: Getrouwd <span>(Details : {http://terminology.hl7.org/CodeSystem/v3-MaritalStatus code 'M' = 'Married', given as 'Married'})</span></p><p><b>multipleBirth</b>: true</p><h3>Contacts</h3><table><tr><td>-</td><td><b>Relationship</b></td><td><b>Name</b></td><td><b>Telecom</b></td></tr><tr><td>*</td><td>Emergency Contact <span>(Details : {http://terminology.hl7.org/CodeSystem/v2-0131 code 'C' = 'Emergency Contact)</span></td><td>Sarah Abels </td><td>ph: 0690383372(MOBILE)</td></tr></table><h3>Communications</h3><table><tr><td>-</td><td><b>Language</b></td><td><b>Preferred</b></td></tr><tr><td>*</td><td>Nederlands <span>(Details : {urn:ietf:bcp:47 code 'nl' = 'Dutch', given as 'Dutch'})</span></td><td>true</td></tr></table><p><b>managingOrganization</b>: <a>Burgers University Medical Centre</a></p></div>",
            "status": "generated"
        }
    }

    #dim schema as HS.FHIRServer.Schema = ##class(HS.FHIRServer.Schema).LoadSchema("R4")
    set elapsed = 0
    set useFreshResource = 0
    set resourceString = resource.%ToJSON()
    set modifyOriginalObject = 1
    set max = 1000

    if useFreshResource
    {
        Set start = $ZH
        for count = 1:1:max
        {
            set resource = ##class(%DynamicObject).%FromJSON(resourceString)
        }
        Set end = $ZH, elapsed = end - start

        w "JSON Parsing took " _ elapsed _ " millisecs per run",!
    }

    Set start = $ZH
    for count = 1:1:max
    {
        if useFreshResource
        {
            set resource = ##class(%DynamicObject).%FromJSON(resourceString)
        }

        set newresource = ##class(MyFHIRServer.Util.ResourceProperties).FHIROrderResourceProperties(resource, modifyOriginalObject)
    }
    Set end = $ZH, elapsed1 = (end - start) - elapsed

    w "Shallow ordering took net " _ elapsed1 _ " millisecs per run",!

    Set start = $ZH
    for count = 1:1:max
    {
        if useFreshResource
        {
            set resource = ##class(%DynamicObject).%FromJSON(resourceString)
        }

        set newresource =  ##class(MyFHIRServer.Util.ResourceProperties).FHIROrderResourcePropertiesDeep(schema, resource, modifyOriginalObject)
    }
    Set end = $ZH, elapsed2 = (end - start) - elapsed

    w "Deep ordering took net " _ elapsed2 _ " millisecs per run",!
    set factor = (elapsed2 / elapsed1)
    w "Deep ordering is " _ factor _ " times slower",!

    // Shallow ordering took net .032756 millisecs per run
    // Deep ordering took net 1.562777 millisecs per run
    // Deep ordering is 47.70964098180486018 times slower

    #; set s1 = ##class(HS.FHIRServer.Util.JsonHelper).ToJSONString(resource, "   ", $CHAR(13,10))
    #; set s2 = ##class(HS.FHIRServer.Util.JsonHelper).ToJSONString(newresource, "   ", $CHAR(13,10))
    #; if (s1 = s2)
    #; {
    #;     w "equal: " _ s1
    #; }
    #; else
    #; {
    #;     w !,s1,!,!,s2,!
    #; }
}

}
