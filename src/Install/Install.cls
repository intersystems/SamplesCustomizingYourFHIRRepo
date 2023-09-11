/// Create  FHIR Namespace
Class Install.Install
{

Parameter Namespace As String = "FHIR";

/// Create FHIR namespace
ClassMethod CreateFHIRNameSpace(namespace As %String = {..#Namespace})
{
    set vars("Namespace") = namespace
    set vars("CLASSNAME") = $CLASSNAME()
	set sc = ..setup(.vars)

	if $$$ISERR(sc)
	{
		do $System.Status.DisplayError(sc)
	}
}

/// Manifest Definition.
XData Manifest [ XMLNamespace = INSTALLER ]
{
<Manifest>
	<Log Text="Set variables" Level="0"/>
	<Default Name="SourceDir" Value="/tmp"/>

	<Log Text="Changing system configuration" Level="0"/>
	<SystemSetting Name="Config.config.routines" Value="50" />
	<SystemSetting Name="Config.config.globals8kb" Value="2000" />

	<SystemSetting Name="Config.Startup.SystemMode" Value="DEVELOPMENT" />

	<Log Text="check if namespace ${Namespace} exists, if not create it" Level="0"/>
	<If Condition='(##class(Config.Namespaces).Exists("${Namespace}")=0)'>
		<Log Text="Creating Iris namespace ${Namespace}" Level="0"/>
		<Namespace Name="${Namespace}" Create="yes" Code="${Namespace}" Data="${Namespace}" Ensemble="1">
			<Configuration>
				<Database Name="${Namespace}" Dir="${MGRDIR}${Namespace}" Create="yes" Resource="%DB_${Namespace}"/>
				<ClassMapping Package="HS" From="HSLIB"/>
				<ClassMapping Package="HSMOD" From="HSLIB"/>
			</Configuration>
			<Invoke Class="%ZHSLIB.HealthShareMgr" Method="EnableHealthShareNamespace" CheckStatus="true" >
				<Arg Value="${Namespace}"/>
				<Arg Value="0"/>
				<Arg Value="1"/>
				<Arg Value="1"/>
			</Invoke>
		</Namespace>
	</If>
</Manifest>
}

/// Called as After Activate step from samples-customizing-your-fhir-repo
ClassMethod SetupFHIRServer(namespace As %String = {..#Namespace}) As %Status
{
    new $namespace
    set $namespace = namespace

    set appKey = "/fhir/r4"

    // Install elements that are required for a FHIR-enabled namespace
    do ##class(HS.FHIRServer.Installer).InstallNamespace()

	w !,"Loading custom serach parameters:",!
    do ##class(HS.FHIRMeta.Load.NpmLoader).importPackages("/home/irisowner/irisdev/MyFhirServer-searchparameters@0.0.1")

	set sc = $$$OK
    // Install an instance of a FHIR Service into the current namespace
    if '##class(HS.FHIRServer.ServiceAdmin).EndpointExists(appKey)
    {
       do ##class(Install.Install).InstallInstance("HS.Local.FHIRServer.Storage.Json.InteractionsStrategy", "MyFhirServer-searchparameters@0.0.1", appKey)
    }

    #; set dir = $System.Util.ManagerDirectory() _ "test-data-fhir"
    #; write !," ====== Load test data in "_ namespace _" from " _ dir

    #; set sc = ##class(HS.FHIRServer.Tools.DataLoader).SubmitResourceFiles(dir, "FHIRServer", appKey)

	#; if $$$ISERR(sc)
	#; {
	#; 	do $System.Status.DisplayError(sc)
	#; }

    return sc
}

/// Taken from HS.FHIRServer.Installer
/// Do not create CSP app
/// Do not set REST Url for instance
ClassMethod InstallInstance(pStrategyClass As %String, pPackage As %String, pAppKey As %String, pOAuthClientName As %String = "", pDesc As %String = "", pCreateDatabases = 1, pResourcePath As %String = "", pVersionPath As %String = "")
{
	Set pPackageList = $ListBuild("hl7.fhir.r4.core@4.0.1", pPackage)
    Set strategyKey = ##class(HS.FHIRServer.ServiceAdmin).GetStrategyKeyFromClass(pStrategyClass)
    Set repoId = ##class(HS.FHIRServer.API.RepoManager).CreateRepo(strategyKey, pCreateDatabases, pResourcePath , pVersionPath)
    do ..AddInstanceToRepo(repoId, pPackageList, , pOAuthClientName, pDesc)
}

/// Taken from HS.FHIRServer.Installer - Has to be coipied here because this method is marked Private 
ClassMethod AddInstanceToRepo(pRepoOrId As %String, pPackageList As %String, pAppKey As %String = "", pOAuthClientName As %String = "", pDesc As %String = "")
{
	#dim repoManager as HS.FHIRServer.API.RepoManager
	#dim serviceInstance as HS.FHIRServer.ServiceInstance
	#dim strategy as HS.FHIRServer.API.InteractionsStrategy
	
	#dim metaAPI as HS.FHIRMeta.API = ##class(HS.FHIRMeta.API).getInstance(pPackageList)
	// Get the actual "list" form in case the argument was a legacy "popular name"
	Set pPackageList = metaAPI.PackageList
	

	Set repoManager = ##class(HS.FHIRServer.API.RepoManager).getInstance(pRepoOrId)
	// Start a Transaction
	#dim TRANSACTION as HS.Util.Scoped.Transaction = ##class(HS.Util.Scoped.Transaction).Start()
	
	// Create the new ServiceInstance object for this service
	Set serviceInstance = repoManager.AddService(pPackageList)
	Set strategy = serviceInstance.CreateStrategy()
	
	// Create the FHIRService Configuration Object
	#dim configData as HS.FHIRServer.API.ConfigData = ##class(HS.FHIRServer.Tools.ConfigEditor).NewDefaultConfig()
	
	Set configData.DebugMode = 0
	Set configData.FHIRVersion = metaAPI.FHIRVersion
	Set configData.FHIRMetadataSet = $LTS(pPackageList)
	Set configData.InteractionsStrategyClass = repoManager.repo.strategyClass
	
	// Save an initial Configuration Object for the service and strategy
	Do strategy.SaveServiceConfigData(configData)
	do ##class(HS.FHIRServer.ServiceAdmin).SetInstanceStrategyConfigData(strategy.InstanceKey, strategy.GetDefaultStrategyConfig())
	
	// Create CSP App if URL provided
	if pAppKey '= "" {
		if pDesc = "" {
			Set pDesc = "FHIR Server end point; strategy=" _ repoManager.repo.strategyKey _ ", packages=" _ $LTS(pPackageList)
		}
		Do ##class(HS.FHIRServer.Installer).InstallCSPApp(pAppKey, repoManager.repo, pOAuthClientName, pDesc)
	}
	
	// Create the persistent classes
	Set options("restURL") = pAppKey
	Do repoManager.CreateService(serviceInstance.serviceId, .options)

	// Create a CapabilityStatement
	Set interactions = strategy.NewInteractionsInstance()
	do interactions.SetMetadata( strategy.GetMetadataResource() )
	 
	Do TRANSACTION.Commit()
}

/// This is a method generator whose code is generated by XGL.
ClassMethod setup(ByRef pVars, pLogLevel As %Integer = 3, pInstaller As %Installer.Installer, pLogger As %Installer.AbstractLogger) As %Status [ CodeMode = objectgenerator, Internal ]
{
 #; Let our XGL document generate code for this method.
 return ##class(%Installer.Manifest).%Generate(%compiledclass, %code, "Manifest")
}

}
