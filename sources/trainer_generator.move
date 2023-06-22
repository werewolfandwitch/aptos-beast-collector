module beast_collector::trainer_generator {        
    use std::error;
    use std::bcs;
    use std::signer;    
    use std::string::{Self, String};    
    use std::option::{Self};
    use aptos_std::table::{Self, Table};  
    use aptos_token::property_map::{Self};
    use aptos_token::token::{Self}; 
    use aptos_framework::coin;    
    use aptos_framework::event::{Self, EventHandle};
    use std::vector;
    use aptos_framework::account;    
    use beast_collector::utils;
    use beast_collector::acl::{Self};    
    use aptos_framework::guid;

    const BURNABLE_BY_CREATOR: vector<u8> = b"TOKEN_BURNABLE_BY_CREATOR";    
    const BURNABLE_BY_OWNER: vector<u8> = b"TOKEN_BURNABLE_BY_OWNER";
    const TOKEN_PROPERTY_MUTABLE: vector<u8> = b"TOKEN_PROPERTY_MUTATBLE";    

    const FEE_DENOMINATOR: u64 = 100000;
    const WAR_COIN_DECIMAL:u64 = 100000000;   
    
    // collection name / info
    const TRAINER_COLLECTION_NAME:vector<u8> = b"W&W Beast Collector";    
    const COLLECTION_DESCRIPTION:vector<u8> = b"Werewolf and witch beast collector https://beast.werewolfandwitch.xyz/";
    // item property
    
    const PROPERTY_EXP: vector<u8> = b"W_EXP"; // 100 MAX, 100 EXP => 1 LEVEL UP
    const PROPERTY_LEVEL: vector<u8> = b"W_LEVEL"; // 5 LEVEL MAX, 5 LEVEL with 100 EXP can upgrade GRADE of trainer
    const PROPERTY_NEXT_EXPLORATION_TIME: vector<u8> = b"W_NEXT_EXPLORATION_TIME";
    const PROPERTY_GRADE: vector<u8> = b"W_GRADE"; // Trainer(1) / Pro Trainer(2) / Semi champion(3) / World champion(4) / Master (5) 
  

    struct AclAddEvent has drop, store {
        added: address,        
    }
    
    struct TrainerManager has store, key {          
        signer_cap: account::SignerCapability,
        acl: acl::ACL,
        acl_events:EventHandle<AclAddEvent>,                                   
    } 

    struct ItemEvents has key {
        token_minting_events: EventHandle<MintedEvent>,        
    }

    struct MintedEvent has drop, store {
        minted_item: token::TokenId,
        generated_time: u64
    }

    entry fun admin_withdraw<CoinType>(sender: &signer, amount: u64) acquires TrainerManager {
        let sender_addr = signer::address_of(sender);
        let resource_signer = get_resource_account_cap(sender_addr);                                
        let coins = coin::withdraw<CoinType>(&resource_signer, amount);                
        coin::deposit(sender_addr, coins);
    }

    fun get_resource_account_cap(minter_address : address) : signer acquires TrainerManager {
        let minter = borrow_global<TrainerManager>(minter_address);
        account::create_signer_with_capability(&minter.signer_cap)
    }    

    entry fun add_acl(sender: &signer, address_to_add:address) acquires TrainerManager  {                    
        let sender_addr = signer::address_of(sender);                
        let manager = borrow_global_mut<TrainerManager>(sender_addr);        
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
    entry fun init<WarCoinType>(sender: &signer) acquires TrainerManager{
        let sender_addr = signer::address_of(sender);                
        let (resource_signer, signer_cap) = account::create_resource_account(sender, x"01");    
        token::initialize_token_store(&resource_signer);
        if(!exists<TrainerManager>(sender_addr)){            
            move_to(sender, TrainerManager {                
                signer_cap,  
                acl: acl::empty(),
                acl_events:account::new_event_handle<AclAddEvent>(sender)
            });
        };
        if(!coin::is_account_registered<WarCoinType>(signer::address_of(&resource_signer))){
            coin::register<WarCoinType>(&resource_signer);
        };
        let mutate_setting = vector<bool>[ true, true, true ]; // TODO should check before deployment.
        let collection_uri = string::utf8(b"https://werewolfandwitch-beast-collection.s3.ap-northeast-2.amazonaws.com/trainer/1.png");
        token::create_collection(&resource_signer, 
            string::utf8(TRAINER_COLLECTION_NAME), 
            string::utf8(COLLECTION_DESCRIPTION), collection_uri, 99999, mutate_setting);                
        let manager = borrow_global_mut<TrainerManager>(sender_addr);
        acl::add(&mut manager.acl, sender_addr);              
    }    
    // trainer url: https://werewolfandwitch-beast-collection.s3.ap-northeast-2.amazonaws.com/trainer/0.png
    public fun mint_trainer (
        receiver: &signer, auth: &signer, minter_address:address, grade: u64
    ) acquires TrainerManager {    
        let auth_address = signer::address_of(auth);
        let manager = borrow_global<TrainerManager>(minter_address);
        acl::assert_contains(&manager.acl, auth_address);                           
        let resource_signer = get_resource_account_cap(minter_address);                
        let resource_account_address = signer::address_of(&resource_signer);    
        let mutability_config = &vector<bool>[ false, true, true, true, true ];
        if(!token::check_collection_exists(resource_account_address, string::utf8(TRAINER_COLLECTION_NAME))) {
            let mutate_setting = vector<bool>[ true, true, true ]; 
            let collection_uri = string::utf8(b"https://werewolfandwitch-beast-collection.s3.ap-northeast-2.amazonaws.com/trainer/1.png");
            token::create_collection(&resource_signer, string::utf8(TRAINER_COLLECTION_NAME), string::utf8(COLLECTION_DESCRIPTION), collection_uri, 99999, mutate_setting);        
        };
        
        let supply_count = &mut token::get_collection_supply(resource_account_address, string::utf8(TRAINER_COLLECTION_NAME));        
        let new_supply = option::extract<u64>(supply_count);                        
        let i = 0;
        let token_name = string::utf8(TRAINER_COLLECTION_NAME);
        while (i <= new_supply) {
            let new_token_name = string::utf8(TRAINER_COLLECTION_NAME);
            string::append_utf8(&mut new_token_name, b" #");
            let count_string = utils::to_string((i as u128));
            string::append(&mut new_token_name, count_string);                                
            if(!token::check_tokendata_exists(resource_account_address, string::utf8(TRAINER_COLLECTION_NAME), new_token_name)) {
                token_name = new_token_name;                
                break
            };
            i = i + 1;
        };                                  
        let guid = account::create_guid(&resource_signer);
        let uuid = guid::creation_num(&guid);        
        let random_idx = utils::random_with_nonce(auth_address, 36, uuid);                                        
        let idx_string = utils::to_string((random_idx as u128));
        let uri = string::utf8(b"https://werewolfandwitch-beast-collection.s3.ap-northeast-2.amazonaws.com/trainer/");         
        string::append(&mut uri, idx_string);
        string::append_utf8(&mut uri, b".png");
        // const PROPERTY_EXP: vector<u8> = b"W_EXP"; // 100 MAX, 100 EXP => 1 LEVEL UP
        // const PROPERTY_LEVEL: vector<u8> = b"W_LEVEL"; // 5 LEVEL MAX, 5 LEVEL with 100 EXP can upgrade GRADE of trainer
        // const PROPERTY_NEXT_EXPLORATION_TIME: vector<u8> = b"W_NEXT_EXPLORATION_TIME";
        // const PROPERTY_GRADE: vector<u8> = b"W_GRADE"; // Trainer(1) / Pro Trainer(2) / Semi champion(3) / World champion(4) / Master (5) 
        let token_data_id = token::create_tokendata(
                &resource_signer,
                string::utf8(TRAINER_COLLECTION_NAME),
                token_name,
                string::utf8(COLLECTION_DESCRIPTION),
                1, // 1 maximum for NFT 
                uri, 
                minter_address, // royalty fee to                
                FEE_DENOMINATOR,
                4000, //
                // we don't allow any mutation to the token
                token::create_token_mutability_config(mutability_config),
                // type
                vector<String>[string::utf8(BURNABLE_BY_OWNER), string::utf8(BURNABLE_BY_CREATOR), string::utf8(TOKEN_PROPERTY_MUTABLE), 
                    string::utf8(PROPERTY_EXP), 
                    string::utf8(PROPERTY_LEVEL), 
                    string::utf8(PROPERTY_NEXT_EXPLORATION_TIME), 
                    string::utf8(PROPERTY_GRADE)],  // property_keys                
                vector<vector<u8>>[bcs::to_bytes<bool>(&true), bcs::to_bytes<bool>(&true), bcs::to_bytes<bool>(&true),
                    bcs::to_bytes<u64>(&0),
                    bcs::to_bytes<u64>(&1),
                    bcs::to_bytes<u64>(&0),
                    bcs::to_bytes<u64>(&grade)
                ],  // values 
                vector<String>[string::utf8(b"bool"),string::utf8(b"bool"), string::utf8(b"bool"),
                    string::utf8(b"u64"),
                    string::utf8(b"u64"),
                    string::utf8(b"u64"),
                    string::utf8(b"u64")],
        );
        let token_id = token::mint_token(&resource_signer, token_data_id, 1);
        token::opt_in_direct_transfer(receiver, true);
        token::direct_transfer(&resource_signer, receiver, token_id, 1);        
    }
          
}