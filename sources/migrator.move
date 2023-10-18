
module beast_collector::migrator {
    use std::signer;
    use std::string::{Self, String};
    use aptos_token::token::{Self, TokenId};
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use beast_collector::utils;
    use std::error;

    const ENOT_AUTHORIZED:u64 = 0;
    
    const BEAST_COLLECTION_NAME:vector<u8> = b"W&W Beast";

    struct BeastMigratedEvent has drop, store {
        owner: address,
        beast: TokenId,
        email: String,
        timestamp: u64
    }

    struct CoinMigratedEvent has drop, store {
        owner: address,
        amount: u64,
        email: String,
        timestamp: u64
    }

    struct MigrationManager has store, key {
        beast_migrated_events:EventHandle<BeastMigratedEvent>,
        coin_migrated_events:EventHandle<CoinMigratedEvent>,
    }

    entry fun init<WarCoinType>(sender: &signer) {
        let sender_addr = signer::address_of(sender);
        let (_resource_signer, _signer_cap) = account::create_resource_account(sender, x"10");
        if(!exists<MigrationManager>(sender_addr)){
            move_to(sender, MigrationManager {
                beast_migrated_events:account::new_event_handle<BeastMigratedEvent>(sender),
                coin_migrated_events:account::new_event_handle<CoinMigratedEvent>(sender),
            });
        };
    }

    entry fun burn_war<WarCoinType>(sender: &signer, amount: u64) {                
        aptos_framework::managed_coin::burn<WarCoinType>(sender, amount);
    }

    entry fun burn_war_and_migrate_to_tcg<WarCoinType>(
        holder: &signer, holder_email:String, contract_address:address, amount:u64,
    ) acquires MigrationManager {
        let holder_addr = signer::address_of(holder);
        let coin_address = utils::coin_address<WarCoinType>();
        assert!(coin_address == @war_coin, error::permission_denied(ENOT_AUTHORIZED));
        burn_war<WarCoinType>(holder, amount);
        let migrator_events = borrow_global_mut<MigrationManager>(contract_address);
        event::emit_event(&mut migrator_events.coin_migrated_events, CoinMigratedEvent {
            owner: holder_addr,
            amount: amount,
            email: holder_email,
            timestamp: timestamp::now_seconds()
        });
    }

    entry fun burn_nft_and_migrate_to_tcg(
        holder: &signer, holder_email:String, contract_address:address, token_name:String, property_version:u64,
    ) acquires MigrationManager {
        let holder_addr = signer::address_of(holder);
        let token_id = token::create_token_id_raw(@beast_creator, string::utf8(BEAST_COLLECTION_NAME), token_name, property_version);
        token::burn(holder, @beast_creator, string::utf8(BEAST_COLLECTION_NAME), token_name, property_version, 1);
        let migrator_events = borrow_global_mut<MigrationManager>(contract_address);
        event::emit_event(&mut migrator_events.beast_migrated_events, BeastMigratedEvent {
            owner: holder_addr,
            beast: token_id,
            email: holder_email,
            timestamp: timestamp::now_seconds()
        });
    }
}
