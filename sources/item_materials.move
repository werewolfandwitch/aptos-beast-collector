
module item_gen::item_materials {    
    use std::bcs;
    use std::signer;    
    use std::string::{Self, String};    
    use aptos_framework::account;    
    use aptos_token::token::{Self};
    use item_gen::acl::{Self};    
    use aptos_framework::coin;
    use aptos_framework::event::{Self, EventHandle};

    const BURNABLE_BY_CREATOR: vector<u8> = b"TOKEN_BURNABLE_BY_CREATOR";    
    const BURNABLE_BY_OWNER: vector<u8> = b"TOKEN_BURNABLE_BY_OWNER";
    const TOKEN_PROPERTY_MUTABLE: vector<u8> = b"TOKEN_PROPERTY_MUTATBLE";    

    const FEE_DENOMINATOR: u64 = 100000;

    const ENOT_IN_ACL: u64 = 1;
    const EIS_TOP_LEVEL: u64 = 2;

    // collection name / info
    const ITEM_MATERIAL_COLLECTION_NAME:vector<u8> = b"W&W ITEM MATERIAL";
    const COLLECTION_DESCRIPTION:vector<u8> = b"These materials are used for item synthesis in W&W";

    // property for game

    const MATERIAL_A: vector<u8> = b"Glimmering Crystals";
    const MATERIAL_B: vector<u8> = b"Ethereal Essence";
    const MATERIAL_C: vector<u8> = b"Dragon Scale";
    const MATERIAL_D: vector<u8> = b"Celestial Dust";
    const MATERIAL_E: vector<u8> = b"Essence of the Ancients";
    const MATERIAL_F: vector<u8> = b"Phoenix Feather";
    const MATERIAL_G: vector<u8> = b"Moonstone Ore";
    const MATERIAL_H: vector<u8> = b"Enchanted Wood";
    const MATERIAL_I: vector<u8> = b"Elemental Essence";

    //!! Item material description

    // Glimmering Crystals: These rare and radiant crystals are found deep within ancient caves. They emit a soft, enchanting glow and are a key ingredient in crafting powerful magical artifacts.
    // https://werewolfandwitch-mainnet.s3.ap-northeast-2.amazonaws.com/item-material-image/glimmering_crystals.png

    // Ethereal Essence: A ghostly substance that can only be collected from the spirits of ethereal beings. It possesses a faint shimmer and is often used in creating ethereal weapons or enchanted armor.
    // https://werewolfandwitch-mainnet.s3.ap-northeast-2.amazonaws.com/item-material-image/ethereal_essence.png

    // Dragon Scale: The scales of mighty dragons, known for their durability and resistance to fire. Dragon scales are highly sought after for forging powerful armor and shields that provide exceptional protection against elemental attacks.
    // https://werewolfandwitch-mainnet.s3.ap-northeast-2.amazonaws.com/item-material-image/dragon_scale.png

    // Celestial Dust: A fine, shimmering powder collected from fallen stars. Celestial dust is imbued with celestial magic and can be used to enchant weapons and create celestial-themed jewelry.
    // https://werewolfandwitch-mainnet.s3.ap-northeast-2.amazonaws.com/item-material-image/celestial_dust.png

    // Essence of the Ancients: A rare substance extracted from ancient ruins or the remnants of ancient creatures. It contains potent magical energy and is often used in creating legendary artifacts or enhancing existing ones.
    // https://werewolfandwitch-mainnet.s3.ap-northeast-2.amazonaws.com/item-material-image/essence_of_the_ancients.png

    // Phoenix Feather: Feathers shed by phoenixes, mythical birds of fire and rebirth. These feathers possess incredible heat resistance and are used in crafting flame-resistant equipment or items that grant temporary fire-based abilities.
    // https://werewolfandwitch-mainnet.s3.ap-northeast-2.amazonaws.com/item-material-image/phoenix_feather.png

    // Moonstone Ore: A precious gemstone that can only be mined during a full moon. Moonstone ore has lunar magic infused within it and is used to create enchanted jewelry or enhance magical staves.
    // https://werewolfandwitch-mainnet.s3.ap-northeast-2.amazonaws.com/item-material-image/moonstone_ore.png

    // Enchanted Wood: Wood harvested from mystical forests inhabited by sentient trees. This wood retains magical properties and is ideal for crafting wands, bows, and staves.
    // https://werewolfandwitch-mainnet.s3.ap-northeast-2.amazonaws.com/item-material-image/enchanted_wood.png

    // Kraken Ink: An ink harvested from the mighty krakens of the deep sea. It possesses a dark, iridescent sheen and is used in the creation of powerful spell scrolls or to inscribe protective runes.
    // https://werewolfandwitch-mainnet.s3.ap-northeast-2.amazonaws.com/item-material-image/kraken_ink.png

    // Elemental Essence: Essence drawn from the elemental planes. Each elemental essence (fire, water, earth, air) grants specific properties and can be used in alchemy or enchanting to imbue items with elemental attributes.
    // https://werewolfandwitch-mainnet.s3.ap-northeast-2.amazonaws.com/item-material-image/elemental_essence.png

    struct ItemMaterialManager has store, key {          
        signer_cap: account::SignerCapability,                 
        acl: acl::ACL,
        acl_events:EventHandle<AclAddEvent>,
    }

    struct AclAddEvent has drop, store {
        added: address,        
    }


    entry fun admin_withdraw<CoinType>(sender: &signer, amount: u64) acquires ItemMaterialManager {
        let sender_addr = signer::address_of(sender);
        let resource_signer = get_resource_account_cap(sender_addr);                                
        let coins = coin::withdraw<CoinType>(&resource_signer, amount);                
        coin::deposit(sender_addr, coins);
    }

    fun get_resource_account_cap(minter_address : address) : signer acquires ItemMaterialManager {
        let minter = borrow_global<ItemMaterialManager>(minter_address);
        account::create_signer_with_capability(&minter.signer_cap)
    }    

    entry fun add_acl(sender: &signer, addr:address) acquires ItemMaterialManager  {                    
        let sender_addr = signer::address_of(sender);                
        let manager = borrow_global_mut<ItemMaterialManager>(sender_addr);        
        acl::add(&mut manager.acl, sender_addr);
        event::emit_event(&mut manager.acl_events, AclAddEvent { 
            added: addr,            
        });        
    }

    fun is_in_acl(sender_addr:address) : bool acquires ItemMaterialManager {
        let manager = borrow_global<ItemMaterialManager>(sender_addr);        
        acl::contains(&manager.acl, sender_addr)
    }
    // resource cab required 
    entry fun init(sender: &signer,collection_uri: String) acquires ItemMaterialManager {
        let sender_addr = signer::address_of(sender);                
        let (resource_signer, signer_cap) = account::create_resource_account(sender, x"02");    
        token::initialize_token_store(&resource_signer);
        if(!exists<ItemMaterialManager>(sender_addr)){            
            move_to(sender, ItemMaterialManager {                
                signer_cap,  
                acl: acl::empty(),
                acl_events:account::new_event_handle<AclAddEvent>(sender)
            });
        };                
        let mutate_setting = vector<bool>[ true, true, true ]; // TODO should check before deployment.
        token::create_collection(&resource_signer, 
            string::utf8(ITEM_MATERIAL_COLLECTION_NAME), 
            string::utf8(COLLECTION_DESCRIPTION), collection_uri, 9999, mutate_setting);        
        let manager = borrow_global_mut<ItemMaterialManager>(sender_addr);             
        acl::add(&mut manager.acl, sender_addr);
        event::emit_event(&mut manager.acl_events, AclAddEvent { 
            added: sender_addr,            
        });        
    }        

    entry fun mint_item_material_admin (
        sender: &signer,         
        token_name: String,         
        description:String, 
        collection_uri:String, max_amount:u64, amount:u64
    ) acquires ItemMaterialManager {             
        let sender_address = signer::address_of(sender);
        let resource_signer = get_resource_account_cap(sender_address);                
        let resource_account_address = signer::address_of(&resource_signer);     
        let manager = borrow_global<ItemMaterialManager>(sender_address);             
        acl::assert_contains(&manager.acl,sender_address);                
        let mutability_config = &vector<bool>[ true, true, false, true, true ];        
        let token_data_id;
        if(!token::check_tokendata_exists(resource_account_address, string::utf8(ITEM_MATERIAL_COLLECTION_NAME), token_name)) {
            token_data_id = token::create_tokendata(
                &resource_signer,
                string::utf8(ITEM_MATERIAL_COLLECTION_NAME),
                token_name,
                description,
                max_amount, // 1 for NFT
                collection_uri,
                sender_address, // royalty fee to                
                FEE_DENOMINATOR,
                4000,
                // we don't allow any mutation to the token
                token::create_token_mutability_config(mutability_config),
                // type
                vector<String>[string::utf8(BURNABLE_BY_OWNER),string::utf8(TOKEN_PROPERTY_MUTABLE)],  // property_keys                
                vector<vector<u8>>[bcs::to_bytes<bool>(&true),bcs::to_bytes<bool>(&false)],  // values 
                vector<String>[string::utf8(b"bool"),string::utf8(b"bool")],
            );            
        } else {
            token_data_id = token::create_token_data_id(resource_account_address, string::utf8(ITEM_MATERIAL_COLLECTION_NAME),token_name);                    
        };                     
        let token_id = token::mint_token(&resource_signer, token_data_id, amount);
        token::opt_in_direct_transfer(sender, true);
        token::direct_transfer(&resource_signer, sender, token_id, amount);        
    }

    public fun mint_item_material (
        sender: &signer,         
        token_name: String,
    ) acquires ItemMaterialManager {             
        let sender_address = signer::address_of(sender);
        let resource_signer = get_resource_account_cap(sender_address);                
        let resource_account_address = signer::address_of(&resource_signer);     
        let manager = borrow_global<ItemMaterialManager>(sender_address);             
        acl::assert_contains(&manager.acl,sender_address);                
        let mutability_config = &vector<bool>[ true, true, false, true, true ];        
        let token_data_id;
        if(!token::check_tokendata_exists(resource_account_address, string::utf8(ITEM_MATERIAL_COLLECTION_NAME), token_name)) {
            token_data_id = token::create_tokendata(
                &resource_signer,
                string::utf8(ITEM_MATERIAL_COLLECTION_NAME),
                token_name,
                description,
                9999, // 1 for NFT
                collection_uri,
                sender_address, // royalty fee to                
                FEE_DENOMINATOR,
                4000,
                // we don't allow any mutation to the token
                token::create_token_mutability_config(mutability_config),
                // type
                vector<String>[string::utf8(BURNABLE_BY_OWNER),string::utf8(TOKEN_PROPERTY_MUTABLE)],  // property_keys                
                vector<vector<u8>>[bcs::to_bytes<bool>(&true),bcs::to_bytes<bool>(&false)],  // values 
                vector<String>[string::utf8(b"bool"),string::utf8(b"bool")],
            );            
        } else {
            token_data_id = token::create_token_data_id(resource_account_address, string::utf8(ITEM_MATERIAL_COLLECTION_NAME),token_name);                    
        };                     
        let token_id = token::mint_token(&resource_signer, token_data_id, 1);
        token::opt_in_direct_transfer(sender, true);
        token::direct_transfer(&resource_signer, sender, token_id, 1);        
    }    
}

