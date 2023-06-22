
module beast_collector::beast_generator {            
    use std::bcs;
    use std::signer;    
    use std::string::{Self, String};    
    use std::option::{Self};
    use aptos_std::table::{Self, Table};  
    use aptos_token::property_map::{Self};
    use aptos_token::token::{Self, TokenId};     
    use aptos_framework::coin;    
    use aptos_framework::event::{Self, EventHandle};
    use std::vector;
    use aptos_framework::account;    
    use beast_collector::utils;
    use beast_collector::acl::{Self};        

    const BURNABLE_BY_CREATOR: vector<u8> = b"TOKEN_BURNABLE_BY_CREATOR";    
    const BURNABLE_BY_OWNER: vector<u8> = b"TOKEN_BURNABLE_BY_OWNER";
    const TOKEN_PROPERTY_MUTABLE: vector<u8> = b"TOKEN_PROPERTY_MUTATBLE";    

    const FEE_DENOMINATOR: u64 = 100000;
    const WAR_COIN_DECIMAL:u64 = 100000000;   
    
    // collection name / info
    const BEAST_COLLECTION_NAME:vector<u8> = b"W&W Beast";    
    const COLLECTION_DESCRIPTION:vector<u8> = b"Werewolf and witch beast collector https://beast.werewolfandwitch.xyz/";
    // item property
    const ITEM_EXP: vector<u8> = b"W_EXP";
    const ITEM_LEVEL: vector<u8> = b"W_LEVEL";
    const ITEM_RARITY: vector<u8> = b"W_RARITY"; // very common(1),Common(2), Rare(3), Very Rare(4), Epic (5), Legendary(6), Mythic(7)
    const ITEM_EVO_STAGE: vector<u8> = b"W_EVO_STAGE";
    const ITEM_DUNGEON_TIME: vector<u8> = b"W_DUNGEON_TIME";
    const ITEM_BREEDING_TIME: vector<u8> = b"W_BREEDING";
    const ITEM_EVOLUTION_TIME: vector<u8> = b"W_EVOLUTION";
  
    const ENOT_CREATOR:u64 = 1;
    const ESAME_MATERIAL:u64 = 2;
    const ENOT_IN_RECIPE:u64 = 3;
    const ENOT_IN_ACL: u64 = 4;
    const EIS_TOP_LEVEL:u64 = 5;
    const ENOT_AUTHORIZED:u64 = 6;
    const ENO_SUFFICIENT_FUND:u64 = 7;

    struct BeastCollection has key {
        collections: Table<u64, Evolution>, // <Name of Item, Item Composition>        
    }

    struct Evolution has key, store, drop {
        stage_name_1: String,        
        stage_uri_1: String,
        stage_name_2: String,        
        stage_uri_2: String,
        stage_name_3: String,        
        stage_uri_3: String,
        story: String
    }

    struct AclAddEvent has drop, store {
        added: address,        
    }

    struct CollectionAdded has drop, store {
        material_1: String,        
        material_2: String,
        item: String,
    }
    

    struct BeastManager has store, key {          
        signer_cap: account::SignerCapability,
        acl: acl::ACL,
        maximum_beast_count:u64,
        acl_events:EventHandle<AclAddEvent>,
        token_minting_events: EventHandle<MintedEvent>,
        collection_add_events:EventHandle<CollectionAdded>,                                                  
    } 


    struct MintedEvent has drop, store {
        minted_item: token::TokenId,
        generated_time: u64
    }

    entry fun admin_withdraw<CoinType>(sender: &signer, amount: u64) acquires BeastManager {
        let sender_addr = signer::address_of(sender);
        let resource_signer = get_resource_account_cap(sender_addr);                                
        let coins = coin::withdraw<CoinType>(&resource_signer, amount);                
        coin::deposit(sender_addr, coins);
    }

    fun get_resource_account_cap(minter_address : address) : signer acquires BeastManager {
        let minter = borrow_global<BeastManager>(minter_address);
        account::create_signer_with_capability(&minter.signer_cap)
    }    

    entry fun add_acl(sender: &signer, address_to_add:address) acquires BeastManager  {                    
        let sender_addr = signer::address_of(sender);                
        let manager = borrow_global_mut<BeastManager>(sender_addr);        
        acl::add(&mut manager.acl, address_to_add);
        event::emit_event(&mut manager.acl_events, AclAddEvent { 
            added: address_to_add,            
        });        
    }

    entry fun remove_acl(sender: &signer, address_to_remove:address) acquires BeastManager  {                    
        let sender_addr = signer::address_of(sender);                
        let manager = borrow_global_mut<BeastManager>(sender_addr);        
        acl::remove(&mut manager.acl, address_to_remove);        
    }    
    // resource cab required 
    entry fun init<WarCoinType>(sender: &signer) acquires BeastManager{
        let sender_addr = signer::address_of(sender);                
        let (resource_signer, signer_cap) = account::create_resource_account(sender, x"05");    
        token::initialize_token_store(&resource_signer);
        if(!exists<BeastManager>(sender_addr)){            
            move_to(sender, BeastManager {                
                signer_cap,  
                acl: acl::empty(),
                maximum_beast_count: 0,
                acl_events:account::new_event_handle<AclAddEvent>(sender),
                token_minting_events: account::new_event_handle<MintedEvent>(sender),
                collection_add_events: account::new_event_handle<CollectionAdded>(sender),                                                  
            });
        };
        

        if(!coin::is_account_registered<WarCoinType>(signer::address_of(&resource_signer))){
            coin::register<WarCoinType>(&resource_signer);
        };        
        
        let manager = borrow_global_mut<BeastManager>(sender_addr);
        acl::add(&mut manager.acl, sender_addr);              
    }    

    entry fun add_collection (
        sender: &signer, beast_number: u64,
        stage_name_1: String, stage_uri_1: String, 
        stage_name_2: String, stage_uri_2: String, 
        stage_name_3: String, stage_uri_3: String, 
        story: String,
        ) acquires BeastCollection, BeastManager {
        let creator_address = signer::address_of(sender);
        let collections = borrow_global_mut<BeastCollection>(creator_address);
        let beast_manager = borrow_global_mut<BeastManager>(creator_address);
        beast_manager.maximum_beast_count = beast_manager.maximum_beast_count + 1;
        table::add(&mut collections.collections, beast_number, Evolution {
            stage_name_1,            
            stage_uri_1,
            stage_name_2, 
            stage_uri_2,
            stage_name_3,
            stage_uri_3,
            story: story
        });        
        // event::emit_event(&mut recieps.recipe_add_events, CollectionAdded { 
        //     material_1: material_token_name_1,        
        //     material_2: material_token_name_2,
        //     item: item_token_name,            
        // });        
    }

     entry fun remove_collection (
        sender: &signer, beast_number: u64, 
        ) acquires BeastCollection,BeastManager {  
        let creator_address = signer::address_of(sender);
        let collection = borrow_global_mut<BeastCollection>(creator_address);
        table::remove(&mut collection.collections, beast_number);                                                          
        let beast_manager = borrow_global_mut<BeastManager>(creator_address);
        beast_manager.maximum_beast_count = beast_manager.maximum_beast_count - 1;
    }

    public fun mint_beast (
        sender: &signer,auth: &signer, minter_address:address, beast_number:u64
    ) acquires BeastManager {    
        let auth_address = signer::address_of(auth);
        let manager = borrow_global<BeastManager>(minter_address);
        acl::assert_contains(&manager.acl, auth_address);                           
        let resource_signer = get_resource_account_cap(minter_address);                
        let resource_account_address = signer::address_of(&resource_signer);    
        let mutability_config = &vector<bool>[ true, true, true, true, true ];
        if(!token::check_collection_exists(resource_account_address, string::utf8(BEAST_COLLECTION_NAME))) {
            let mutate_setting = vector<bool>[ true, true, true ]; // TODO should check before deployment.
            let collection_uri = string::utf8(b"https://werewolfandwitch-beast-collection.s3.ap-northeast-2.amazonaws.com/beast/1.png");
            token::create_collection(&resource_signer, 
                string::utf8(BEAST_COLLECTION_NAME), 
                string::utf8(COLLECTION_DESCRIPTION), 
                collection_uri, 99999, mutate_setting);        
        };        
        let supply_count = &mut token::get_collection_supply(resource_account_address, string::utf8(BEAST_COLLECTION_NAME));        
        let new_supply = option::extract<u64>(supply_count);                        
        let i = 0;
        let token_name = string::utf8(BEAST_COLLECTION_NAME);
        while (i <= new_supply) {
            let new_token_name = string::utf8(BEAST_COLLECTION_NAME);                
            string::append_utf8(&mut new_token_name, b" #");
            let count_string = utils::to_string((i as u128));
            string::append(&mut new_token_name, count_string);                                
            if(!token::check_tokendata_exists(resource_account_address, string::utf8(BEAST_COLLECTION_NAME), new_token_name)) {
                token_name = new_token_name;                
                break
            };
            i = i + 1;
        };                  
        let collection_uri = string::utf8(b"https://werewolfandwitch-beast-collection.s3.ap-northeast-2.amazonaws.com/beast/1.png");                
        let token_data_id = token::create_tokendata(
                &resource_signer,
                string::utf8(BEAST_COLLECTION_NAME),
                token_name,
                string::utf8(COLLECTION_DESCRIPTION),
                1, // 1 maximum for NFT 
                collection_uri, // TODO should be changed. 
                minter_address, // royalty fee to                
                FEE_DENOMINATOR,
                4000, // TODO:: should be check later::royalty_points_numerator
                // we don't allow any mutation to the token
                token::create_token_mutability_config(mutability_config),
                // type
                vector<String>[string::utf8(BURNABLE_BY_OWNER), string::utf8(BURNABLE_BY_CREATOR), string::utf8(TOKEN_PROPERTY_MUTABLE)
                    ],  // property_keys                
                vector<vector<u8>>[bcs::to_bytes<bool>(&true), bcs::to_bytes<bool>(&true), bcs::to_bytes<bool>(&true)
                    ],  // values 
                vector<String>[string::utf8(b"bool"),string::utf8(b"bool"), string::utf8(b"bool")
                    ],
        );
        let token_id = token::mint_token(&resource_signer, token_data_id, 1);
        token::opt_in_direct_transfer(sender, true);
        token::direct_transfer(&resource_signer, sender, token_id, 1);        
    }       
}
