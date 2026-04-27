/// Registers the /api web application that dispatches to Sample.REST.
/// Mirrors the pattern in Sample.MCPSetup so the install runs at module load time.
Class Sample.RESTSetup Extends %RegisteredObject
{

ClassMethod Run() As %Status
{
    New $NAMESPACE
    Set $NAMESPACE = "%SYS"

    // Recreate the app idempotently
    Do ##class(Security.Applications).Delete("/api")

    Kill props
    Set props("DispatchClass") = "Sample.REST"
    Set props("NameSpace") = "IRISAPP"
    Set props("AutheEnabled") = 64    // unauthenticated access
    Set props("MatchRoles") = ":%All"
    Set props("Enabled") = 1
    Set props("CookiePath") = "/api"
    Set props("Description") = "Hepatitis dashboard REST API"

    Set sc = ##class(Security.Applications).Create("/api", .props)
    If $$$ISERR(sc) {
        Write "Error creating /api web app: ", $System.Status.GetErrorText(sc), !
        Quit sc
    }
    Write "REST web app /api created successfully (unauthenticated, namespace IRISAPP).", !
    Quit $$$OK
}

}
