
module beast_collector::beast_move {
    use std::signer;
    use std::string::{Self, String};
    use aptos_token::token::{Self, TokenId};
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::timestamp;
    use aptos_framework::account;
    
    const BEAST_COLLECTION_NAME:vector<u8> = b"W&W Beast";

    struct BeastMovedEvent has drop, store {
        owner: address,
        beast: TokenId,
        email: String,
        moved_time: u64
    }

    struct BeastMoveManager has store, key {
        beast_moved_events:EventHandle<BeastMovedEvent>,
    }

    entry fun init(sender: &signer) {
        let sender_addr = signer::address_of(sender);
        let (_resource_signer, _signer_cap) = account::create_resource_account(sender, x"10");
        if(!exists<BeastMoveManager>(sender_addr)){
            move_to(sender, BeastMoveManager {
                beast_moved_events:account::new_event_handle<BeastMovedEvent>(sender),
            });
        };
    }

    entry fun burn_and_move_to_tcg(
        holder: &signer, holder_email:String, mover_contract_address:address, token_name:String, property_version:u64,
    ) acquires BeastMoveManager {
        let holder_addr = signer::address_of(holder);
        let token_id = token::create_token_id_raw(@beast_creator, string::utf8(BEAST_COLLECTION_NAME), token_name, property_version);
        token::burn(holder, @beast_creator, string::utf8(BEAST_COLLECTION_NAME), token_name, property_version, 1);
        let mover_events = borrow_global_mut<BeastMoveManager>(mover_contract_address);
        event::emit_event(&mut mover_events.beast_moved_events, BeastMovedEvent {
            owner: holder_addr,
            beast: token_id,
            email: holder_email,
            moved_time: timestamp::now_seconds()
        });
    }
}
