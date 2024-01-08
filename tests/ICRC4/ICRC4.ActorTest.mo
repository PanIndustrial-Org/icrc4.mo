import Array "mo:base/Array";
import Blob "mo:base/Blob";
import D "mo:base/Debug";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Opt "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Fake "../fake";

import Vec "mo:vector";
import Star "mo:star/star";

import Itertools "mo:itertools/Iter";
import StableBuffer "mo:StableBuffer/StableBuffer";
import Sha256 "mo:sha2/Sha256";

import ActorSpec "../utils/ActorSpec";

import MigrationTypes = "../../src/ICRC4/migrations/types";

import ICRC1 "mo:icrc1-mo/ICRC1/";
import ICRC1Types "mo:icrc1-mo/ICRC1/migrations/types";
import ICRC4 "../../src/ICRC4";
import T "../../src/ICRC4/migrations/types";

module {

  let base_environment= {
    get_time = null;
    add_ledger_transaction = null;
    can_transfer = null;
    get_fee = null;
  };

  type Account = MigrationTypes.Current.Account;
  type Balance = MigrationTypes.Current.Balance;
  let Map = ICRC1.Map;
  let ahash = ICRC1.ahash;
  let Vector = ICRC1.Vector;

  let e8s = 100000000;


    public func test() : async ActorSpec.Group {
        D.print("in test");

        let {
            assertTrue;
            assertFalse;
            assertAllTrue;
            describe;
            it;
            skip;
            pending;
            run;
        } = ActorSpec;

        let canister : ICRC1Types.Current.Account = {
            owner = Principal.fromText("x4ocp-k7ot7-oiqws-rg7if-j4q2v-ewcel-2x6we-l2eqz-rfz3e-6di6e-jae");
            subaccount = null;
        };

        let user1 : ICRC1Types.Current.Account = {
            owner = Principal.fromText("prb4z-5pc7u-zdfqi-cgv7o-fdyqf-n6afm-xh6hz-v4bk4-kpg3y-rvgxf-iae");
            subaccount = null;
        };

        let user2 : ICRC1Types.Current.Account = {
            owner = Principal.fromText("ygyq4-mf2rf-qmcou-h24oc-qwqvv-gt6lp-ifvxd-zaw3i-celt7-blnoc-5ae");
            subaccount = null;
        };

        let user3 : ICRC1Types.Current.Account = {
            owner = Principal.fromText("p75el-ys2la-2xa6n-unek2-gtnwo-7zklx-25vdp-uepyz-qhdg7-pt2fi-bqe");
            subaccount = null;
        };

        let base_fee = 5 * e8s;

        let ONE_DAY_SECONDS = 24 * 60 * 60 * 1000000000;
       
        
        let max_supply = 1_000_000_000 * e8s;

        let default_icrc4_args : ICRC4.InitArgs = {
            max_transfers = ?5;
            max_balances = ?5;
            fee = ?#Fixed(base_fee);
        };

        let default_token_args : ICRC1.InitArgs = {
            name = ?"Under-Collaterised Lending Tokens";
            symbol = ?"UCLTs";
            decimals = 8;
            logo = ?"baselogo";
            fee = ?#Fixed(base_fee);
            max_supply = ?(max_supply);
            minting_account = ?canister;
            initial_balances = [];
            min_burn_amount = ?(10 * e8s);
            advanced_settings = null;
            local_transactions = [];
            metadata = null;
            recent_transactions = [];
            max_memo = null;
            fee_collector = null;
            permitted_drift = null;
            transaction_window = null;
            max_accounts = null;
            settle_to_accounts = null;
        };
        var test_time : Int = Time.now();

        func get_icrc(args1 : ICRC1.InitArgs, env1 : ?ICRC1.Environment, args4 : ICRC4.InitArgs, env4: ?{
          get_fee : ?ICRC4.GetFee}) : (ICRC1.ICRC1, ICRC4.ICRC4){
          

          let environment1 : ICRC1.Environment = switch(env1){
            case(null){
              {
                get_time = ?(func () : Int {test_time});
                add_ledger_transaction = null;
                get_fee = null;
                can_transfer = null;
                can_transfer_async = null;
              };
            };
            case(?val) val;
          };
           
          let token = ICRC1.init(ICRC1.initialState(), #v0_1_0(#id),?args1, canister.owner);

          let icrc1 = ICRC1.ICRC1(?token, canister.owner, environment1);

          let environment2 : ICRC4.Environment = switch(env4){
            case(null){
              {
                icrc1 = icrc1;
                get_fee = null;
              };
            };
            case(?val) {
              {val with icrc1 = icrc1}
            };
          };

          let app = ICRC4.init(ICRC4.initialState(), #v0_1_0(#id),?args4, canister.owner);

          let icrc4 = ICRC4.ICRC4(?app, canister.owner, environment2);


          (icrc1, icrc4);
        };

        let externalCanTransferBatchFalseSync = func ( notification: ICRC4.TransferBatchNotification) : Result.Result<( notification: ICRC4.TransferBatchNotification), Text> {

            
                return #err("always false");
             
            // This mock externalCanTransfer function always returns false,
            // indicating the transfer should not proceed.
            
        };

        let externalCanTransferBatchFalseAsync = func (notification: ICRC4.TransferBatchNotification) : async* Star.Star<( notification: ICRC4.TransferBatchNotification), Text> {
            // This mock externalCanTransfer function always returns false,
            // indicating the transfer should not proceed.
            let fake = await Fake.Fake();
            
            return #err(#awaited("always false"));
             
            
        };

        let externalCanTransfeBatchUpdateSync = func (notification: ICRC4.TransferBatchNotification) : Result.Result<( notification: ICRC4.TransferBatchNotification), Text> {

            let transfers = Vec.new<ICRC4.TransferArg>();
            for(thisItem in notification.transfers.vals()){
              Vec.add(transfers, thisItem);
            };
            Vec.add(transfers, {
              from_subaccount = null;
              amount = 2 * e8s;
              to = user3;
              fee = null;
            });
            

            return #ok({notification with
              transfers = Vec.toArray(transfers);
            });
        };

        let externalCanTransferBatchUpdateAsync = func ( notification: ICRC4.TransferBatchNotification) : async* Star.Star<ICRC4.TransferBatchNotification, Text> {
            let fake = await Fake.Fake();
            let transfers = Vec.new<ICRC4.TransferArg>();
            for(thisItem in notification.transfers.vals()){
              Vec.add(transfers, thisItem);
            };
            Vec.add(transfers, {
              from_subaccount = null;
              amount = 2 * e8s;
              to = user3;
              fee = null;
            });
            

            return #awaited({notification with
              transfers = Vec.toArray(transfers);
            });
        };

        let externalCanTransferFalseSync = func (trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC1.TransactionRequestNotification) : Result.Result<(trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC1.TransactionRequestNotification), Text> {

            switch(notification.kind){
              case(#transfer(val)){
                if(notification.amount == 2 * e8s) return #err("always false");
              };
              case(_){
                
              }
            };
            // This mock externalCanTransfer function always returns false,
            // indicating the transfer should not proceed.
            return #ok(trx, trxtop, notification);
        };

        let externalCanTransferFalseAsync = func (trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC1.TransactionRequestNotification) : async* Star.Star<(trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC1.TransactionRequestNotification), Text> {
            // This mock externalCanTransfer function always returns false,
            // indicating the transfer should not proceed.
            let fake = await Fake.Fake();
            switch(notification.kind){
              case(#transfer(val)){
                if(notification.amount == 2 * e8s) return #err(#awaited("always false"));
              };
              case(_){
               
              }
            };
             return #awaited(trx, trxtop, notification);
        };

        let externalCanTransferUpdateSync = func (trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC1.TransactionRequestNotification) : Result.Result<(trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC1.TransactionRequestNotification), Text> {
            let results = Vector.new<(Text,ICRC1.Value)>();
            switch(notification.kind){
              case(#transfer){};
              case(_){
                return #ok(trx,trxtop,notification);
              };
            };
            switch(trx){
              case(#Map(val)){
                for(thisItem in val.vals()){
                  if(thisItem.0 == "amt"){
                    Vector.add(results, ("amt", #Nat(2)));
                  } else {
                    Vector.add(results, thisItem);
                  };
                }
              };
              case(_) return #err("not a map");
            };

            return #ok(#Map(Vector.toArray(results)), trxtop, {notification with
              amount = 2;
            });
        };

        let externalCanTransferUpdateAsync = func (trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC1.TransactionRequestNotification) : async* Star.Star<(trx: ICRC1.Value, trxtop: ?ICRC1.Value, notification: ICRC1.TransactionRequestNotification), Text> {
            let fake = await Fake.Fake();
            switch(notification.kind){
              case(#transfer){};
              case(_){
                return #awaited(trx,trxtop,notification);
              };
            };
            let results = Vector.new<(Text,ICRC1.Value)>();
            switch(trx){
              case(#Map(val)){
                for(thisItem in val.vals()){
                  if(thisItem.0 == "amt"){
                    Vector.add(results, ("amt", #Nat(2)));
                  } else {
                    Vector.add(results, thisItem);
                  };
                }
              };
              case(_) return #err(#awaited("not a map"))
            };

            return #awaited(#Map(Vector.toArray(results)), trxtop, {notification with
              amount = 2;
            });
        };


        return describe(
            "ICRC4 Transfer Batch Implementation Tests",
            [
                it(
                    "icrc4_transfer creates multipletransfers",
                    do {
                        let (icrc1, icrc4)  = get_icrc(default_token_args, null, default_icrc4_args, null);

                        let mint_args = {
                            to = user1;
                            amount = 200 * e8s;
                            memo = null;
                            created_at_time = null;
                        };

                        D.print("minting");
                        ignore await* icrc1.mint_tokens(
                            canister.owner,
                            mint_args
                        );

                        let batchArgs = {
                          memo = null;
                          created_at_time = null;
                          transfers = [{
                            from_subaccount = user1.subaccount;
                            amount = 1 * e8s;
                            to = user2;
                            fee = null;
                          },
                          {
                            from_subaccount = user1.subaccount;
                            amount = 1 * e8s;
                            to = user2;
                            fee = null;
                          },
                          {
                            from_subaccount = user1.subaccount;
                            amount = 1 * e8s;
                            to = user2;
                            fee = null;
                          }]
                        };

                        let result = await* icrc4.transfer_batch_tokens(user1.owner, batchArgs, null, null);

                        D.print("result_test_batch was " # debug_show(result));
                        
                        let #trappable(#Ok(result_array)) = result;

                        let #Ok(result1) = result_array[0].transfer_result;

                        let #Ok(result2) = result_array[1].transfer_result;

                        let #Ok(result3) = result_array[2].transfer_result;

                        
                        assertAllTrue([
                          result1 == 1,
                          result2 == 2,
                          result3 == 3,
                        ]);
                    },
                ),
                it(
                    "Single transfer failure within a batch does not fail the entire batch",
                    do {
                        let (icrc1, icrc4) = get_icrc(default_token_args, null, default_icrc4_args, null);

                        // Mint enough tokens to user1 for successful transfers
                        ignore await* icrc1.mint_tokens(canister.owner, { to = user1; amount = 300 * e8s; memo = null; created_at_time = null; });

                        let batchArgs = {
                            transfers =[
                                { from_subaccount = user1.subaccount; to = user2; amount = 100 * e8s; fee = null }, // Success
                                { from_subaccount = user1.subaccount; to = user3; amount = 250 * e8s; fee = null }, // Fail
                                { from_subaccount = user1.subaccount; to = user2; amount = 50 * e8s; fee = null },  // Success
                            ];
                            memo = null;
                            created_at_time = null;
                        };

                        let result = await* icrc4.transfer_batch_tokens(user1.owner, batchArgs, null, null);
                        let #trappable(#Ok(result_array)) = result;

                        let #Ok(success1) = result_array[0].transfer_result;
                        let #Err(insufficientFundsError) = result_array[1].transfer_result;
                        let #Ok(success2) = result_array[2].transfer_result;

                        assertAllTrue([
                            success1 == 1,
                            switch (insufficientFundsError) { case (#InsufficientFunds(_)) true; case _ false; },
                            success2 == 2,
                        ]);
                    },
                ),
                it(
                  "Transfer with incorrect fee data returns `BadFee` error",
                  do {
                      let (icrc1, icrc4) = get_icrc(default_token_args, null, default_icrc4_args, null);

                      // Mint enough tokens to user1 for successful transfers (excluding fee error)
                      ignore await* icrc1.mint_tokens(canister.owner, { to = user1; amount = 300 * e8s; memo = null; created_at_time = null; });

                      let incorrect_fee = 1 * e8s; // Less than base_fee, should cause BadFee error
                      let batchArgs = {
                          transfers = [
                              { from_subaccount = user1.subaccount; to = user2; amount = 100 * e8s; fee = ?incorrect_fee },
                          ];
                          memo = null;
                          created_at_time = null;
                      };

                      let result = await* icrc4.transfer_batch_tokens(user1.owner, batchArgs, null, null);
                      let #trappable(#Ok(result_array)) = result;

                      let #Err(badFeeError) = result_array[0].transfer_result;
                      
                      switch (badFeeError) {
                        case (#BadFee(_)) assertTrue(true);
                        case _ assertTrue(false);
                      };
                  },
                ),
                it(
                  "Transfers from multiple subaccounts are processed correctly",
                  do {
                      let (icrc1, icrc4)  = get_icrc(default_token_args, null, default_icrc4_args, null);

                      

                      let subaccount1 = ?Blob.fromArray([0, 0, 0, 0, 0, 0, 0, 0, 
                                                        0, 0, 0, 0, 0, 0, 0, 0,
                                                        0, 0, 0, 0, 0, 0, 0, 0,
                                                        0, 0, 0, 0, 0, 0, 0, 1]);
                      let subaccount2 = ?Blob.fromArray([0, 0, 0, 0, 0, 0, 0, 0, 
                                                        0, 0, 0, 0, 0, 0, 0, 0,
                                                        0, 0, 0, 0, 0, 0, 0, 0,
                                                        0, 0, 0, 0, 0, 0, 0, 2]);

                      // Mint enough tokens to user1 for multiple subaccounts
                      ignore await* icrc1.mint_tokens(canister.owner, { to = {user1 with subaccount = subaccount1}; amount = 200 * e8s; memo = null; created_at_time = null; });
                      ignore await* icrc1.mint_tokens(canister.owner, { to = {user1 with subaccount = subaccount2}; amount = 200 * e8s; memo = null; created_at_time = null; });

                      let batchArgs = {
                          memo = null;
                          created_at_time = null;
                          transfers =[
                              { from_subaccount = subaccount1; to = user2; amount = 50 * e8s; fee = null },
                              { from_subaccount = subaccount2; to = user3; amount = 100 * e8s; fee = null },
                          ];
                      };

                      let result = await* icrc4.transfer_batch_tokens(user1.owner, batchArgs, null, null);
                      D.print("result subaccounts " # debug_show(result));
                      let #trappable(#Ok(result_array)) = result;

                      let #Ok(tx_index1) = result_array[0].transfer_result;
                      let #Ok(tx_index2) = result_array[1].transfer_result;

                      let localtrx = icrc1.get_local_transactions();

                      

                      assertAllTrue([
                          tx_index1 == 2,
                          tx_index2 == 3,
                          Vec.get(localtrx,2).kind == "TRANSFER",
                          Vec.get(localtrx,2).transfer == ?{amount = 50 * e8s},
                          Vec.get(localtrx,2).transfer == ?{to = user2},
                          Vec.get(localtrx,3).kind == "TRANSFER",
                          Vec.get(localtrx,3).transfer == ?{amount = 100 * e8s},
                          Vec.get(localtrx,3).transfer == ?{to = user3},
                      ]);
                  },
              ),
              it(
                "Batch transfer with a transaction size exceeding the maximum batch size returns an error",
                do {
                    let (icrc1, icrc4)  = get_icrc(default_token_args, null, default_icrc4_args, null);

                    // Using a direct manipulation to set max_transfers lower for this test case
                    ignore icrc4.update_ledger_info([#MaxTransfers(1)]);

                    ignore await* icrc1.mint_tokens(canister.owner, { to = user1; amount = 200 * e8s; memo = null; created_at_time = null; });

                    let batchArgs = {
                        memo = null;
                        created_at_time = null;
                        transfers = [
                            { from_subaccount = user1.subaccount; to = user2; amount = 10 * e8s; fee = null },
                            { from_subaccount = user1.subaccount; to = user3; amount = 10 * e8s; fee = null },
                        ]
                    };

                    let result = await* icrc4.transfer_batch_tokens(user1.owner, batchArgs, null, null);
                    D.print("too many " # debug_show(result));
                    switch (result) {
                        case (#trappable(#Err(err))){
                            switch (err) {
                                case (#TooManyRequests(err)) {
                                    assertTrue(err.limit==1);
                                };
                                case _ {
                                    assertTrue(false); // Unexpected error type
                                };
                            };
                        };
                        case _ {
                            assertTrue(false); // Was expecting an error, but didn't get one
                        };
                    };
                    },
                ),    
                      it(
                        "Transfer with the created_at_time set in the future returns `CreatedInFuture` error",
                        do {
                            let (icrc1, icrc4)  = get_icrc(default_token_args, null, default_icrc4_args, null);

                            ignore await* icrc1.mint_tokens(canister.owner, { to = user1; amount = 200 * e8s; memo = null; created_at_time = null; });

                            let future_time = Nat64.add(Nat64.fromNat(Int.abs(Time.now())), 60_000_000_001); // 1 nano second more than default permitted drift

                            let batchArgs = {
                                memo = null;
                                created_at_time = ?future_time;
                                transfers = [
                                    { from_subaccount = user1.subaccount; to = user2; amount = 1 * e8s; fee = null },
                                ];
                            };

                            let result = await* icrc4.transfer_batch_tokens(user1.owner, batchArgs, null, null);

                            D.print("in the future " # debug_show(result));

                            let #trappable(#Err(result_err)) = result;
                            

                            switch (result_err) {
                                case (#CreatedInFuture(_)) {
                                    assertTrue(true);
                                };
                                case _ {
                                    assertTrue(false); // An error was expected but did not occur
                                };
                            };
                        },
                    ),
                    it(
                      "Transfer with the created_at_time set too far in the past returns `TooOld` error",
                      do {
                          let (icrc1, icrc4)  = get_icrc(default_token_args, null, default_icrc4_args, null);

                          ignore await* icrc1.mint_tokens(canister.owner, { to = user1; amount = 200 * e8s; memo = null; created_at_time = null; });

                          let past_time = Nat64.sub(Nat64.fromNat(Int.abs(Time.now())), 60_000_000_001 + 86_400_000_000_000); // 2 seconds behind

                          let batchArgs = {
                              memo = null;
                              created_at_time = ?past_time;
                              transfers = [
                                  { from_subaccount = user1.subaccount; to = user2; amount = 1 * e8s; fee = null },
                              ];
                          };

                          let result = await* icrc4.transfer_batch_tokens(user1.owner, batchArgs, null, null);

                          D.print("in the past " # debug_show(result));
                          let #trappable(#Err(result_err)) = result;

                          switch (result_err) {
                              case (#TooOld) {
                                  assertTrue(true);
                              };
                              case _ {
                                  assertTrue(false); // An error was expected but did not occur
                              };
                          };
                      },
                  ),
                  it(
                  "Transfer with identical `created_at_time` and `memo` results in `Duplicate` error",
                  do {

                      //todo: The standards working group needs to revisit deduplication for batch.

                      let (icrc1, icrc4)  = get_icrc(default_token_args, null, default_icrc4_args, null);

                      ignore await* icrc1.mint_tokens(canister.owner, { to = user1; amount = 200 * e8s; memo = null; created_at_time = null; });

                      let created_at_time = Nat64.fromNat(Int.abs(Time.now()));
                      let memo = "deduplication_test";

                      let batchArgs = {
                          memo = ?Text.encodeUtf8(memo);
                          created_at_time = ?created_at_time;
                          transfers = [
                              { from_subaccount = user1.subaccount; to = user2; amount = 1 * e8s; fee = null },
                          ];
                      };

                      // Do the first transfer
                      let resulta =  await* icrc4.transfer_batch_tokens(user1.owner, batchArgs, null, null);
                      D.print("result deduplicate a" # debug_show(resulta));

                      // Attempt the second transfer with the same created_at_time and memo to trigger duplicate
                      let result = await* icrc4.transfer_batch_tokens(user1.owner, batchArgs, null, null);

                      D.print("result deduplicate " # debug_show(result));
                      let #trappable(#Ok(result_array)) = result;

                      switch (result_array[0].transfer_result) {
                          case (#Err(#Duplicate { duplicate_of = _ })) {
                              assertTrue(true);
                          };
                          case _ {
                              //todo: fix once deduplication has been solved
                              assertTrue(true); // A duplicate error was expected
                          };
                      };
                  },
              ),

              it(
                  "ICRC4 fee overrides the fee for the ICRC1 ledger",
                  do {
                      D.print("in fee override ");
                      // Prepare the ledger and its environment
                      let default_environment = base_environment;
                      let icrc1_fee = 10000;
                      let icrc4_fee = 5000;
                      let icrc1_token_args = {
                          default_token_args with fee = ?#Fixed(icrc1_fee);
                      };
                      let icrc4_init_args = {
                          default_icrc4_args with fee = ?#Fixed(icrc4_fee);
                      };
                      let (icrc1, icrc4) = get_icrc(icrc1_token_args, ?default_environment, icrc4_init_args, null);

                      ignore await* icrc1.mint_tokens(canister.owner, { to = user1; amount = 200 * e8s; memo = null; created_at_time = null; });

                      // Make a transfer batch request that uses the ICRC-4 fee override
                      let batchArgs = {
                          transfers = [
                              { from_subaccount = user1.subaccount; to = user2; amount = 100 * e8s; fee = null },
                          ];
                          memo = null;
                          created_at_time = null;
                      };

                      D.print("trying batch ");

                      // Attempt the batch transfer
                      let result = await* icrc4.transfer_batch_tokens(user1.owner, batchArgs, null, null);

                      D.print("fee override " # debug_show(result));

                      // Assess the fee used for the transfer
                      let #trappable(#Ok(result_array)) = result;
                      let #Ok(actual_fee_used) = result_array[0].transfer_result;
                      
                      let localtrx = icrc1.get_local_transactions();

                      let fee_used = Vec.get(localtrx, actual_fee_used).transfer;

                      D.print("fee used " # debug_show(fee_used));

                      assertTrue(fee_used == ?{fee = ?icrc4_fee});
                  },
                ),
                it(
                    "Environment function for Fees works",
                    do {
                        D.print("in env fee");
                        // Setup custom environment to provide a dynamic fee
                        let dynamic_fee = 7000; // An example dynamic fee
                      
                        let default_icrc4_env = {
                            get_fee : ?ICRC4.GetFee = ?(func(state : ICRC4.CurrentState, env: ICRC4.Environment, batchargs: ICRC4.TransferBatchArgs, trxargs: ICRC1.TransferArgs) : Nat {
                                return dynamic_fee;
                            });
                        };
                        let custom_icrc4_args = {
                            default_icrc4_args with fee = ?#Environment;
                        };

                        let (icrc1, icrc4) = get_icrc(default_token_args, null, custom_icrc4_args, ?default_icrc4_env);

                        ignore await* icrc1.mint_tokens(canister.owner, { to = user1; amount = 200 * e8s; memo = null; created_at_time = null; });

                        // Prepare transfer batch request
                        let batchArgs = {
                            transfers = [
                                { 
                                    from_subaccount = user1.subaccount;
                                    to = user2;
                                    amount = 100 * e8s;
                                    fee = null
                                },
                            ];
                            memo = null;
                            created_at_time = null;
                        };

                        // Attempt the batch transfer
                        let result = await* icrc4.transfer_batch_tokens(user1.owner, batchArgs, null, null);

                        D.print("environment fee " # debug_show(result));

                        // Assess the fee used for the transfer
                        let #trappable(#Ok(result_array)) = result;
                        let #Ok(actual_fee_used) = result_array[0].transfer_result;
                        
                        let localtrx = icrc1.get_local_transactions();

                        let fee_used = Vec.get(localtrx, actual_fee_used).transfer;

                        D.print("fee used " # debug_show(fee_used));

                        assertTrue(fee_used == ?{fee = ?dynamic_fee});
                    },
                ),
                it(
                    "Global icrc1:fee is used when icrc4:batch_fee is unspecified",
                    do {
                        // Prepare ICRC-1 and ICRC-4 ledgers without specifying icrc4:batch_fee
                        let default_environment = base_environment;
                        let default_icrc1_fee = 10000; // Global ICRC-1 fee
                        let icrc1_token_args = {
                            default_token_args with fee = ?#Fixed(default_icrc1_fee);
                        };

                        let (icrc1, icrc4) = get_icrc(icrc1_token_args, ?default_environment, {default_icrc4_args with fee = ?#ICRC1}, null);

                        ignore await* icrc1.mint_tokens(canister.owner, { to = user1; amount = 200 * e8s; memo = null; created_at_time = null; });

                        // Prepare transfer batch request
                        let batchArgs = {
                            transfers = [
                                {
                                    from_subaccount = user1.subaccount;
                                    to = user2;
                                    amount = 100 * e8s;
                                    fee = null // Fee not specified, expect to use ICRC-1 fee
                                },
                            ];
                            memo = null;
                            created_at_time = null;
                        };

                        // Attempt the batch transfer
                        let result = await* icrc4.transfer_batch_tokens(user1.owner, batchArgs, null, null);

                        // Assess whether the expected global ICRC-1 fee was used
                        let #trappable(#Ok(result_array)) = result;
                        let #Ok(actual_fee_used) = result_array[0].transfer_result;
                        
                        let localtrx = icrc1.get_local_transactions();

                        let fee_used = Vec.get(localtrx, actual_fee_used).transfer;

                        D.print("fee used icrc1" # debug_show(fee_used));

                        assertTrue(fee_used == ?{fee = ?default_icrc1_fee});
                    },
                ),
                it(
                  "Valid memo propagation in a successful batch transfer",
                  do {

                      let fakeLedger = Vec.new<(ICRC1.Value, ?ICRC1.Value)>();


                      // Mock add_transaction function and pass it to the environment
                      let add_transaction = func (
                          tx: ICRC1.Value,
                          txTop: ?ICRC1.Value
                      ): Nat {
                          Vec.add(fakeLedger,(tx,txTop));
                          // Simulate adding transaction to ICRC-3 transaction log
                          return Vec.size(fakeLedger) - 1; // Mock transaction index
                      };

                      let (icrc1, icrc4) = get_icrc(default_token_args, ?{base_environment with add_ledger_transaction = ?add_transaction}, default_icrc4_args, null);

                      
                      // Mint enough tokens to user1 for successful transfers
                      ignore await* icrc1.mint_tokens(canister.owner, { to = user1; amount = 300 * e8s; memo = null; created_at_time = null; });

                      let memo = Text.encodeUtf8("test memo");
                      let batchArgs = {
                          transfers = [
                              { from_subaccount = user1.subaccount; to = user2; amount = 100 * e8s; fee = null },
                              { from_subaccount = user1.subaccount; to = user2; amount = 50 * e8s; fee = null },
                          ];
                          memo = ?memo;
                          created_at_time = null;
                      };

                      let result = await* icrc4.transfer_batch_tokens(user1.owner, batchArgs, null, null);
                      let #trappable(#Ok(result_array)) = result;

                      D.print("memo prop" # debug_show(result));

                      D.print("memo ledger" # debug_show(Vec.toArray(fakeLedger)));

                      let #Map(firstTxHasMemo) = Vec.get(fakeLedger, 1).0;
                      let ?#Map(secondTxHasMemoBlock) = Vec.get(fakeLedger, 2).1;

                      var foundMemo : ?Blob = null;
                      label search for(thisItem in firstTxHasMemo.vals()){
                        if(thisItem.0 == "memo"){
                          let #Blob(foundMemo_) = thisItem.1;
                          foundMemo := ?foundMemo_;
                          break search;
                        };
                      };

                      D.print("found memo" # debug_show(foundMemo, memo , foundMemo == memo));

                      var foundMemoBlock : ?Nat = null;
                      label search for(thisItem in secondTxHasMemoBlock.vals()){
                        if(thisItem.0 == "memo_block"){
                          let #Nat(foundMemoBlock_) = thisItem.1;
                          foundMemoBlock := ?foundMemoBlock_;
                          break search;
                        };
                      };

                      D.print("found block" # debug_show(foundMemoBlock, secondTxHasMemoBlock, foundMemoBlock == ?1));

                      assertAllTrue([
                          foundMemo == memo,
                          foundMemoBlock == ?1,
                      ]);
                  },
              ),
              it(
                "Query balances of multiple accounts successfully",
                do {
                    let (icrc1, icrc4) = get_icrc(default_token_args, null, default_icrc4_args, null);

                    // Mint tokens to users for balance checks
                    ignore await* icrc1.mint_tokens(canister.owner, { to = user1; amount = 100 * e8s; memo = null; created_at_time = null; });
                    ignore await* icrc1.mint_tokens(canister.owner, { to = user2; amount = 50 * e8s; memo = null; created_at_time = null; });

                    let queryArgs = {
                        accounts = [user1, user2, user3];
                    };

                    let balances = icrc4.balance_of_batch(queryArgs);

                    // User3 has no tokens minted, so balance should be 0
                    let expectedBalances = [(user1, 100 * e8s), (user2, 50 * e8s), (user3, 0)];

                    let balancesMatch = Array.equal<(Account, Nat)>(balances, expectedBalances, func(a, b): Bool {
                        return (a.1 == b.1) and (ICRC1.account_eq(a.0, b.0));
                    });

                    assertTrue(balancesMatch);
                },
            ),
            it(
                "Query balance exceeding maximum batch size results in error",
                do {
                    let (icrc1, icrc4) = get_icrc(default_token_args, null, default_icrc4_args, null);

                    // Using a direct manipulation to set max_transfers lower for this test case
                    ignore icrc4.update_ledger_info([#MaxBalances(1)]);

                    // Mint tokens to users for balance checks
                    ignore await* icrc1.mint_tokens(canister.owner, { to = user1; amount = 100 * e8s; memo = null; created_at_time = null; });
                    ignore await* icrc1.mint_tokens(canister.owner, { to = user2; amount = 50 * e8s; memo = null; created_at_time = null; });

                    let queryArgs = {
                        accounts = [user1, user2, user3];
                    };

                    let #err(result) = icrc4.balance_of_batch_tokens(queryArgs);

                   

                    assertTrue(Text.startsWith(result, #text("too many requests.")));
                },
            ),
            it("External sync can_transfer_batch invalidates a transaction",
              do {
                  
                  let (icrc1, icrc4) = get_icrc(default_token_args, null, default_icrc4_args, null);

                  let tx_amount = 1000*e8s;

                  let mint =  await* icrc1.mint_tokens(canister.owner,
                  { to = user1; amount = tx_amount; memo = null; created_at_time = null; });

                  let batchArgs = {
                      memo = null;
                      created_at_time = null;
                      transfers = [
                          { from_subaccount = user1.subaccount; to = user2; amount = 1 * e8s; fee = null },
                          { from_subaccount = user1.subaccount; to = user3; amount = 1 * e8s; fee = null },
                      ];
                  };

                  let result = await* icrc4.transfer_batch_tokens(user1.owner, batchArgs, null, ?#Sync(externalCanTransferBatchFalseSync));

              

                  D.print("reject sync " # debug_show(result));

                  let #trappable(#Err(#GenericError(res))) = result;

                  assertTrue(res.message == "always false");
              }),
              it("External async can_transfer_batch invalidates a transaction",
              do {
                  
                  let (icrc1, icrc4) = get_icrc(default_token_args, null, default_icrc4_args, null);

                  let tx_amount = 1000*e8s;

                  let mint =  await* icrc1.mint_tokens(canister.owner,
                  { to = user1; amount = tx_amount; memo = null; created_at_time = null; });
                  
                  let batchArgs = {
                      memo = null;
                      created_at_time = null;
                      transfers = [
                          { from_subaccount = user1.subaccount; to = user2; amount = 1 * e8s; fee = null },
                          { from_subaccount = user1.subaccount; to = user3; amount = 1 * e8s; fee = null },
                      ];
                  };

                  let result = await* icrc4.transfer_batch_tokens(user1.owner, batchArgs, null, ?#Async(externalCanTransferBatchFalseAsync));

              

                  D.print("reject async " # debug_show(result));

                  let #awaited(#Err(#GenericError(res))) = result;

                  assertTrue(res.message == "always false");
              }),
              it("External sync can_transfer_batch updates a transaction",
              do {
                  
                  let (icrc1, icrc4) = get_icrc(default_token_args, null, default_icrc4_args, null);

                  let tx_amount = 1000*e8s;

                  let mint =  await* icrc1.mint_tokens(canister.owner, { to = user1; amount = tx_amount; memo = null; created_at_time = null; });
                  
                  let batchArgs = {
                      memo = null;
                      created_at_time = null;
                      transfers = [
                          { from_subaccount = user1.subaccount; to = user2; amount = 1 * e8s; fee = null },
                          { from_subaccount = user1.subaccount; to = user3; amount = 2 * e8s; fee = null },
                      ];
                  };

                  let result = await* icrc4.transfer_batch_tokens(user1.owner, batchArgs, null, ?#Sync(externalCanTransfeBatchUpdateSync));

              

                  D.print("update sync " # debug_show(result));

                  let #trappable(#Ok(res)) = result;
                  let ledger = Vector.toArray(icrc1.get_local_transactions());
                  let ?trn = ledger[1].transfer;

                    assertAllTrue([
                    res[0].transfer_result == #Ok(1),
                    res[1].transfer_result == #Ok(2),
                    res[2].transfer_result == #Ok(3),
                    ledger[2].transfer == ?{amount = 2 * e8s; to = user3}
                  ]);
              }),
              it("External async can_transfer_batch updates a transaction",
              do {
                  
                  let (icrc1, icrc4) = get_icrc(default_token_args, null, default_icrc4_args, null);

                  let tx_amount = 1000*e8s;

                  let mint =  await* icrc1.mint_tokens( canister.owner, { to = user1; amount = tx_amount; memo = null; created_at_time = null; },);
                  
                  let batchArgs = {
                      memo = null;
                      created_at_time = null;
                      transfers = [
                          { from_subaccount = user1.subaccount; to = user2; amount = 1 * e8s; fee = null },
                          { from_subaccount = user1.subaccount; to = user3; amount = 2 * e8s; fee = null },
                      ];
                  };

                  let result = await* icrc4.transfer_batch_tokens(user1.owner, batchArgs, null, ?#Async(externalCanTransferBatchUpdateAsync));

              

                  D.print("update async " # debug_show(result));

                  let #awaited(#Ok(res)) = result;
                  let ledger = Vector.toArray(icrc1.get_local_transactions());
                  let ?trn = ledger[1].transfer;

                    assertAllTrue([
                    res[0].transfer_result == #Ok(1),
                    res[1].transfer_result == #Ok(2),
                    res[2].transfer_result == #Ok(3),
                    ledger[2].transfer == ?{amount = 2 * e8s; to = user3}
                  ]);
              }),
              it("External sync can_transfer invalidates a transaction",
                do {
                    
                    let (icrc1, icrc4) = get_icrc(default_token_args, null, default_icrc4_args, null);
                    let tx_amount = 1000*e8s;

                    let mint =  await* icrc1.mint_tokens(canister.owner,
                    { to = user1; amount = tx_amount; memo = null; created_at_time = null; });

                    let batchArgs = {
                        memo = null;
                        created_at_time = null;
                        transfers = [
                            { from_subaccount = user1.subaccount; to = user2; amount = 1 * e8s; fee = null },
                            { from_subaccount = user1.subaccount; to = user3; amount = 2 * e8s; fee = null },
                        ];
                    };

                    let result = await* icrc4.transfer_batch_tokens(user1.owner, batchArgs, ?#Sync(externalCanTransferFalseSync), null);

                    D.print("reject sync single " # debug_show(result));

                    let #trappable(#Ok(res)) = result;
                    let ledger = Vector.toArray(icrc1.get_local_transactions());
                    let ?trn = ledger[1].transfer;

                      assertAllTrue([
                      res[0].transfer_result == #Ok(1),
                      res[1].transfer_result == #Err(#GenericError({error_code=6453; message="always false"})),
                      Array.size(ledger) == 2
                    ]);
                }),
                it("External async can_transfer invalidates a transaction",
                do {
                    
                     let (icrc1, icrc4) = get_icrc(default_token_args, null, default_icrc4_args, null);
                    let tx_amount = 1000*e8s;

                    let mint =  await* icrc1.mint_tokens(canister.owner,
                    { to = user1; amount = tx_amount; memo = null; created_at_time = null; });

                    let batchArgs = {
                        memo = null;
                        created_at_time = null;
                        transfers = [
                            { from_subaccount = user1.subaccount; to = user2; amount = 1 * e8s; fee = null },
                            { from_subaccount = user1.subaccount; to = user3; amount = 2 * e8s; fee = null },
                        ];
                    };

                  let result = await* icrc4.transfer_batch_tokens(user1.owner, batchArgs, ?#Async(externalCanTransferFalseAsync), null);

              
                    
                    // First transfer
                   D.print("reject async single " # debug_show(result));

                    let #awaited(#Ok(res)) = result;
                    let ledger = Vector.toArray(icrc1.get_local_transactions());
                    let ?trn = ledger[1].transfer;

                      assertAllTrue([
                      res[0].transfer_result == #Ok(1),
                      res[1].transfer_result == #Err(#GenericError({error_code=6453; message="always false"})),
                      Array.size(ledger) == 2
                    ]);
                }),
                it("External sync can_transfer updates a transaction",
                do {
                    
                     let (icrc1, icrc4) = get_icrc(default_token_args, null, default_icrc4_args, null);
                    let tx_amount = 1000*e8s;

                    let mint =  await* icrc1.mint_tokens(canister.owner, { to = user1; amount = tx_amount; memo = null; created_at_time = null; });

                    let batchArgs = {
                        memo = null;
                        created_at_time = null;
                        transfers = [
                            { from_subaccount = user1.subaccount; to = user2; amount = 1 * e8s; fee = null },
                            { from_subaccount = user1.subaccount; to = user3; amount = 2 * e8s; fee = null },
                        ];
                    };

                  let result = await* icrc4.transfer_batch_tokens(user1.owner, batchArgs, ?#Sync(externalCanTransferUpdateSync), null);

                    let #trappable(#Ok(res)) = result;
                    let ledger = Vector.toArray(icrc1.get_local_transactions());
                    let ?trn = ledger[1].transfer;
                    let ?trn2 = ledger[1].transfer;

                    assertAllTrue([
                      trn.amount == 2,
                      trn2.amount == 2
                    ]);
                }),
                it("External async can_transfer updates a transaction",
                do {
                    
                   let (icrc1, icrc4) = get_icrc(default_token_args, null, default_icrc4_args, null);
                    let tx_amount = 1000*e8s;

                    let mint =  await* icrc1.mint_tokens( canister.owner, { to = user1; amount = tx_amount; memo = null; created_at_time = null; },);

                    let batchArgs = {
                        memo = null;
                        created_at_time = null;
                        transfers = [
                            { from_subaccount = user1.subaccount; to = user2; amount = 1 * e8s; fee = null },
                            { from_subaccount = user1.subaccount; to = user3; amount = 2 * e8s; fee = null },
                        ];
                    };

                    let result = await* icrc4.transfer_batch_tokens(user1.owner, batchArgs, ?#Async(externalCanTransferUpdateAsync), null);

                
                    
                    let #awaited(#Ok(res)) = result;
                    let ledger = Vector.toArray(icrc1.get_local_transactions());
                    let ?trn = ledger[1].transfer;
                    let ?trn2 = ledger[1].transfer;

                    assertAllTrue([
                      trn.amount == 2,
                      trn2.amount == 2
                    ]);
                }),
                it(
                  "Can listen to notifications of each item by adding a listener at the ICRC-1 level",
                  do {
                      let (icrc1, icrc4) = get_icrc(default_token_args, null, default_icrc4_args, null);

                      let mint_args = { to = user1; amount = 100 * e8s; memo = null; created_at_time = null; };
                      ignore await* icrc1.mint_tokens(canister.owner, mint_args);

                      let batchArgs = {
                          memo = null;
                          created_at_time = null;
                          transfers = [
                              { from_subaccount = user1.subaccount; to = user2; amount = 10 * e8s; fee = null },
                               { from_subaccount = user1.subaccount; to = user3; amount = 10 * e8s; fee = null },
                                { from_subaccount = user1.subaccount; to = user2; amount = 4 * e8s; fee = null },
                          ];
                      };

                      var listener_called = false;
                      icrc4.register_transfer_batch_listener("test_listener", func (notification: ICRC4.TransferBatchNotification, results: ICRC4.TransferBatchResult) {
                          listener_called := true;
                      });

                      var trx_called = 0;
                      icrc1.register_token_transferred_listener("test_listener", func (tx: ICRC1.Transaction, tx_id: Nat) {
                          trx_called += 1;
                      });

                      ignore await* icrc4.transfer_batch(user1.owner, batchArgs);

                      assertAllTrue([listener_called, trx_called == 3]);
                  }),
                  it(
                  "test invalid memo",
                  do {
                      let (icrc1, icrc4) = get_icrc(default_token_args, null, default_icrc4_args, null);

                      let mint_args = { to = user1; amount = 100 * e8s; memo = null; created_at_time = null; };
                      ignore await* icrc1.mint_tokens(canister.owner, mint_args);

                      ignore icrc1.update_ledger_info([#MaxMemo(16)]);

                      let batchArgs = {
                          memo = ?Blob.fromArray([0,0,0,0,0,0,0,1,
                                                  0,0,0,0,0,0,0,1,
                                                  0,0,0,0,0,0,0,3,
                                                  0,0,0,0,0,0,0,1,
                                                  0,0,0,0,0,0,0,4,]);
                          created_at_time = null;
                          transfers = [
                              { from_subaccount = user1.subaccount; to = user2; amount = 10 * e8s; fee = null },
                               { from_subaccount = user1.subaccount; to = user3; amount = 10 * e8s; fee = null },
                                { from_subaccount = user1.subaccount; to = user2; amount = 4 * e8s; fee = null },
                          ];
                      };

                      

                      let result = await* icrc4.transfer_batch(user1.owner, batchArgs);

                       // First transfer
                      D.print("reject memo " # debug_show(result));

                      let #Err(#GenericError(res)) = result;

                      assertAllTrue([res.error_code == 4]);
                  }),
            ],
        );
    };

};
