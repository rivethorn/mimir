#+private

package new

MAIN_FILE_CONTENT: string : `package main

import "core:fmt"

main :: proc() {
    fmt.println("Hellope!")
}
`

FMT_FILE_CONTENT: string : `{
    "$schema": "https://raw.githubusercontent.com/DanielGavin/ols/master/misc/odinfmt.schema.json",
    "character_width": 80,
    "tabs": true,
    "tabs_width": 4
}`

OLS_FILE_CONTENT: string : `{
    "$schema": "https://raw.githubusercontent.com/DanielGavin/ols/master/misc/ols.schema.json",
    "collections": [
        { "name": "pkgs", "path": "pkgs" }
    ],
    "enable_document_symbols": true,
    "enable_hover": true,
    "enable_snippets": true,
    "enable_fake_methods": true,
    "enable_inlay_hints_params": false
}`

GITIG_FILE_CONTENT: string : `bin/
*.bin
.DS_Store`

