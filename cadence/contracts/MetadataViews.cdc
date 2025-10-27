// Minimal MetadataViews stub for linter compatibility

access(all) contract MetadataViews {
    
    access(all) resource interface Resolver {
        access(all) fun getViews(): [Type]
        access(all) fun resolveView(_ view: Type): AnyStruct?
    }
}