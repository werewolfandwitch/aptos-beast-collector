
module beast_collector::trainer_exploration {
    
    use beast_collector::utils;
    use beast_collector::trainer_generator;
    use std::signer;    
    use aptos_token::token::{Self, TokenId}; 
    use std::string::{Self, String};    
    use aptos_token::property_map::{Self};
    use aptos_framework::account;    
    

    // check collection creator 
    // check trainer grade and create egg by grade
    // check timer and change it for next exploration
    const TRAINER_COLLECTION_NAME:vector<u8> = b"W&W Beast Collector";
    
    const PROPERTY_EXP: vector<u8> = b"W_EXP"; // 100 MAX, 100 EXP => 1 LEVEL UP
    const PROPERTY_LEVEL: vector<u8> = b"W_LEVEL"; // 5 LEVEL MAX, 5 LEVEL with 100 EXP can upgrade GRADE of trainer
    const PROPERTY_NEXT_EXPLORATION_TIME: vector<u8> = b"W_NEXT_EXPLORATION_TIME";
    const PROPERTY_GRADE: vector<u8> = b"W_GRADE"; // Trainer(1) / Pro Trainer(2) / Semi champion(3) / World champion(4) / Master (5) 

    struct Exploration has store, key {          
        signer_cap: account::SignerCapability,        
    }
        

    fun get_resource_account_cap(exp_address : address) : signer acquires Exploration {
        let launchpad = borrow_global<Exploration>(exp_address);
        account::create_signer_with_capability(&launchpad.signer_cap)
    }

    entry fun init(sender: &signer) {
        let sender_addr = signer::address_of(sender);                
        let (resource_signer, signer_cap) = account::create_resource_account(sender, x"03");                                
        if(!exists<Exploration>(sender_addr)){            
            move_to(sender, Exploration {                
                signer_cap,                
            });
        };
    }   

    entry fun trainer_exploration<CoinType>(receiver: &signer, trainer_token_name:String, trainer_creator:address, property_version:u64, exp_address:address, trainer_contract:address) acquires Exploration {
        let token_id = token::create_token_id_raw(trainer_creator, string::utf8(TRAINER_COLLECTION_NAME), trainer_token_name, property_version);        
        let resource_signer = get_resource_account_cap(exp_address);

        // get egg                                
        let pm = token::get_property_map(signer::address_of(receiver), token_id);
        let ex_time = property_map::read_u64(&pm, &string::utf8(PROPERTY_NEXT_EXPLORATION_TIME));

        // extend time
        trainer_generator::add_exp(receiver, &resource_signer, trainer_contract, token_id, 30);        
        trainer_generator::extend_exploration_time(receiver, &resource_signer, trainer_contract, token_id);        
    }
}
