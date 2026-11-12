<div align="center">
    <img src="assets/banner.png"/>
    <div style="text-align: center; font-style: italic; margin-top: 0.5rem;">
        <a href="https://odin-lang.org">Odin</a>'s little toolchain.
    </div>
</div>

---

## The idea

Odin doesn't have a package manager. It's not an accident, and it's not
something I'm trying to "fix."

[GingerBill](https://github.com/gingerBill), Odin's creator, has been pretty clear that Odin won't get one.
The language stays deliberately small, and pulling in a whole ecosystem of
dependency-management cruft kind of goes against that.
The community leans on `git` for sharing code, and honestly, it works.

So Mimir is not a package manager. It never will be, and it says so proudly.

What Mimir *is*: a friendlier way to run the commands you'd run
anyway. Mimir wraps the tools Odin already gives you — `odin build`
and the like — into a unified workflow that feels natural to Odin developers.

Git is the source of truth. Mimir just holds the door open for you.

---

## Installation

There's a one-liner for each platform. Each grabs the latest [release](https://github.com/rivethorn/mimir/releases)
from GitHub, drops it on your system, and puts it on your `PATH` for you.

**Linux / macOS** (bash):

```bash
curl -fsSL https://raw.githubusercontent.com/rivethorn/mimir/main/scripts/install.sh | bash
```

If you'd rather inspect it first, download the script and run it:

```bash
curl -fsSL https://raw.githubusercontent.com/rivethorn/mimir/main/scripts/install.sh -o install-mimir.sh
bash install-mimir.sh
```

**Windows** (PowerShell):

```powershell
irm https://raw.githubusercontent.com/rivethorn/mimir/main/scripts/install.ps1 | iex
```

Open a fresh shell afterwards to pick up the PATH change — Mimir lands in
`~/.mimir/bin` (Linux/macOS) or `%USERPROFILE%\.mimir\bin` (Windows). The
scripts are in the repo under `scripts/` if you want to read them: `install.sh`
and `install.ps1`.

### Build from source

Prefer to build it yourself? You need Odin on your `PATH` plus `git`:

```bash
cd mimir
odin build . -collection:pkgs=pkgs -o:speed
```

Then put the `mimir` binary somewhere on your `PATH`. Done.

Hackers: `build.sh --debug` (`build.bat --debug` on Windows) produces
`bin/mimir-dbg` with memory tracking in `-debug` builds — a leak report
(grouped by call site, plus bad frees) describes what's still allocated
when the command finishes.

---

## The layout

Mimir has opinions, but they're simple ones. Every command works inside a
project with:

```
my-project/
├── main.odin     # your program, alongside any other project Odin files
├── bin/
│   ├── debug/    # debug builds land here
│   └── release/  # and release builds here
├── ols.json      # Mimir reads your collections from here
└── odinfmt.json
```

`mimir new` scaffolds all of this — including a `git init` — so you rarely
have to think about it. It does not create a `src/` or `pkgs/` directory;
add collections when you need them with `mimir add-col <path>`.

With `-lib`, you get the library outline instead — just your package file
at the top level:

```
my-lib/
├── my-lib.odin  # package my_lib
├── ols.json
└── odinfmt.json
```

---

## Commands

Everything you can do, in one place:

| command | what it does |
| ------- | ------------ |
| `mimir new <name> [-lib]` | Scaffold a fresh Odin project (root-level Odin files, `ols.json`, git init — the works; `-lib` scaffolds a library instead) |
| `mimir build [pkg] [-odin-flag:<flag> ...]` | Compile the project root — or the given package directory — into `bin/`, named after the directory |
| `mimir run [pkg] [-odin-flag:<flag> ...] [-- args]` | Build if needed, then run the project or package; pass arguments through with `--` |
| `mimir add-col <path>` (`ac`) | Create the directory and add it to `ols.json`, using the path as both name and path |
| `mimir remove-col <name>` (`rc`) | Remove the collection and its directory; prompts before deleting files |
| `mimir install <repo>` | Build a binary — the current project (`.`) or a remote one — and install it on your system |
| `mimir uninstall <pkg>` | Remove an installed binary from your system |
| `mimir list` | Show installed packages |
| `mimir clean` | Nuke `bin/` and all build artifacts |
| `mimir version` | Tell you what version you're running |
| `mimir help` | Show this help from inside the terminal |

Short aliases cover the common ones — `mimir b` for build, `mimir r` for run.
Useful when your hands are already on the keyboard.

### Options worth knowing

- `-release` on `build` and `run` compiles in release mode. Debug and
  release binaries stay separate, so one never clobbers the other.
- `-silent` on `build` and `run` quiets the chit-chat and lets your
  own output shine.
- `-odin-flag:<flag>` on `build` and `run` passes an additional flag to the
  Odin compiler. Repeat it for multiple flags, for example
  `mimir build -odin-flag:-no-bounds-check -odin-flag:-define:FEATURE=true`.
  For `run`, put compiler flags before `--`; arguments after `--` go to your
  program, e.g. `mimir run -odin-flag:-no-bounds-check -- arg1`. Mimir
  rebuilds when this compiler-flag set changes.
- `build` and `run` take an optional package directory or single Odin
  file: `mimir build tools/migrate` compiles that package — named after
  the directory — into `bin/` instead of compiling the project root, and `mimir run
  tools/one.odin` does the same for one file (named after the file,
  built with odin's `-file` under the hood). Either form must hold a
  `main` procedure. The project root is the default target. With an
  explicit target,
  `build` and `run` work outside a project too — the binary still lands
  in `bin/`, and `ols.json` collections apply when one is around. For
  `run`, a first argument that resolves to nothing — or to a file odin
  can't build — is passed through to your program as before.
- `add-col <path>` adds `{ "name": "<path>", "path": "<path>" }` to
  `ols.json` and creates the directory (including missing parents).
  `remove-col <name>` removes the collection directory too; it asks for
  confirmation first if the directory contains files. These commands also
  have the short aliases `ac` and `rc`.
- `-dry-run` on `uninstall` and `clean` shows you exactly what would
  happen before anything does. Nice when you're not sure.
- `-no-git` on `new` skips the `git init` when you manage version control
  yourself.
- `-lib` on `new` scaffolds a library instead of a binary: just a
  top-level `[name].odin` carrying `package [name]`.
  Dashes become underscores (`my-lib` → `package my_lib`), and the
  `.gitignore` leaves the binary name out since there is none.
- `run` is smart about it — it only rebuilds when your Odin files have
  actually changed since the last build. Otherwise it says "Already at latest
  change" and gets on with running.

---

## What a fresh start looks like

`mimir new hello` gives you a tiny `main.odin` that greets the world:

```odin
package main

import "core:fmt"

main :: proc() {
    fmt.println("Hellope!")
}
```

(`Hellope` is an Odin tradition. You'll get used to it. It grows on you.)

With `-lib`, `mimir new mylib` gives you `mylib/mylib.odin` instead:

```odin
package mylib

hello :: proc() -> string {
    return "Hellope!"
}
```

Same tradition, library-shaped: the `ols.json` starts with no collections.
Add the library's directory to a project with `mimir add-col <path>`.

Mimir reads `collections` from `ols.json` when building, so adding a
collection automatically supplies Odin's `-collection` flag.

---

## Current state

Every command is wired up and working: `new`, `build`, `run`, `add-col`,
`remove-col`, `install`, `uninstall`, `list`, `clean`, `version`, and `help`
— each with its own `-help`. `install` builds straight into release mode and installs the
binary on your system; `uninstall` takes it right back off.

The codebase uses the `reflags` package for consistent command-line parsing
throughout, making the CLI clean and maintainable. Smart rebuild detection
keeps iteration fast — changes to Odin files trigger rebuilds, but unchanged
projects skip the rebuild step entirely.

It's still young, so expect a rough edge or two. Hit one? File it. It's
appreciated in advance!

Mimir's own internal packages remain in `pkgs/` and are configured as an
OLS collection; projects created by Mimir start without a `pkgs/` folder or
collection.

---

## Why it exists

Mimir was built out of love for Odin's stance: few moving parts, no
ceremony, the tools you need and nothing you don't. The last thing it wants
to become is a layer of abstraction that hides the actual work from you.

So Mimir stays honest. It wraps `odin` and `git`. It shares your `ols.json`.
It puts packages in a normal folder you could manage by hand if you ever
wanted to. If Mimir vanished tomorrow, you'd lose nothing — your code, your
dependencies, and your repo would all still be right there.

It's not a package manager, and it never will be. It's just a kinder way to
talk to the tools Odin already gives you.

---

MIT licensed. Built with love and a little bit of Odin.
