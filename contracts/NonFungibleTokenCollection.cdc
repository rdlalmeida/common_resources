/*
    This interface complements the NonFungibleTokenSimple in the sense that
    it implements a Collection resource used to store the NFTs defined in
    that other interface. The idea here is to establish Collections that 
    can store different types of NFTs. Technically, I think I can establish
    this mechanic with the NonFungibleToken interface alone, but that means
    that I need to establish Collection and all the functions in each of the
    NFT contracts, which I think it may be a bit dangerous.
    
    Is this a good idea? Does it works?
    I don't know, hence why I'm trying
    
    @rdlalmeida 07/02/2023
*/

// First main difference: this interface needs to import the Token exclusive one to set up the resources and such. This may be a limiting factor. Or not. We shall see...
import NonFungibleTokenSimple from "./NonFungibleTokenSimple.cdc"

pub contract interface NonFungibleTokenCollection {
    /*
        TODO: Is it a good idea to keep the same variable name? Or any of the other interfaces
        and resources?
        For sake of consistency, I'm going to keep the same names for now.
        But I need to revisit this sometime later.
    */ 
    
    // Total amount of tokens in the collection. As opposed to the original NonFungibleToken,
    // this parameter accounts for all tokens in the collection, potentially from different 
    // types.
    pub var totalSupply: UInt64

    // Event emitted when the NFT contract is initialized
    pub event ContractInitialized()

    // Event for when a token is withdraw. Because I've changed the id type of the base NFT, this function receives a String as an ID now
    pub event Withdraw(id: String, from: Address?)

    // Event for when a token is deposited, with the id switched to a String as before.
    pub event Deposit(id: String, to: Address?)

    // Now for the Provider and Receiver interfaces. In this case, they are pretty much the same as the original ones. The deposit and retrival is type independent, in principle.
    // Time will tell if I'm right
    pub resource interface Provider {
        // Withdraw removes an NFT from the Collection and moves to the calller. NOTE: These functions accept an return an NFT that follows the
        // NonFungibleTokenSimple interface defined before. Because of the new (and slightly more complicated, I have to assume) paradigm, the id used to retrieve/deposit the NFT
        // is now a String that needs to conform to whatever id building rules the contract developer establishes. Hopefully all of this can be abstracted in a Smart Contract
        // to prevent regular users from having to build complex Strings just to retrieve an NFT 
        pub fun withdraw(withdrawID: String): @NonFungibleTokenSimple.NFT {
            post {
                result.id == withdrawID: "The ID of the withdraw token must be the same as the requested ID"
            }
        }
    }

    // Interface to mediate deposits to the Collection
    pub resource interface Receiver {
        // Deposit takes an NFT as an argument as adds it to the Collection. Again, the NFT type does not seems to be relevant so far
        pub fun deposit(token: @NonFungibleTokenSimple.NFT)
    }

    // Now for the main interface
    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleTokenSimple.NFT)
        pub fun getIDs(): [String]
        pub fun borrowNFT(id: String): &NonFungibleTokenSimple.NFT
    }

    /*
        TODO 1: Create a function to retrieve an array of Strings with all the NFT types identified in the Collection:
            getAllNFTTypes(): [String]

        TODO 2: Create a function to retrive histogram data regarding the number of NFTs per type in the Collection:
            getNFTHistogram(): {String: UInt64}, where:
                String - NFT type, as a String obviously
                UInt64 - Number of NFTs counted in the Collection for that type
        
        TODO 3: Shall I add a new dictionary to this contract to keep track of how many NFT this collection has per type?
        The Deposit function becomes a bit more complicated, but it seems a good idea and simplifies greatly the previous TODO.
            Think about it Ricardo!
    */

    // Requirements for the concrete resource type, adapted to the new isolate NFT interface, to be declared in the implementing contract
    pub resource Collection: Provider, Receiver, CollectionPublic {
        // Dictionary to hold the NFTs in the Collection, again, with nothing that limits the NFT type so far
        pub var ownedNFTs: @{String: NonFungibleTokenSimple.NFT}

        // Withdraw removes an NFT, regardless of the type, even though it is somewhat explicit in the id to provide
        pub fun withdraw(withdrawID: String): @NonFungibleTokenSimple.NFT

        // Deposit takes an NFT and adds it to the Collection dictionary. Any Cadence developer worth his salt should be able to
        // create logic to add the token into the proper position in the dicionary
        pub fun deposit(token: @NonFungibleTokenSimple.NFT)

        // getIDs returns an array of the IDs that are in the collection. So far is just a simple array with all the NFT types, concatenated with some uuids (hopefully)
        pub fun getIDs(): [String]

        // Returns a borrowed reference to an NFT in the Collection so that the caller can read data and call methods from it
        pub fun borrowNFT(id: String): &NonFungibleTokenSimple.NFT {
            pre {
                self.ownedNFTs[id] != nil: "NFT with id '".concat(id).concat("' does not exists in the Collection!")
            }
        }
    }

    // createEmptyCollection creates an empty Collection and returns it to the caller so that they can own NFTs. Nothing else to add to this one.
    pub fun createEmptyCollection(): @Collection {
        post {
            result.getIDs().length == 0: "The created Collection must be empty! This one has ".concat(result.getIDs().length.toString()).concat(" in it already!")
        }
    }

}