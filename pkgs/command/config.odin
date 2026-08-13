#+private
package command

Collection :: struct {
	name: string,
	path: string,
}

Profile :: struct {
	name:         string,
	os:           string,
	arch:         string,
	checker_path: []string,
	exclude_path: []string,
}

Ols :: struct {
	schema:                                  string `json:"$schema"`,
	collections:                             []Collection,
	thread_pool_count:                       int,
	enable_checker_only_saved:               bool,
	enable_checker_workspace_diagnostics:    bool,
	enable_semantic_tokens:                  bool,
	enable_document_symbols:                 bool,
	enable_format:                           bool,
	enable_hover:                            bool,
	enable_procedure_context:                bool,
	enable_inlay_hints_params:               bool,
	enable_inlay_hints_default_params:       bool,
	enable_inlay_hints_implicit_return:      bool,
	enable_inlay_hints_optional_result:      bool,
	enable_procedure_snippet:                bool,
	enable_auto_import:                      bool,
	enable_add_import_to_bottom:             bool,
	enable_references:                       bool,
	enable_document_highlights:              bool,
	enable_completion_matching:              bool,
	enable_fake_methods:                     bool,
	enable_overload_resolution:              bool,
	enable_document_links:                   bool,
	enable_comp_lit_signature_help:          bool,
	enable_comp_lit_signature_help_use_docs: bool,
	enable_code_action_invert_if:            bool,
	struct_fields_underscore_visibility:     string,
	disable_parser_errors:                   bool,
	verbose:                                 bool,
	file_log:                                bool,
	odin_command:                            string,
	odin_root_override:                      string,
	checker_args:                            string,
	checker_skip_packages:                   []string,
	completion_exclude_attributes:           []string,
	profile:                                 string,
	profiles:                                []Profile,
}
