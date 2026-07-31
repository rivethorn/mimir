package build

@(private)
Build_Config :: struct {
	name, path, output: string,
	release, silent:    bool,
}

