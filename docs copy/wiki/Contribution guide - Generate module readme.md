As per CARML module design structure, every module in the CARML library requires a ReadMe markdown file documenting the set of deployable resource types, input and output parameters and a set of relevant template references from the official Azure Resource Reference documentation.

The ReadMe generator utility aims to simplify contributing to the CARML library, as it supports creating from scratch or updating the module ReadMe markdown file.

---

### _Navigation_

- [Location](#location)
- [How it works](#what-it-does)
  - [Special case: 'Parameter Usage' section](#special-case-parameter-usage-section)
- [How to use it](#how-to-use-it)

---
# Location

You can find the script under `/utilities/tools/Set-ModuleReadMe.ps1`

# How it works

1. Using the provided template path, the script first makes sure to convert it to ARM/JSON if necessary (i.e. if a path to a Bicep file was provided)
1. If the intended readMe file does not yet exist in the expected path, it is generated with a skeleton (with e.g. a generated header name)
1. It then goes through all sections defined as `SectionsToRefresh` (by default all) and refreshes the section content (for example for the `Parameters`) based on the values in the ARM/JSON Template. It detects sections by their header and regenerates always the full section.
1. Once all are refreshed, the current ReadMe file is overwritten. **Note:** The script can be invoked with a `WhatIf` in combination with `Verbose` to just receive an console-output of the updated content.

## Special case: 'Parameter Usage' section

The `Parameter Usage` examples are located just beneath the `Parameters` table. They are intended to show how to use complex objects/arrays that can be provided as parameters, excluding child-resources as they have their own readMe.

**For the most part, this section is to be populated manually**. However, for a specific set of common parameters, we automatically add their example to the readMe if the parameter exists in the template. At the time of this writing these are:
- Private Endpoints
- Role Assignments
- Tags
- User Assigned Identities

To be able to change this list with minimum effort, the script reads the content from markdown files in the folder: `utilities/tools/moduleReadMeSource` and matches their title against the parameters of the template file. If a match is found, it's content is added to the readme alongside the generated header. This means, if you want to add another case, you just need to add a new file to the `moduleReadMeSource` folder and follow the naming pattern `resourceUsage-<parameteRName>.md`.

For example, the content of file `resourceUsage-roleAssignments.md` in folder `moduleReadMeSource` is added to a template's readMe if it contains a parameter `roleAssignments`. The combined result is:

```markdown
### Parameter Usage: `roleAssignments`

<[resourceUsage-roleAssignments.md] file content>
```

# How to use it

For details on how to use the function please refer to the script's local documentation.
> **Note:** The script must be loaded before the function can be invoked
