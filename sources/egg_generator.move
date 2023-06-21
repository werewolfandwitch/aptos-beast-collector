
module beast_collector::egg_generator {    
    use std::bcs;
    use std::signer;    
    use std::string::{Self, String};    
    use aptos_framework::account;    
    use aptos_token::token::{Self};
    use beast_collector::acl::{Self};    
    use aptos_framework::coin;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::guid;
    use beast_collector::utils;

    const BURNABLE_BY_CREATOR: vector<u8> = b"TOKEN_BURNABLE_BY_CREATOR";    
    const BURNABLE_BY_OWNER: vector<u8> = b"TOKEN_BURNABLE_BY_OWNER";
    const TOKEN_PROPERTY_MUTABLE: vector<u8> = b"TOKEN_PROPERTY_MUTATBLE";    

    const FEE_DENOMINATOR: u64 = 100000;

    const ENOT_IN_ACL: u64 = 1;
    const EIS_TOP_LEVEL: u64 = 2;

    // collection name / info
    const EGG_COLLECTION_NAME:vector<u8> = b"W&W EGG";
    const COLLECTION_DESCRIPTION:vector<u8> = b"Werewolf and witch beast collector https://beast.werewolfandwitch.xyz/";

    const PROPERTY_HATCH_TIME: vector<u8> = b"W_HATCH_TIME"; 
    const PROPERTY_LEVEL: vector<u8> = b"W_RARITY"; // (Normal / Rare / Epic)

    struct EggManager has store, key {          
        signer_cap: account::SignerCapability,                 
        acl: acl::ACL,
        acl_events:EventHandle<AclAddEvent>,
    }

    struct AclAddEvent has drop, store {
        added: address,        
    }


    entry fun admin_withdraw<CoinType>(sender: &signer, amount: u64) acquires EggManager {
        let sender_addr = signer::address_of(sender);
        let resource_signer = get_resource_account_cap(sender_addr);                                
        let coins = coin::withdraw<CoinType>(&resource_signer, amount);                
        coin::deposit(sender_addr, coins);
    }

    fun get_resource_account_cap(minter_address : address) : signer acquires EggManager {
        let minter = borrow_global<EggManager>(minter_address);
        account::create_signer_with_capability(&minter.signer_cap)
    }    

    entry fun add_acl(sender: &signer, address_to_add:address) acquires EggManager  {                    
        let sender_addr = signer::address_of(sender);                
        let manager = borrow_global_mut<EggManager>(sender_addr);        
        acl::add(&mut manager.acl, address_to_add);
        event::emit_event(&mut manager.acl_events, AclAddEvent { 
            added: address_to_add,            
        });        
    }

    entry fun remove_acl(sender: &signer, address_to_remove:address) acquires TrainerManager  {                    
        let sender_addr = signer::address_of(sender);                
        let manager = borrow_global_mut<TrainerManager>(sender_addr);        
        acl::remove(&mut manager.acl, address_to_remove);        
    }
    
    // resource cab required 
    entry fun init(sender: &signer) acquires EggManager {
        let sender_addr = signer::address_of(sender);                
        let (resource_signer, signer_cap) = account::create_resource_account(sender, x"03");    
        token::initialize_token_store(&resource_signer);
        if(!exists<EggManager>(sender_addr)){            
            move_to(sender, EggManager {                
                signer_cap,  
                acl: acl::empty(),
                acl_events:account::new_event_handle<AclAddEvent>(sender)
            });
        };                
        
        let manager = borrow_global_mut<EggManager>(sender_addr);             
        acl::add(&mut manager.acl, sender_addr);
        event::emit_event(&mut manager.acl_events, AclAddEvent { 
            added: sender_addr,            
        });        
    }        

    entry fun mint_egg (
        sender: &signer,
        item_material_contract:address,               
        token_name: String,
    ) acquires EggManager {             
        let sender_address = signer::address_of(sender);
        let resource_signer = get_resource_account_cap(sender_address);                
        let resource_account_address = signer::address_of(&resource_signer);     
        let manager = borrow_global<EggManager>(sender_address);             
        acl::assert_contains(&manager.acl,sender_address);
        let mutability_config = &vector<bool>[ true, true, false, true, true ];        
        let token_data_id;

        if(!token::check_collection_exists(resource_account_address, string::utf8(EGG_COLLECTION_NAME))) {
            let mutate_setting = vector<bool>[ true, true, true ]; 
            let collection_uri = string::utf8(b"https://werewolfandwitch-beast-collection.s3.ap-northeast-2.amazonaws.com/trainer/1.png"); // TODO Egg pic
            token::create_collection(&resource_signer, 
                string::utf8(EGG_COLLECTION_NAME), 
                string::utf8(COLLECTION_DESCRIPTION), 
                collection_uri, 99999, mutate_setting);        
        };

        let guid = account::create_guid(&resource_signer);
        let uuid = guid::creation_num(&guid);        
        let random_idx = utils::random_with_nonce(sender_address, 36, uuid);                                        
        let idx_string = utils::to_string((random_idx as u128));
        let uri = string::utf8(b"https://werewolfandwitch-beast-collection.s3.ap-northeast-2.amazonaws.com/trainer/");         
        string::append(&mut uri, idx_string);
        string::append_utf8(&mut uri, b".png");
        if(!token::check_tokendata_exists(resource_account_address, string::utf8(EGG_COLLECTION_NAME), token_name)) {
            token_data_id = token::create_tokendata(
                &resource_signer,
                string::utf8(EGG_COLLECTION_NAME),
                token_name,
                string::utf8(COLLECTION_DESCRIPTION),
                99999,
                uri,
                item_material_contract, // royalty fee to                
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
            token_data_id = token::create_token_data_id(resource_account_address, string::utf8(EGG_COLLECTION_NAME), token_name);                    
        };                     
        let token_id = token::mint_token(&resource_signer, token_data_id, 1);
        token::opt_in_direct_transfer(sender, true);
        token::direct_transfer(&resource_signer, sender, token_id, 1);        
    }
    // burn and generate new egg
    // public fun breeding (
    //     receiver: &signer,
    //     auth: &signer,
    // ) acquires EggManager {                     
    // }    
}

