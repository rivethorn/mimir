#+private
package build

Collection :: struct {
	name: string,
	path: string,
}

Ols :: struct {
	collections: []Collection,
}
