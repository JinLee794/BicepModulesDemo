The `'Test-NamePrefixAvailability'` function provides you with the capability to test if the [`namePrefix`](./The%20CI%20environment%20-%20Token%20replacement#optional-local-custom-tokens), specified in the [`settings.json`](https://github.com/Azure/BicepModulesDemo/blob/main/settings.json) file, conflicts with any existing resource.

---

### _Navigation_

- [Location](#location)
- [How it works](#what-it-does)
- [How to use it](#how-to-use-it)

---
# Location

You can find the script under `utilities/tools/Test-NamePrefixAvailability.ps1`

# How it works

When invoked, the script

1. Fetches all parameter files for modules that require unique names. For example
   - `'Microsoft.Storage/storageAccounts'`
   - `'Microsoft.ContainerRegistry/registries'`
   - `'Microsoft.KeyVault/vaults'`
1. Replace any tokens contained in the parameter files with the key-value pairs provided in the `Tokens` input parameter
1. Search for each resource resource type if the final name would be taken
1. Return the result for each resource alongside a final recommendation to use / not use the chosen `'namePrefix'`

# How to use it

> **Note:** You'll need to have an active Azure login. If not connected, you can do so via the `Connect-AzAzccount` cmdlet (from the `Az.Resources` PowerShell module).
> **Note:** The script must be loaded before the function can be invoked

For details on how to use the function please refer to the script's local documentation.
