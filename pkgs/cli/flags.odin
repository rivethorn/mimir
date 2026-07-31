package cli

@(private = "file")
Flag :: struct {
	name, short, desc: string,
}

Flags :: [?]Flag {
	{name = "build", short = "b", desc = "Compile the current package"},
	{name = "new", desc = "Create a new Odin project"},
	{name = "version", desc = "Show Mimir's version"},
}

