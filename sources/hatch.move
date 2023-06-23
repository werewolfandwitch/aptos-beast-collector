
module beast_collector::hatch {
    
    use std::signer;    
    use std::error;
    use aptos_framework::timestamp;    
    use aptos_framework::coin::{Self};    
    use aptos_framework::event::{Self, EventHandle};        
    use aptos_framework::account;    
    use aptos_framework::guid;
    use std::string::{Self, String};    
    use aptos_token::token::{Self, TokenId};     
    use aptos_token::property_map::{Self};    

    use beast_collector::utils;
    use beast_collector::trainer_generator;    

    const ENOT_AUTHORIZED:u64 = 0;    

    const EGG_COLLECTION_NAME:vector<u8> = b"W&W EGG";

    const PROPERTY_RARITY: vector<u8> = b"W_RARITY"; // (Common(1) / Rare(2) / Epic (3))

    struct Hatch has store, key {          
        signer_cap: account::SignerCapability,        
    }    

    entry fun admin_withdraw<CoinType>(sender: &signer, amount: u64) acquires Hatch {
        let sender_addr = signer::address_of(sender);
        let resource_signer = get_resource_account_cap(sender_addr);                                
        let coins = coin::withdraw<CoinType>(&resource_signer, amount);                
        coin::deposit(sender_addr, coins);
    }

    fun get_resource_account_cap(minter_address : address) : signer acquires Hatch {
        let launchpad = borrow_global<Hatch>(minter_address);
        account::create_signer_with_capability(&launchpad.signer_cap)
    }

    entry fun init(sender: &signer) {
        let sender_addr = signer::address_of(sender);                
        let (resource_signer, signer_cap) = account::create_resource_account(sender, x"02");        
        if(!exists<Hatch>(sender_addr)){            
            move_to(sender, Hatch {                
                signer_cap,                
            });
        };        
    } 

    entry fun hatch (
        receiver: &signer, hatch_address:address, egg_token_name:String, egg_creator:address, property_version:u64
    ) acquires Hatch {                  
        assert!(egg_creator == @egg_creator, error::permission_denied(ENOT_AUTHORIZED));
        let receiver_addr = signer::address_of(receiver);
        let resource_signer = get_resource_account_cap(hatch_address);
        let token_id = token::create_token_id_raw(egg_creator, string::utf8(EGG_COLLECTION_NAME), egg_token_name, property_version);        
        let pm = token::get_property_map(signer::address_of(receiver), token_id);        
        let egg_rarity = property_map::read_u64(&pm, &string::utf8(PROPERTY_RARITY));
        assert!(egg_rarity > 0 && egg_rarity <= 3, error::permission_denied(ENOT_AUTHORIZED));        
        // burn and mint
        if(egg_rarity == 1) {
            // mint_egg_common
        } else if(egg_rarity == 2){
            // mint_egg_rare
        } else {
            // mint_egg_epic
        }
    }

    fun mint_egg_common (receiver: &signer, auth: &signer, egg_minter_address:address) acquires Hatch {                                              
        // get random number 1~1000
        // 55%,30%,10%,2.8%,1%,0.7%,0.5%
        let resource_signer = get_resource_account_cap(egg_minter_address);                
        let resource_account_address = signer::address_of(&resource_signer);
        let guid = account::create_guid(&resource_signer);        
        let uuid = guid::creation_num(&guid);        
        let random_idx = utils::random_with_nonce(resource_account_address, 1000, uuid) + 1;
        if(random_idx <= 550) {
            // very common
        } else if (random_idx > 550 && random_idx <= 850) {
            // common
        } else if (random_idx > 850 && random_idx <= 950) {
        } else if (random_idx > 950 && random_idx <= 978) {
        } else if (random_idx > 978 && random_idx <= 988) {
        } else if (random_idx > 988 && random_idx < 995) {
        } else {
            //mythic
        }
        

    }
    
    fun mint_egg_rare (receiver: &signer, auth: &signer, egg_minter_address:address) acquires Hatch {           
        // 46%,26%,19%,4.8%,2%,1.5%,0.7%
        let resource_signer = get_resource_account_cap(egg_minter_address);                
        let resource_account_address = signer::address_of(&resource_signer);
        let guid = account::create_guid(&resource_signer);        
        let uuid = guid::creation_num(&guid);        
        let random_idx = utils::random_with_nonce(resource_account_address, 1000, uuid) + 1;
        if(random_idx <= 460) {
            // very common
        } else if (random_idx > 460 && random_idx <= 720) {
            // common
        } else if (random_idx > 720 && random_idx <= 910) {
        } else if (random_idx > 910 && random_idx <= 958) {
        } else if (random_idx > 958 && random_idx <= 978) {
        } else if (random_idx > 978 && random_idx < 993) {
        } else {
            //mythic
        }

    }

    fun mint_egg_epic (receiver: &signer, auth: &signer, egg_minter_address:address) acquires Hatch {           
        // 35%,24%,22%,12%,4%,2%,1%
        let resource_signer = get_resource_account_cap(egg_minter_address);                
        let resource_account_address = signer::address_of(&resource_signer);
        let guid = account::create_guid(&resource_signer);        
        let uuid = guid::creation_num(&guid);        
        let random_idx = utils::random_with_nonce(resource_account_address, 1000, uuid) + 1;
        if(random_idx <= 350) {
            // very common
        } else if (random_idx > 350 && random_idx <= 590) {
            // common
        } else if (random_idx > 590 && random_idx <= 810) {
        } else if (random_idx > 810 && random_idx <= 930) {
        } else if (random_idx > 930 && random_idx <= 970) {
        } else if (random_idx > 970 && random_idx < 990) {
        } else {
            //mythic
        }
    }

    fun get_range_very_common (egg_minter_address:address) : u64 acquires Hatch {           
        // beast idx  1-42
        let total_count_idx = 42;
        let start_idx = 1;

        let resource_signer = get_resource_account_cap(egg_minter_address);                
        let resource_account_address = signer::address_of(&resource_signer);
        let guid = account::create_guid(&resource_signer);        
        let uuid = guid::creation_num(&guid);        
        let random_idx = utils::random_with_nonce(resource_account_address, total_count_idx, uuid) + start_idx;
        random_idx
    }

    fun get_range_common (egg_minter_address:address) : u64 acquires Hatch {           
        // beast idx  143 - 154
        let total_count_idx = 12;
        let start_idx = 143;       
        get_random_with_idx(total_count_idx,start_idx,egg_minter_address) 
    }

    fun get_range_rare (egg_minter_address:address) : u64 acquires Hatch {           
        // beast idx  255-260
        let total_count_idx = 6;
        let start_idx = 255;

        get_random_with_idx(total_count_idx,start_idx, egg_minter_address)
    }

    fun get_range_very_rare (egg_minter_address:address) : u64 acquires Hatch {           
        // beast idx  361-364
        let total_count_idx = 4;
        let start_idx = 361;

        get_random_with_idx(total_count_idx,start_idx, egg_minter_address)
    }

    fun get_range_epic (egg_minter_address:address) : u64 acquires Hatch {           
        // beast idx  465-467
        let total_count_idx = 3;
        let start_idx = 465;
        get_random_with_idx(total_count_idx,start_idx, egg_minter_address)
    }

    fun get_range_legendary (egg_minter_address:address) : u64 acquires Hatch {           
        // beast idx  568-571
        let total_count_idx = 4;
        let start_idx = 568;
        get_random_with_idx(total_count_idx,start_idx,egg_minter_address)        
    }

    fun get_range_mythic (egg_minter_address:address) : u64 acquires Hatch {           
        // beast idx  672-673
        let total_count_idx = 2;
        let start_idx = 672;
        get_random_with_idx(total_count_idx,start_idx, egg_minter_address)
    }

    fun get_random_with_idx(total_count_idx:u64, start_idx:u64, egg_minter_address:address) : u64 acquires Hatch {
        let resource_signer = get_resource_account_cap(egg_minter_address);                
        let resource_account_address = signer::address_of(&resource_signer);
        let guid = account::create_guid(&resource_signer);        
        let uuid = guid::creation_num(&guid);        
        let random_idx = utils::random_with_nonce(resource_account_address, total_count_idx, uuid) + start_idx;
        random_idx
    }
}
