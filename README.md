# Mimir

[Odin](https://odin-lang.org)'s little toolchain.

> [!NOTE]
Still in heavy development.

---

## The idea

Odin doesn't have a package manager. It's not an accident, and it's not
something I'm trying to "fix."

[GingerBill](https://github.com/gingerBill), Odin's creator, has been pretty clear that Odin won't get one.
The language stays deliberately small, and pulling in a whole ecosystem of
dependency-management cruft kind of goes against that.
The community leans on `git` for sharing code, and honestly, it works.

So Mimir is not a package manager. It never will be, and it says so proudly.

What Mimir *is*: a friendlier way to run the exact `git` commands you'd run
anyway. `mimir add` clones a repo into your `pkgs/` directory. `mimir update`
is a `git pull`. `mimir remove` deletes a folder. That's it — no registry,
no lockfiles, no hidden machinery.

Git is the source of truth. Mimir just holds the door open for you.

---

## Installing (ish)

You'll need Odin itself on your `PATH`, plus `git`. Right now there's no
release pipeline to speak of — you build from source:

```bash
cd mimir
odin build src -collection:pkgs=pkgs -o:speed
```

Then put the `mimir` binary somewhere on your `PATH`. That's it.

## The layout

Mimir has opinions, but they're simple ones. Every command works inside a
project with:

```
my-project/
├── src/          # your code (must contain at least one .odin file)
├── pkgs/         # packages you've added, living right next to your code
├── bin/
│   ├── debug/    # debug builds land here
│   └── release/  # and release builds here
├── ols.json      # Mimir reads your collections from here
└── odinfmt.json
```

`mimir new` scaffolds all of this — including a `git init` — so you rarely
have to think about it.

---

## Commands

Everything you can do, in one place:

| command | what it does |
| ------- | ------------ |
| `mimir new <name>` | Scaffold a fresh Odin project (`src/`, `pkgs/`, `ols.json`, git init — the works) |
| `mimir build` | Compile the current project into `bin/` |
| `mimir run` | Build if needed, then run the thing |
| `mimir add <site/owner/repo> [--name <custom>]` | `git clone`s a repo into `pkgs/` |
| `mimir remove <pkg>` | Delete a package directory from `pkgs/` |
| `mimir update <pkg>` | `git pull` a package from upstream |
| `mimir list` | Show a pretty tree of everything in `pkgs/` |
| `mimir install [<site/owner/repo>]` | Build a binary — the current project or a remote one — and install it on your system |
| `mimir uninstall <pkg>` | Remove an installed binary from your system |
| `mimir clean` | Nuke `bin/` and all build artifacts |
| `mimir version` | Tell you what version you're running |
| `mimir help` | Show this help from inside the terminal |

Short aliases cover the common ones — `mimir b` for build, `mimir r` for
run. Useful when your hands are already on the keyboard.

### Options worth knowing

- `--release` / `-r` on `build` and `run` compiles in release mode. Debug and
  release binaries stay separate, so one never clobbers the other.
- `--silent` / `-s` on `build` and `run` quiets the chit-chat and lets your
  own output shine.
- `--dry-run` / `-d` on `remove`, `update`, `uninstall`, and `clean` shows
  you exactly what would happen before anything does. Nice when you're not
  sure.
- `--no-git` on `new` skips the `git init` when you manage version control
  yourself.
- `run` is smart about it — it only rebuilds when your `src/` files have
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

Because Mimir reads your `ols.json` for `collections`, adding a package and
then importing it as `pkgs:something` just works — no hand-typed
`-collection` flags.

---

## Current state

Every command is wired up and working: `new`, `build`, `run`, `add`,
`remove`, `update`, `list`, `install`, `uninstall`, `clean`, `version`, and
`help` — each with its own `--help`. `install` builds straight into release
mode and drops the binary on your system; `uninstall` takes it right back
off.

It's still young, so expect a rough edge or two. Hit one? File it. It's appreciated in advance!

The project follows Odin conventions loosely — `src/` for your code, `pkgs/`
for everything else — and each package keeps its own tiny package directory
so the language server (`ols`) can see them cleanly.

---

## Why it exists

Mimir was built out of love for Odin's stance: few moving parts, no
ceremony, the tools you need and nothing you don't. The last thing it wants
to become is a layer of abstraction that hides the actual work from you.

So Mimir stays honest. It wraps `git`. It shares your `ols.json`. It puts
packages in a normal folder you could manage by hand if you ever wanted to.
If Mimir vanished tomorrow, you'd lose nothing — your code, your
dependencies, and your repo would all still be right there.

It's not a package manager, and it never will be. It's just a kinder way to
talk to the tools Odin already gives you.

---

MIT licensed. Built with love and a little bit of Odin.
