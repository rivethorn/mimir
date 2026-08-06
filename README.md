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

So Mimir isn't a package manager. I want to be really clear about that,
because I think it's the heart of the whole thing.

What Mimir *actually* is, is a friendlier way to run the same `git`
commands you were probably going to run anyway. When you `mimir add` a
package, it does a `git clone` into a temp folder and drops the code into
your `pkgs/` directory. `mimir update` is a `git pull`. `mimir remove`
just deletes the folder. That's it. No registry, no lockfiles, no hiding
what's actually happening under the hood.

Git is the source of truth. Mimir just holds the door open for you.

---

## Installing (ish)

You'll need Odin itself on your `PATH`, plus `git`. Right now there's no
release pipeline to speak of — you build from source:

```bash
cd mimir
odin build src -collection:pkgs=pkgs
```

Then put the `mimir` binary somewhere on your `PATH`. That's it.

## The layout

Mimir has opinions, but they're simple ones. Every command works inside a
project that has:

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

`mimir new` scaffolds all of this for you, so you rarely have to think
about it.

## Commands

Everything you can do, in one go:

| command | what it does |
| ------- | ------------ |
| `mimir new <name>` | Scaffold a fresh Odin project (`src/`, `pkgs/`, `ols.json`, git init — the works) |
| `mimir build` | Compile the current project into `bin/` |
| `mimir run` | Build if needed, then run the thing |
| `mimir add <site/owner/repo> [--name <custom>]` | `git clone`s a repo into `pkgs/` |
| `mimir remove <pkg>` | Delete a package directory from `pkgs/` |
| `mimir update <pkg>` | `git pull` a package from upstream |
| `mimir list` | Show a pretty tree of everything in `pkgs/` |
| `mimir clean` | Nuke `bin/` and all build artifacts |
| `mimir version` | Tell you what version you're running |
| `mimir help` | Show this help from inside the terminal |

Short aliases exist for most of them — `mimir b` for build, `mimir r` for
run. Useful when your hands are already on the keyboard.

### Options worth knowing

- `--release` / `-r` on `build` and `run` compiles in release mode. Debug
  and release binaries are kept separate, so you never clobber one with
  the other.
- `--silent` / `-s` on `build` and `run` quiets the chit-chat and lets
  your own output shine.
- `--dry-run` / `-d` on `remove`, `update`, and `clean` shows you exactly
  what would happen before anything does. Nice when you're not sure.
- `run` is smart-ish about it — it only rebuilds when your `src/` files
  have actually changed since the last build. Otherwise it just tells you
  "Already at latest change" and gets on with running.

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

Because Mimir reads your `ols.json` for `collections`, adding a package
and then importing it as `pkgs:something` just works — no fiddling with
`-collection` flags by hand.

## Current state of the world

Honest status card:

- **Done and working:** `new`, `build`, `run`, `add`, `remove`, `update`,
  `list`, `clean` — each with their `--help`.
- **Planned / sitting in a comment:** the skeleton for `install` /
  `uninstall`, and toolchain management are sketched in `state.odin` but
  not wired up yet.
- **Known rough edges:** it's young. Report bugs, be kind.

The project structure follows Odin conventions loosely — `src/` for your
code, `pkgs/` for everything else — and each package has its own tiny
package directory so the language server (`ols`) can see them cleanly.

## A little philosophy

I made this because I love Odin's stance: few moving parts, no ceremony,
the tools you need and nothing you don't. The last thing I want is to
become a layer of abstraction that hides the actual work from you.

So Mimir stays honest. It wraps `git`. It shares your `ols.json`. It puts
packages in a normal folder you could manage by hand if you ever wanted
to. If Mimir vanished tomorrow, you'd lose nothing — your code, your
dependencies, and your repo would all still be right there.

It's not a package manager, and it never will be. It's just a kinder way
to talk to the tools Odin already gives you.

---

MIT licensed. Built with love and a little bit of Odin.
