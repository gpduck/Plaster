function Get-PlasterTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,
                   ParameterSetName="Path",
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Specifies a path to a folder containing a Plaster template or multiple template folders.  Can also be a path to plasterManifest.xml.")]
        [ValidateNotNullOrEmpty()]                   
        [string]
        $Path,

        [Parameter(ParameterSetName="Path",
                   HelpMessage="Indicates that this cmdlet gets the items in the specified locations and in all child items of the locations.")]
        [switch]
        $Recurse,

        [Parameter(Position=0,
                   Mandatory=$true,
                   ParameterSetName="InstalledModules",
                   HelpMessage="Initiates a search for Plaster templates inside of installed modules.")]
        [switch]
        $IncludeModules
    )
    
    process {
        function CreateTemplateObjectFromManifest([System.Xml.XmlDocument]$manifestXml, [PSModuleInfo]$module) {
            # TODO: Use the module that was passed in
            
            $metadata = $manifestXml["plasterManifest"]["metadata"]
            $manifestObj = [PSCustomObject]@{
                Title = $metadata["title"].InnerText
                Description = $metadata["description"].InnerText
                Version = New-Object -TypeName "System.Version" -ArgumentList $metadata["version"].InnerText
                Tags = $metadata["tags"].InnerText.split(",") | % { $_.Trim() }
                Manifest = $manifestXml
            }

            $manifestObj.PSTypeNames.Insert(0, "Microsoft.PowerShell.Plaster.PlasterTemplate")
            return $manifestObj
        }

        function GetManifestsUnderPath([string]$rootPath, [bool]$recurse) {
            $manifests = Get-ChildItem -Path $rootPath -Include "plasterManifest.xml" -Recurse:$recurse
            foreach ($manifest in $manifests) {
                # TODO: Definitely don't want to just SilentlyContinue here,
                #       what's the ideal way to handle manifest errors?
                $manifestXml = Test-PlasterManifest -Path $manifest.FullName -ErrorAction SilentlyContinue
                CreateTemplateObjectFromManifest $manifestXml $null
            }
        }

        if ($IncludeModules.IsPresent) {
            # Search for templates in module path
            $modules = Get-ModuleExtensions -Module Plaster -Version $PlasterVersion

            foreach ($module in $modules) {
                # Scan all module paths registered in the module
            }
        }
        elseif ($Path) {
            # Is this a folder path or a Plaster manifest file path?
            if (Test-Path $Path -PathType Leaf) {
                # Use Test-PlasterManifest to load the manifest file
                Test-PlasterManifest -Path $Path
            }
            else {
                GetManifestsUnderPath $Path $Recurse.IsPresent
            }
        }
        else {
            # Return all templates included with Plaster
            # TODO: Create and populate this path!
            GetManifestsUnderPath $PSScriptRoot\Templates $true
        }
    }
}