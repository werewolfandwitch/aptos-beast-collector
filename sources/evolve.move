
module beast_collector::evolve {
    
    use std::signer;            
    use aptos_framework::coin::{Self};
    use aptos_framework::event::{Self};        
    use aptos_framework::account;        

    const MAX_AMOUNT:u64 = 1000;
    const APT_PRICE:u64 = 50000000;
    const WAR_PRICE:u64 = 50000000000;    

    const ENOT_AUTHORIZED:u64 = 0;
    const ENOT_OPENED: u64 = 1; 
    const EMAX_AMOUNT: u64 = 2;   
    const ENO_SUFFICIENT_FUND: u64 = 3;

    struct Evolve has store, key {          
        signer_cap: account::SignerCapability,                                                        
    }
        

    entry fun admin_withdraw<CoinType>(sender: &signer, amount: u64) acquires Evolve {
        let sender_addr = signer::address_of(sender);
        let resource_signer = get_resource_account_cap(sender_addr);                                
        let coins = coin::withdraw<CoinType>(&resource_signer, amount);                
        coin::deposit(sender_addr, coins);
    }

    fun get_resource_account_cap(minter_address : address) : signer acquires Evolve {
        let launchpad = borrow_global<Evolve>(minter_address);
        account::create_signer_with_capability(&launchpad.signer_cap)
    }

    entry fun init(sender: &signer) {
        let sender_addr = signer::address_of(sender);                
        let (resource_signer, signer_cap) = account::create_resource_account(sender, x"08");        
        if(!exists<Evolve>(sender_addr)){            
            move_to(sender, Evolve {                
                signer_cap,                
            });
        };
        
    } 
    // TODO 
    entry fun evolve() {

    }
}
