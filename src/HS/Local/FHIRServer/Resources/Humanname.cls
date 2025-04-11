/// Helper for Humanname formatting
Class MyFHIRServer.Resources.Humanname
{

/// Find proper name of Patient
ClassMethod FindAndFormatFullName(names As %DynamicArray) As %String
{
	#dim name as %DynamicObject = ..FindFullName(names)

	if '$ISOBJECT(name)
	{
		return "No Name"
	}

	return ..FormatName(name)
}

/// Find proper name of Patient
ClassMethod FindFullName(names As %DynamicArray) As %String
{
	if '$ISOBJECT(names)
	{
		return ""
	}

	// First, find maiden
	for nameIndex = 1:1:(names.%Size())
	{
		set name = names.%Get(nameIndex - 1)

		if name.use = "maiden"
		{
			return name
		}
	}

	// Then, find offical
	for nameIndex = 1:1:(names.%Size())
	{
		set name = names.%Get(nameIndex - 1)

		if name.use = "official"
		{
			return name
		}
	}

	// If no matches, return first name
	return names.%Get(0)
}

/// Format Full Name
ClassMethod FormatName(name As %DynamicObject) As %String
{
	if name.text '= ""
	{
		return name.text
	}

	set fullname = name.family

	if (fullname = "")
	{
		set fullname = "UnknownFamily"
	}

	set fullname = fullname _ ","

	if $ISOBJECT(name.given)
	{
		for givenIndex = 1:1:(name.given.%Size())
		{
			set fullname = fullname _ " " _ name.given.%Get(givenIndex - 1)
		}
	}
	else
	{
		set fullname = fullname _ "No-Given"
	}

	return fullname
}

}
