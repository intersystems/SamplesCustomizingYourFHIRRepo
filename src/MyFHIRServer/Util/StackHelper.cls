/// Get CallStack
Class MyFHIRServer.Util.StackHelper
{

/// Get stack level relative to the caller in the format ##class("_classname_")."_method_"()
ClassMethod GetCallerName() As %String
{
    return ..GetStackLevel($STACK(-1) - 2)
}

/// PrintStack 
ClassMethod PrintStack() As %Status
{
    set depth = $STACK(-1)

    for i=1:1:depth-1 // Do not include PrintStack
    {
        w ..GetStackLevel(i),!
    }

    return $$$OK
}

/// GetStackLevel 
ClassMethod GetStackLevel(index As %Integer) As %String
{
    set level = $EXTRACT($STACK(index, "PLACE"), 2, *)
    set classname = $PIECE($PIECE(level, "^", 2), ".", 1, *-1)
    set method = $PIECE(level, "+", 1)

    return "##class("_classname_")."_method_"()"
}

}
