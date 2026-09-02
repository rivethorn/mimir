package cli

import "pkgs:state"

@(private = "file")
Flag :: struct {
	command:           state.Command,
	name, short, desc: string,
}

Main_Commands :: [?]Flag {
	{
		command = .Build,
		name = "build",
		short = "b",
		desc = "Compile the current project",
	},
	{
		command = .Run,
		name = "run",
		short = "r",
		desc = "Compile and run the current project",
	},
	{command = .New, name = "new", desc = "Create a new Odin project"},
	{command = .Install, name = "install", desc = "Install an Odin binary"},
	{
		command = .Uninstall,
		name = "uninstall",
		desc = "Uninstall an Odin binary from your system",
	},
	{
		command = .Clean,
		name = "clean",
		desc = "Remove all built binaries and build artifacts",
	},
	{command = .Version, name = "version", desc = "Show Mimir's version"},
	{command = .Help, name = "help", short = "h", desc = "Show help message"},
}

Build_Options :: [?]Flag {
	{
		name = "--release",
		short = "-r",
		desc = "Compile the project in release mode",
	},
	{name = "--silent", short = "-s", desc = "Silent the terminal output"},
	{name = "--help", short = "-h", desc = "Show help message"},
}

Run_Options :: [?]Flag {
	{
		name = "--release",
		short = "-r",
		desc = "Compile and run the project in release mode",
	},
	{name = "--silent", short = "-s", desc = "Silent the terminal output"},
	{name = "--help", short = "-h", desc = "Show help message"},
}

New_Options :: [?]Flag {
	{name = "--no-git", desc = "Do not initialize a git repository"},
	{name = "--help", short = "-h", desc = "Show help message"},
}

Install_Options :: [?]Flag {
	{name = "--help", short = "-h", desc = "Show help message"},
}

Uninstall_Options :: [?]Flag {
	{
		name = "--dry-run",
		short = "-d",
		desc = "See what would happen without changing anything",
	},
	{name = "--help", short = "-h", desc = "Show help message"},
}

Clean_Options :: [?]Flag {
	{
		name = "--dry-run",
		short = "-d",
		desc = "See what would happen without changing anything",
	},
	{name = "--help", short = "-h", desc = "Show help message"},
}
