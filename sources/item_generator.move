
module nft_war::item_generator {    
    use std::bcs;
    use std::signer;    
    use std::string::{Self, String};    
    
    use aptos_token::token::{Self};    

    const BURNABLE_BY_CREATOR: vector<u8> = b"TOKEN_BURNABLE_BY_CREATOR";    
    const BURNABLE_BY_OWNER: vector<u8> = b"TOKEN_BURNABLE_BY_OWNER";
    const TOKEN_PROPERTY_MUTABLE: vector<u8> = b"TOKEN_PROPERTY_MUTATBLE";    

    const FEE_DENOMINATOR: u64 = 100000;
    

    // collection name / info
    const ITEM_MATERIAL_COLLECTION_NAME:vector<u8> = b"W&W ITEM";
    const COLLECTION_DESCRIPTION:vector<u8> = b"these weapons can be equipped by characters in W&W";

    // property for game

    const MATERIAL_A: vector<u8> = b"Arcane Emberstaff"; // staff
    const MATERIAL_B: vector<u8> = b"Dawnbreaker Blade"; // sword
    const MATERIAL_C: vector<u8> = b"Seraphic Saber";  // sword
    const MATERIAL_D: vector<u8> = b"Phoenixfire Scepter";  // staff
     
    
    
    entry fun create_collection (
        sender: &signer,                
        collection_uri: String, maximum_supply: u64, mutate_setting: vector<bool>
        ) {                                             
        token::create_collection(sender, string::utf8(ITEM_MATERIAL_COLLECTION_NAME), string::utf8(COLLECTION_DESCRIPTION), collection_uri, maximum_supply, mutate_setting);
    }

    entry fun mint_item (
        sender: &signer, token_name: String, royalty_points_numerator:u64, collection_uri:String, max_amount:u64, amount:u64
    ) {        
        let creator_address = signer::address_of(sender);        
        let mutability_config = &vector<bool>[ true, true, false, true, true ];              
        let token_data_id = token::create_tokendata(
                sender,
                string::utf8(ITEM_MATERIAL_COLLECTION_NAME),
                token_name,
                string::utf8(COLLECTION_DESCRIPTION),
                max_amount, // 1 maximum for NFT 
                collection_uri,
                creator_address, // royalty fee to                
                FEE_DENOMINATOR,
                royalty_points_numerator,
                // we don't allow any mutation to the token
                token::create_token_mutability_config(mutability_config),
                // type
                vector<String>[string::utf8(BURNABLE_BY_OWNER),string::utf8(TOKEN_PROPERTY_MUTABLE)],  // property_keys                
                vector<vector<u8>>[bcs::to_bytes<bool>(&true),bcs::to_bytes<bool>(&false)],  // values 
                vector<String>[string::utf8(b"bool"),string::utf8(b"bool")],
        );
        let token_id = token::mint_token(sender, token_data_id, amount);
        token::opt_in_direct_transfer(sender, true);
        token::direct_transfer(sender, sender, token_id, 1);        
    }

    public fun synthesis () {

    }


}

