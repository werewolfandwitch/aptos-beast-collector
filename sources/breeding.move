
module beast_collector::breeding {
    
    use std::signer;    
    use std::error;
    use aptos_framework::timestamp;    
    use aptos_framework::coin::{Self};
    use aptos_framework::event::{Self, EventHandle};        
    use aptos_framework::account;    
    use aptos_framework::guid;
    use beast_collector::utils;
    use beast_collector::trainer_generator;    

    const MAX_AMOUNT:u64 = 1000;
    const APT_PRICE:u64 = 50000000;
    const WAR_PRICE:u64 = 50000000000;    

    const ENOT_AUTHORIZED:u64 = 0;
    const ENOT_OPENED: u64 = 1; 
    const EMAX_AMOUNT: u64 = 2;   
    const ENO_SUFFICIENT_FUND: u64 = 3;

    struct LaunchPad has store, key {          
        signer_cap: account::SignerCapability,
        launchpad_public_open:u64,        
        max_amount:u64,
        minted_count:u64,
        minted_events:EventHandle<MintedEvent>,                                           
    }
    
    struct MintedEvent has drop, store {        
        minted_count: u64
    }  

    entry fun admin_withdraw<CoinType>(sender: &signer, amount: u64) acquires LaunchPad {
        let sender_addr = signer::address_of(sender);
        let resource_signer = get_resource_account_cap(sender_addr);                                
        let coins = coin::withdraw<CoinType>(&resource_signer, amount);                
        coin::deposit(sender_addr, coins);
    }

    fun get_resource_account_cap(minter_address : address) : signer acquires LaunchPad {
        let launchpad = borrow_global<LaunchPad>(minter_address);
        account::create_signer_with_capability(&launchpad.signer_cap)
    }

    entry fun init(sender: &signer, launchpad_public_open:u64) {
        let sender_addr = signer::address_of(sender);                
        let (resource_signer, signer_cap) = account::create_resource_account(sender, x"02");        
        if(!exists<LaunchPad>(sender_addr)){            
            move_to(sender, LaunchPad {                
                signer_cap,
                launchpad_public_open:launchpad_public_open,
                max_amount:MAX_AMOUNT,
                minted_count: 0,
                minted_events:account::new_event_handle<MintedEvent>(sender)                
            });
        };
        
    } 
    // TODO 
    entry fun breeding() {

    }
}
