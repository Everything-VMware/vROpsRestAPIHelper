#
# Module manifest for module 'vROpsRestAPIHelper'
#
# Generated by: Lars Panzerbjørn
#
# Generated on: 22/11/2019
#

@{

	# Script module or binary module file associated with this manifest.
	RootModule = 'vROpsRestAPIHelper.psm1'

	# Version number of this module.
	ModuleVersion = '0.9'

	# ID used to uniquely identify this module
	GUID = 'd7bffe1e-072a-48c3-be27-71748d19e2c2'

	# Author of this module
	Author = 'Lars Panzerbjørn'

	# Copyright statement for this module
	Copyright = '(c) 2019 Lars Panzerbjørn. All rights reserved.'

	# Description of the functionality provided by this module
	Description = 'This is a module to help with REST API calls.'

	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '5.0'

	# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
	FunctionsToExport = '*'

	# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
	CmdletsToExport = '*'

	# Variables to export from this module
	VariablesToExport = '*'

	# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
	AliasesToExport = '*'

	# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{

		PSData = @{

			# Tags applied to this module. These help with module discovery in online galleries.
			Tags = @("vROps","PowerCLI","REST API","VMware")

		} # End of PSData hashtable

	} # End of PrivateData hashtable

}