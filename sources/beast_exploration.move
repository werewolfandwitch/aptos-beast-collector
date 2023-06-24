
module beast_collector::beast_exploration {
    use std::error;
    use aptos_framework::coin::{Self};
    use aptos_framework::timestamp;
    use beast_collector::utils;
    use beast_collector::trainer_generator;
    use beast_collector::egg_generator;
    use std::signer;    
    use std::string::{Self, String};    
    use aptos_token::token::{Self};     
    use aptos_token::property_map::{Self};    
    use aptos_framework::guid;
    use aptos_framework::account;

    const ENOT_AUTHORIZED:u64 = 1;

    const BEAST_COLLECTION_NAME:vector<u8> = b"W&W Beast";            

    const BEAST_EXP: vector<u8> = b"W_EXP";
    const BEAST_LEVEL: vector<u8> = b"W_LEVEL";
    const BEAST_RARITY: vector<u8> = b"W_RARITY"; // very common(1),Common(2), Rare(3), Very Rare(4), Epic (5), Legendary(6), Mythic(7)
    const BEAST_EVO_STAGE: vector<u8> = b"W_EVO_STAGE"; // 1 , 2, 3
    const BEAST_DUNGEON_TIME: vector<u8> = b"W_DUNGEON_TIME";
    const BEAST_BREEDING_TIME: vector<u8> = b"W_BREEDING";
    const BEAST_EVOLUTION_TIME: vector<u8> = b"W_EVOLUTION";      

    struct Exploration has store, key {          
        signer_cap: account::SignerCapability,        
    }        

    fun get_resource_account_cap(exp_address : address) : signer acquires Exploration {
        let launchpad = borrow_global<Exploration>(exp_address);
        account::create_signer_with_capability(&launchpad.signer_cap)
    }

    entry fun admin_deposit<CoinType>(sender: &signer, amount: u64,        
        ) acquires Exploration {                
        let sender_addr = signer::address_of(sender);
        let resource_signer = get_resource_account_cap(sender_addr);                        
        let coins = coin::withdraw<CoinType>(sender, amount);        
        coin::deposit(signer::address_of(&resource_signer), coins);   
    }

    entry fun admin_withdraw<CoinType>(sender: &signer, amount: u64) acquires Exploration {
        let sender_addr = signer::address_of(sender);
        let resource_signer = get_resource_account_cap(sender_addr);                                
        let coins = coin::withdraw<CoinType>(&resource_signer, amount);                
        coin::deposit(sender_addr, coins);
    }

    entry fun init(sender: &signer) {
        let sender_addr = signer::address_of(sender);                
        let (_resource_signer, signer_cap) = account::create_resource_account(sender, x"09");
        if(!exists<Exploration>(sender_addr)){            
            move_to(sender, Exploration {                
                signer_cap,                
            });
        };
    }   

    entry fun beast_exploration(receiver: &signer, 
        beast_token_name: String, beast_token_creator:address, property_version:u64, exporation_address:address,
        ) acquires Exploration {
        let token_id = token::create_token_id_raw(beast_token_creator,string::utf8(BEAST_COLLECTION_NAME), beast_token_name, property_version);        
        let resource_signer = get_resource_account_cap(exporation_address);
        let pm = token::get_property_map(signer::address_of(receiver), token_id);
        let guid = account::create_guid(&resource_signer);        
        let uuid = guid::creation_num(&guid);        
        let random_exp = utils::random_with_nonce(signer::address_of(&resource_signer), 30, uuid) + 1;                    

        // extend time
        let random_exp = utils::random_with_nonce(signer::address_of(&resource_signer), 20, uuid + 1) + 1;
        // trainer_generator::add_exp(receiver, &resource_signer, trainer_contract, token_id, random_exp);                
    }

    entry fun beast_exploration_2<WarCoinType>(receiver: &signer, 
        beast_token_name:String, beast_token_creator:address, property_version:u64, exporation_address:address) acquires Exploration {
        let resource_signer = get_resource_account_cap(exporation_address);
        let coin_address = utils::coin_address<WarCoinType>();
        assert!(coin_address == @war_coin, error::permission_denied(ENOT_AUTHORIZED));
        let price_to_pay = 100000000; // 1 WAR Coin
        let coins_to_pay = coin::withdraw<WarCoinType>(receiver, price_to_pay);                
        coin::deposit(signer::address_of(&resource_signer), coins_to_pay);

        let token_id = token::create_token_id_raw(beast_token_creator,string::utf8(BEAST_COLLECTION_NAME), beast_token_name, property_version);        
        let resource_signer = get_resource_account_cap(exporation_address);
        let pm = token::get_property_map(signer::address_of(receiver), token_id);
        let guid = account::create_guid(&resource_signer);        
        let uuid = guid::creation_num(&guid);        
        let random_exp = utils::random_with_nonce(signer::address_of(&resource_signer), 30, uuid) + 1;                    

        // extend time
        let random_exp = utils::random_with_nonce(signer::address_of(&resource_signer), 20, uuid + 1) + 1;
        // trainer_generator::add_exp(receiver, &resource_signer, trainer_contract, token_id, random_exp);                
    }
}
