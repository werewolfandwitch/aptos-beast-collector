
module beast_collector::breeding {
    
    use std::signer;    
    use std::error;
    use aptos_framework::timestamp;    
    use aptos_framework::coin::{Self};
    use aptos_framework::event::{Self, EventHandle};        
    use aptos_framework::account;    
    use aptos_framework::guid;    

    const MAX_AMOUNT:u64 = 1000;
    const APT_PRICE:u64 = 50000000;
    const WAR_PRICE:u64 = 50000000000;    

    const ENOT_AUTHORIZED:u64 = 0;        

    const BEAST_COLLECTION_NAME:vector<u8> = b"W&W Beast";    

    const BEAST_BREEDING_TIME: vector<u8> = b"W_BREEDING";

    struct Breeding has store, key {          
        signer_cap: account::SignerCapability,                
    }    

    entry fun admin_withdraw<CoinType>(sender: &signer, amount: u64) acquires Breeding {
        let sender_addr = signer::address_of(sender);
        let resource_signer = get_resource_account_cap(sender_addr);                                
        let coins = coin::withdraw<CoinType>(&resource_signer, amount);                
        coin::deposit(sender_addr, coins);
    }

    fun get_resource_account_cap(minter_address : address) : signer acquires Breeding {
        let launchpad = borrow_global<Breeding>(minter_address);
        account::create_signer_with_capability(&launchpad.signer_cap)
    }

    entry fun init(sender: &signer, launchpad_public_open:u64) {
        let sender_addr = signer::address_of(sender);                
        let (resource_signer, signer_cap) = account::create_resource_account(sender, x"07");        
        if(!exists<Breeding>(sender_addr)){            
            move_to(sender, Breeding {                
                signer_cap,                
            });
        };
        
    } 
    
    entry fun breeding(
        holder: &signer, 
        token_name_1:String, property_version_1:u64,
        token_name_2:String, property_version_2:u64
    ) {
        let token_id_1 = token::create_token_id_raw(@beast_creator, string::utf8(BEAST_COLLECTION_NAME), token_name_1, property_version_1);        
        let token_id_2 = token::create_token_id_raw(@beast_creator, string::utf8(BEAST_COLLECTION_NAME), token_name_2, property_version_2);        
        let pm = token::get_property_map(signer::address_of(holder), token_id_1);        
        let p2 = token::get_property_map(signer::address_of(holder), token_id_2);        
        let breed_expired_time_1 = property_map::read_u64(&pm, &string::utf8(BEAST_BREEDING_TIME));
        let breed_expired_time_2 = property_map::read_u64(&pm2, &string::utf8(BEAST_BREEDING_TIME));
        let now_seconds = timestamp::now_seconds();
        assert!(breed_expired_time_1 < now_seconds, error::permission_denied(ENOT_AUTHORIZED));
        assert!(breed_expired_time_2 < now_seconds, error::permission_denied(ENOT_AUTHORIZED));
        // burn two token and make new pet with under level
    }
}
