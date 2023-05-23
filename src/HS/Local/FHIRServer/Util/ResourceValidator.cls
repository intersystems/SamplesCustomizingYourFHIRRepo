Include HS.FHIRServer

/// Local validator, only need to validate CapabilityStatement; skip validation for other types
Class HS.Local.FHIRServer.Util.ResourceValidator Extends HS.FHIRServer.Util.ResourceValidator
{

/// Validate CapabilityStatement; skip validation for other types
Method ValidateResource(pResourceObject As %DynamicObject)
{
    do ##super(pResourceObject)
}

/// This method has been overwritten to add support for:
/// - Conditional references outside a transaction
/// - Validating the type in logical references
/// See *** CUSTOM CODE tags
/// This internal method validates the properties of a single class in the FHIR Schema.  If the class contains
/// properties that are objects, then this call is recursed with the sub-object(s)
/// Inputs:<br>
/// pFHIRObject      : The JSON object to validate. <br>
/// pFHIRTypename      : The classname in the FHIR Schema.<br>
/// pPath            : A FHIR-path representation to the object begin verified<br>
/// pStati           : The accumulated status from previous validations.  This invocation will append
///                    the details of any validation failures found.<br>
/// pIsInTransaction : Boolean indicating that we are inside a transction - which we set to 1 to allow conditional references outside the bundle!
/// Returns:         : An updated status with any additional validation errors included.
Method ValidateObject(pFHIRObject As %Library.DynamicObject, pFHIRTypename As %String, pPath As %String, pStati As %Status, pIsInTransaction As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC = pStati
    set pIsInTransaction = 1 // *** CUSTOM CODE that allows conditional references outside transactions

	// Loop through all the properties in the object
	Do {
		// [DEV NOTE]
		// The 'usage' object is used to identify conflicting property names for value types
		// It is also used to ensure that extensions are properly handled.  When a property is
		// encountered, its index is used to indicate its presence, and its property name is saved.
		//   usage(ix) = propName
		// All value types for a single property (e.g. valueInteger, valueBoolean, etc) have the same
		// index.  This allows us to detect duplicate value specifications within the JSON.
		//
		// For extension properties, we flag their presence by
		//  usage("ext", propName) =  "done" (when processed) | "found" when encountered and not processed
		// This entry is removed when the property being extended is encountered.  At the end, any remaining
		// entries are validated without the corresponding property having to be present (no value present
		// but id or extension info is)
		kill usage
		
		// Iterate through the object's properties
		Set tIterator = pFHIRObject.%GetIterator()
		While tIterator.%GetNext(.tPropName, .tData, .typeInJson) {
			if tData="" {
				$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrEmptyValue, pFHIRTypename, tPropName, $$$OutcomeInvalidPath(pPath_"."_tPropName)))
				Continue
			}
			
			// Check for empty object or array.
			if ($IsObject(tData) && 'tData.%IsA("%Stream.Object") && 'tData.%Size()) {
				$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrEmptyObjectOrArray, pFHIRTypename, tPropName, $$$OutcomeInvalidPath(pPath_"."_tPropName)))
				Continue
			}
			
			// Handle 'resourceType' specially ... it is not a field in the XML schema (which uses the tag)
			if (tPropName="resourceType") && ..metaAPI.IsValidResourceType(pFHIRTypename) {
				// Ignore 'resourceType' ONLY at the resource level
				Continue
			}
			
			// Check for a primitive extension
			if $Extract(tPropName,1)="_" {
				Set propExtnName = tPropName
				Set tPropName = $E(tPropName,2,*)
				Set extnTypeInJson = typeInJson
				Set typeInJson = pFHIRObject.%GetTypeOf(tPropName)

				if typeInJson '= "unassigned" {
					// The corresponding property exists, we will handle this extension when
					// we encounter it
					Continue
				}
				Set extensionData = tData
				Set tData = pFHIRObject.%Get(tPropName)
				// Already checked original tData for blank string and empty object/array earlier.
				
			} else {
				Set propExtnName = "_"_tPropName
				Set extensionData = pFHIRObject.%Get(propExtnName)
				Set extnTypeInJson = pFHIRObject.%GetTypeOf(propExtnName)
				if ($IsObject(extensionData)) && ('extensionData.%Size()) {
					$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrEmptyObjectOrArray, pFHIRTypename, tPropName, $$$OutcomeInvalidPath(pPath_".extension")))
				}
			}
			
			
			If ' $$$IsPropertyDefined(..metaAPI, pFHIRTypename, tPropName) {
				$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrUnexpectedPropertyName, pFHIRTypename, tPropName, $$$OutcomeInvalidPath(pPath)))
				Continue
			}
			Set jt =  $$$GetPropertyJsonType(..metaAPI, pFHIRTypename, tPropName)
			Set dt =  $$$GetPropertyFHIRType(..metaAPI, pFHIRTypename, tPropName)
			Set ix =  $$$GetPropertyIndex(..metaAPI, pFHIRTypename, tPropName)
			Set arr = $$$IsPropertyArray(..metaAPI, pFHIRTypename, tPropName)
			Set propertyIsObject = (jt = "o") || (jt = "alias")
			
			// Primitive Extension is not valid for an object property, treat it as an invalid property name
			if propertyIsObject && (extensionData '= "") {
				$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrUnexpectedPropertyName, pFHIRTypename, propExtnName, $$$OutcomeInvalidPath(pPath)))
				set extensionData = ""
				// Pretend there is no extension and continue to validate the base property
			}
			
			// Check for duplicate usage (for choice properties)
			if $D(usage(ix), firstUsage)'=0 {
				$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrDuplicateValue, tPropName, firstUsage, $$$OutcomeInvalidPath(pPath)))
				Continue
			}
			// Flag the usage of this property
			Set usage(ix) = tPropName
			
			// Check for a primitive extension
			if extensionData '= "" {
				if arr '= (extnTypeInJson = "array") {
					$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrInvalidExtensionCardinality, pFHIRTypename, tPropName, $$$OutcomeInvalidPath(pPath_"."_tPropName)))
				} else {
					if arr && (tData.%Size() '= extensionData.%Size()) {
						// If arrays, the sizes must match					
						$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrInvalidExtensionArraySize, pFHIRTypename, tPropName, $$$OutcomeInvalidPath(pPath_"."_tPropName)))
					}
				}
			}
			
			Set curPath = $Select(pPath="":tPropName, 1:pPath_"."_tPropName)
			if arr=1 {
				if typeInJson '= "array" {
					$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrNotAnArray, pFHIRTypename, tPropName, $$$OutcomeInvalidPath(curPath)))
					Continue
				}
				Set array = tData
				Set lastix = array.%Size()-1
				// Define this variable.  It may be set if extensionData is present
				Set extensionElement = ""
				
			} else {
				if typeInJson = "array" {
					$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrUnexpectedArray, pFHIRTypename, tPropName, $$$OutcomeInvalidPath(curPath)))
					Continue
				}
				Set array = ""
				Set lastix = 0
				// Assign this here since its once-through for scalars
				Set extensionElement = extensionData
			}
			Set propPath = curPath
			for index=0:1:lastix {
				// Save error codes, to facilitate easy check later to see if any were added.
				Set origErrorCodes = $system.Status.GetErrorCodes(tSC)
				if array'="" {
					set tData = array.%Get(index)
					Set typeInJson = array.%GetTypeOf(index)
					Set propPath = curPath_"["_index_"]"
					// Extract the corresponding extension Element
					if extensionData '= "" {
						Set extensionElement = extensionData.%Get(index)
						Set extElementTypeInJson = extensionData.%GetTypeOf(index)
						if tData = "" {
							if typeInJson '= "null" {
								// Empty string is always invalid.
								$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrEmptyValue, pFHIRTypename, tPropName, $$$OutcomeInvalidPath(pPath_"."_tPropName_"["_index_"]")))
							} elseif extElementTypeInJson = "null" {
								// Corresponding non-extension and extension element cannot both be JSON null.
								$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrInvalidPrimitiveNull, pFHIRTypename, tPropName, $$$OutcomeInvalidPath(pPath_"."_tPropName_"["_index_"]")))
							}
						} elseif ($IsObject(tData)) && ('tData.%Size()) {
							// Empty object or array is always invalid.
							$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrEmptyObjectOrArray, pFHIRTypename, tPropName, $$$OutcomeInvalidPath(pPath_"."_tPropName_"["_index_"]")))
						}
						if extensionElement = "" {
							if extElementTypeInJson '= "null" {
								// Empty string is always invalid.
								$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrEmptyValue, pFHIRTypename, "_"_tPropName, $$$OutcomeInvalidPath(pPath_"."_tPropName_"["_index_"]")))
							}
						} elseif '$IsObject(extensionElement) {
							// Must be an object.
							$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrNotAnObject, pFHIRTypename, "_"_tPropName, $$$OutcomeInvalidPath(pPath_"."_tPropName_"["_index_"]")))
						} elseif 'extensionElement.%Size() {
							// Empty object or array is always invalid.
							$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrEmptyObjectOrArray, pFHIRTypename, "_"_tPropName, $$$OutcomeInvalidPath(pPath_"."_tPropName_"["_index_"]")))
						}
						
					} else {
						if tData = "" {
							$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrEmptyValue, pFHIRTypename, tPropName, $$$OutcomeInvalidPath(pPath_"."_tPropName_"["_index_"]")))
							
						} elseIf ($IsObject(tData)) && ('tData.%Size()) {
							$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrEmptyObjectOrArray, pFHIRTypename, tPropName, $$$OutcomeInvalidPath(pPath_"."_tPropName_"["_index_"]")))
						}
					}
				} 
				
				if $system.Status.GetErrorCodes(tSC) '= origErrorCodes {
					Continue
				}
				
				// Below will handle single or multiple values in the same way.
				if propertyIsObject {
					// This property is an object
					if extensionElement '= "" {
						$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrUnexpectedExtension, pFHIRTypename, tPropName, $$$OutcomeInvalidPath(propPath)))
					}
					if typeInJson '= "object" {
						$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrNotAnObject, pFHIRTypename, tPropName, $$$OutcomeInvalidPath(propPath)))
						Continue
					}
					if (dt = "Reference") {
						Set ref = tData.reference
						Set targetList = $Get($$$GetPropertyTargetList(..metaAPI, pFHIRTypename, tPropName))
						// If a reference, validate it
						if (ref '= "") {
							// Create a block for easy exit
							do {
								
								// Match the reference against the allowed RegEx ignoring the resource type for now because we'll check it later
								Set patternStr = "((http|https):\/\/([A-Za-z0-9\-\\\.\:\%\$]*\/)+)?([^\/])*\/[A-Za-z0-9\-\.]{1,64}(\/_history\/[A-Za-z0-9\-\.]{1,64})?"
					
								Set matcher = ..matchers.GetAt(patternStr)
								if matcher="" {
									Set matcher = ##class(%Regex.Matcher).%New(patternStr)
									Do ..matchers.SetAt(matcher, patternStr)
								}
								// Check the value against the regular expression	
								if matcher.Match(ref) {
									// Next we will be checking the resource type.  This either is the second-to-last piece or 4th-to-last depending on whether a specific version of the resource is specified
									Set resourceType = $Piece(ref,"/",*-1)
									if (resourceType = "_history") {
										Set resourceType = $Piece(ref,"/",*-3)
									}
									if resourceType="" {
										$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrMissingReferencedResourceType, ref, tPropName, pFHIRTypename, $$$OutcomeInvalidPath(propPath) ))
									}
									elseif (targetList '= "") {
										// Check the resourceType against each entry in the target list
										Set ok = 0
										for itl=1:1:$LL(targetList) {
											Set target = $ListGet(targetList,itl)
											if ..metaAPI.IsA(resourceType, target) {
												// If it matches or is a Subclass, then accept it.
												set ok=1
												quit
											}
										}
										if 'ok {
											$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrInvalidReferenceTarget, resourceType_"::"_ref, tPropName, pFHIRTypename, $LTS(targetList), $$$OutcomeInvalidPath(propPath) ))
										}
									}
								}
								elseif '##class(HS.HC.Util).IsUUID(ref,1) {
									// If doesn't match regex for absolute/relative reference and isn't UUID, then check if it's a reference to a contained resource or a conditional reference
									Set patternStr = "#([A-Za-z0-9\-\.]{1,64})"
									Set matcher = ..matchers.GetAt(patternStr)
									if matcher="" {
										Set matcher = ##class(%Regex.Matcher).%New(patternStr)
										Do ..matchers.SetAt(matcher, patternStr)
									}
									// Check the value against the regular expression
									if 'matcher.Match(ref) {
										// Not a contained resource
										
										// Next we'll check if it is in a transaction and could be a conditional reference
										// Conditional references are not allowed outside of transaction bundles
										// This would be a search URI of form [type]?parameters...
										If ('pIsInTransaction || $Case($Find(ref,"?"),0:1,$L(ref):1,:0)) {
											// No "?" (or nothing after "?") means not a conditional reference - It's malformed
											$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrMalformedRelativeReference, ref, tPropName, pFHIRTypename, $$$OutcomeInvalidPath(propPath) ))
										} Else {
											// resourceType is the part of the URI before the "?"
											// Make sure it is included and is a valid resourceType for this reference
											Set resourceType = $Piece(ref,"?")
											if resourceType="" {
												$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrMissingReferencedResourceType, ref, tPropName, pFHIRTypename, $$$OutcomeInvalidPath(propPath) ))
											}
											elseif (targetList '= "") {
												// Check the resourceType against each entry in the target list
												Set ok = 0
												for itl=1:1:$LL(targetList) {
													Set target = $ListGet(targetList,itl)
													if ..metaAPI.IsA(resourceType, target) {
														// If it matches or is a Subclass, then accept it.
														set ok=1
														quit
													}
												}
												if 'ok {
													$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrInvalidReferenceTarget, resourceType_"::"_ref, tPropName, pFHIRTypename, $LTS(targetList), $$$OutcomeInvalidPath(propPath) ))
												}
											}
										}
									}
								}
								
							} while 0
						}
                        // *** CUSTOM CODE that deals with logical reference type START ***
                        elseif (tData.type '= "") && (targetList '= "") {
                            do {
                                $$$FSLog("pFHIRTypename=" _ pFHIRTypename _ "; pPath=" _ pPath _ "; Data.type:" _ tData.type _ "; $LTS(targetList)=" _ $LTS(targetList))
                                
                                // Check the resourceType against each entry in the target list
                                Set ok = 0
                                for itl=1:1:$LL(targetList) {
                                    Set target = $ListGet(targetList,itl)
                                    if ..metaAPI.IsA(tData.type, target) {
                                        // If it matches or is a Subclass, then accept it.
                                        set ok=1
                                        quit
                                    }
                                }

                                if 'ok {
                                    $$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrInvalidReferenceTarget, tData.type_"::"_ref, tPropName, pFHIRTypename, $LTS(targetList), $$$OutcomeInvalidPath(propPath) ))
                                }
                            }  while 0
                        }
                        // *** CUSTOM CODE that deals with logical reference type END ***
					}
					
					// The type of this object is specified in the Schema.  If the schema says 'alias'
					// it means that the type is ResourceContainer, so the type is the object's resourceType
					Set ot = $Select(jt="alias": tData.resourceType, 1:dt)
					Set tSC = ..ValidateObject(tData, ot, propPath, tSC, pIsInTransaction)
					Continue
					
				} 
				
				// This property is a primitive, so make sure that the JSON doesn't hold an object
				if (typeInJson = "object") {
					$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrUnexpectedObject, pFHIRTypename, tPropName, $$$OutcomeInvalidPath(propPath)))
					Continue
				}
				
				if extensionElement '= "" {
					// A primitive Extension exists, validate it	
					Set tSC = ..ValidateObject(extensionElement, "Element", propPath, tSC, pIsInTransaction)
				}
				
				// Now process the various primitive types
				if jt="n" {
					Set expectedTypeInJson="number"
				} elseif jt="s" {
					Set expectedTypeInJson="string"
				} elseif jt="b" {
					Set expectedTypeInJson="boolean"
				} elseif jt="x" {
					// XML Div
					Set expectedTypeInJson="string"
				}
				Set noPropertyValue = (typeInJson = "unassigned") || (typeInJson = "null")
				// It is an error if the property is of the wrong type ... unless the property is missing and there is an extension
				if (typeInJson '= expectedTypeInJson) && ( (extensionData ="") || 'noPropertyValue) {
					// The property type in the provided JSON is not correct.
					$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrWrongJsonType, pFHIRTypename, tPropName, typeInJson, expectedTypeInJson, $$$OutcomeInvalidPath(propPath)))
				}
				
				// Now validate the value of the property
				if (noPropertyValue) {
					// If the value is missing, we know its ok because there is an extension, so we're done.
					Continue
				}
				
				Set propType = $$$GetPropertyFHIRType(..metaAPI, pFHIRTypename, tPropName)
				if (jt = "b") || (propType = "decimal") || (propType = "base64Binary") {
					// No more checking for boolean, if the parser saw true/false then the typeInJson would be correct, otherwise wrong.
					// No validation for decimals.  If it was numeric, its OK.
					// No validation for base64Binary.
				} elseif propType = "positiveInt" {
					if (tData <= 0) || (tData > 2147483647) || ((tData\1) '= tData)  {
						$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrInvalidNumber, pFHIRTypename, tPropName, tData, propType, $$$OutcomeInvalidPath(propPath)))
					}
				} elseif propType = "unsignedInt" {
					if (tData < 0) || (tData > 2147483647) || ((tData\1) '= tData)  {
						$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrInvalidNumber, pFHIRTypename, tPropName, tData, propType, $$$OutcomeInvalidPath(propPath)))
					}
				} elseif propType = "integer" {
					if (tData < -2147483648) || (tData > 2147483647) || ((tData\1) '= tData)  {
						$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrInvalidNumber, pFHIRTypename, tPropName, tData, propType, $$$OutcomeInvalidPath(propPath)))
					}
				} else {
					
					Set patternStr = $$$GetRegexForPrimitive(..metaAPI, propType)
					if patternStr '= "" {
					
						Set matcher = ..matchers.GetAt(patternStr)
						if matcher="" {
							// Hack to work around a bad (sub-optimal) Regex in the R3 metaAPI
							Set usePatternStr = $Select(patternStr="[^\s]+([\s]?[^\s]+)*":"[^\s]+(\s[^\s]+)*", 1:patternStr)
							Set matcher = ##class(%Regex.Matcher).%New(usePatternStr)
							Do ..matchers.SetAt(matcher, patternStr)					
						}
						// Check the value against a regular expression	
						if 'matcher.Match(tData) {
							$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrMalformedValue, pFHIRTypename, tPropName, tData, propType, patternStr, $$$OutcomeInvalidPath(propPath)))
						}
						
					}
					
					if $$$IsPropertyValueSet(..metaAPI, pFHIRTypename, tPropName) {
						// There is an enumerated set of allowed values.  Verify.
						if ' $$$IsPropertyValueInSet(..metaAPI, pFHIRTypename, tPropName, tData) {
							// Build a list of valid values to include in the error message.
							Set list = ""
							Set name = ""
							for { 
								Set name = $$$NextValueInPropertyValueSet(..metaAPI, pFHIRTypename, tPropName, name)
								Quit:name=""
								Set list = list _ $select($length(list)=0: name, 1: ","_name)
							}
							$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrValueNotInEnumeration, pFHIRTypename, tPropName, tData, list, $$$OutcomeInvalidPath(propPath)))
							
						}
					}
				}
			}
		} 
	} while 0 // End of one-time-through block
	
	// Verify the presence of all required fields
	Set tPropName = ""
	for {
		Set tPropName = $$$NextRequiredProperty(..metaAPI, pFHIRTypename, tPropName)
		Quit:tPropName=""
		// See if any of the variants of this property was present		
		Set ix = $$$GetPropertyIndex(..metaAPI, pFHIRTypename, tPropName)
		if $Data(usage(ix))=0 {
			$$$FHIRAddError(tSC, $$$ERROR($$$HSFHIRErrMissingRequiredProperty, pFHIRTypename, tPropName, $$$OutcomeInvalidPath(pPath)))
		}
	}
		
	Return tSC
}

}
