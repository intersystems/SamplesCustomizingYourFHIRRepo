# Customizing Your InterSystems FHIR Repo Sample
This respository provides sample code that shows how you can customize the InterSystems IRIS for Health FHIR Repository.
It was originally created along with a presentation delivered at InterSystems Global Summit 2023.

## Why customize InterSystems IRIS for Health FHIR Repository
The InterSystems IRIS for Health FHIR Repository is a world class FHIR Repository, and in more than 80% of the cases the out-of-the-box capabilities will be sufficient
When you need extra capabilities, it is easy to extend.

hese are a number of examples of why you would customize your InterSystems IRIS for Health FHIR Repository:
-	You may need to enforce additional constraints, to for example improve data quality
-	You may want to cleanse or enrich resources before these are stored
-	You may want to enrich resources before these are returned
-	You do want to customize your CapabilityStatement to reflect the exact capabilities.

## Use cases
In this repo we have addresses the following use cases:
1. Pre-processing
   - By default, the InterSystems IRIS for Health FHIR Repository assigns an incrementing sequence number to each resource instance, which is good enough in many cases. We show you how to replace that with a GUID 
   - FHIR uses Identifiers to uniquely identify FHIR Resources. We have implemented code that ensures that the same identifier cannot be reused for another resource instance.

2. Post-processing
This repo shows various things you can do to enrich resources before these are returned, specifically:
   - Reference.display is defined as "Plain text narrative that identifies the resource in addition to the resource reference.". This repo adds some code in which we add a display value for each reference, so that external systems / users get more information about referenced resources without having to read that resource.
   - Resource.text is defined as "A human-readable narrative that contains a summary of the resource and can be used to represent the content of the resource to a human. The narrative need not encode all the structured data, but is required to contain sufficient detail to make it "clinically safe" for a human to just read the narrative. Resource definitions may define what content should be represented in the narrative to ensure clinical safety." We have provided a structure that you can use to dynamically pouplate Resource.txt using plain Objectscript or Pythoin code, or using a Jinja2 template.
   - The FHIR specification defines Resource oproperties in a certain order. At the same time json has no defined property order. During development and testing I found it of great help to re-order json proerties as defined in the specification (resourceType, id, meta, text, extension). 

3. References
In HL7 FHI, resources use Reference properties to link to other resources. Just like in Relational Databases, it makes sense that a FHIR Repository ensures Referential Integrity for those references. For example, when you create an Observation with a reference to a specific Patient resource, the FHIR Repository should first ensure that this Patient resource exists. Turning this around, it should also not be possible to delete a resource while there are still other resources that depend on it! In this repo, we have implemented:
   - Referential Integrity for create, update and delete

   - Processing of logical and conditional references by adding the literal reference.
 
## Set Up
This repo can be run using docker compose:

    `docker-compose up`

After starting, you can access the following URLs:
- Management Portal at http://localhost:32783/csp/sys/UtilHome.csp?$NAMESPACE=FHIR. Login using _SYSTEM/SYS
- You can fetch the FHIR metadata at http://localhost:32783/fhir/r4/metadata?_format=application/fhir%2Bjson 
- Import and run the [Postman collection](https://github.com/intersystems/SamplesCustomizingYourFHIRRepo/blob/2718e8db7973206cacbb4ffdd2c05e91e5d033b3/My%20Customized%20FHIR%20Server.postman_collection.json) 
 

## Using $$$FSLog()
This repo enables $$$FSLog after creating the FHIR Repository through the command 

    `set ^FSLogChannel("all") = 1`

You can view the FSLog global using http://localhost:32783/csp/healthshare/fhir/GJ.Log.cls

## Run the Sample
A [Postman collection](https://github.com/intersystems/SamplesCustomizingYourFHIRRepo/blob/2718e8db7973206cacbb4ffdd2c05e91e5d033b3/My%20Customized%20FHIR%20Server.postman_collection.json) is available to test the customizations

## Documentation
The following InterSystems IRIS for Health Documentation is helpful as background information:

**The InterSystems IRIS for Health FHIR Repository**

[FHIR Server: An Introduction](https://docs.intersystems.com/irisforhealth20231/csp/docbook/Doc.View.cls?KEY=HXFHIR_server_intro)

[Customizing a FHIR Server](https://docs.intersystems.com/irisforhealth20231/csp/docbook/DocBook.UI.Page.cls?KEY=HXFHIR_server_customize_arch)

**The FHIR specification**

[RESTful API](https://hl7.org/fhir/R4/http.html)

[Search](https://hl7.org/fhir/R4/search.html)

[References](https://hl7.org/fhir/R4/references.html)

**Background for Programmers**

[Using ObjectScript](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GCOS_intro)

[Using Embedded Python](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=AFL_epython)

## Bugslist
There are no known bugs at this point in time

## Finally
Use or operation of this code is subject to acceptance of the license available in the code repository for this code.

