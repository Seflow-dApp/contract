// Minimal FungibleTokenMetadataViews stub for linter compatibility

access(all) contract FungibleTokenMetadataViews {
    
    access(all) struct FTDisplay {
        access(all) let name: String
        access(all) let symbol: String
        access(all) let description: String
        
        init(name: String, symbol: String, description: String) {
            self.name = name
            self.symbol = symbol
            self.description = description
        }
    }
}