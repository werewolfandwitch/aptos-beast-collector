
module beast_collector::launchpad {

    entry fun admin_withdraw<CoinType>(sender: &signer, amount: u64) acquires LaunchPad {
        let sender_addr = signer::address_of(sender);
        let resource_signer = get_resource_account_cap(sender_addr);                                
        let coins = coin::withdraw<CoinType>(&resource_signer, amount);                
        coin::deposit(sender_addr, coins);
    }

    entry fun init<AptosCoin, WarCoinType>(sender: &signer) acquires LaunchPad {
        let sender_addr = signer::address_of(sender);                
        let (resource_signer, signer_cap) = account::create_resource_account(sender, x"01");    
        token::initialize_token_store(&resource_signer);
        if(!exists<TrainerManager>(sender_addr)){            
            move_to(sender, LaunchPad {                
                signer_cap,
            });
        };

        if(!coin::is_account_registered<WarCoinType>(signer::address_of(&resource_signer))){
            coin::register<WarCoinType>(&resource_signer);
        };

        if(!coin::is_account_registered<AptosCoin>(signer::address_of(&resource_signer))){
            coin::register<AptosCoin>(&resource_signer);
        };
        
    }     

    entry fun mint_trainer() {
        
    }                     
}
