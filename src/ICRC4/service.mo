module {
  public type Account = {
        owner : Principal;
        subaccount : ?Subaccount;
  };

  public type Subaccount = Blob;

  public type TransferArg =  {
    from_subaccount: ?Subaccount;
    to: Account;
    amount: Nat;
    fee: ?Nat
  };

  public type TransferError = {
      #BadFee : { expected_fee : Nat };
      #InsufficientFunds : { balance : Nat; needed_amount: Nat };
      #GenericError : { error_code : Nat; message : Text };
  };

  public type TransferBatchArgs =  {
      transfers: [TransferArg];
      memo: ?Blob;      // A single memo for batch-level deduplication
      created_at_time: ?Nat64;
  };

  public type TransferBatchError = {
      #TemporarilyUnavailable;
      #TooOld;
      #CreatedInFuture : { ledger_time: Nat64 };
      #Duplicate : { duplicate_of : Nat }; //todo: should this be different for batch since the items can go into many transactions
      #GenericError : { error_code : Nat; message : Text };
  };

  public type TransferBatchResult = {
      #Ok : [{
        transfer : TransferArg; //todo: do we need this?  Can we leave out memo? or is it helpful
        transfer_result : {
          #Ok : Nat; // Transaction indices for successful transfers
          #Err : TransferError
        };
      }];
      #Err : TransferBatchError;
  };

  public type BalanceQueryArgs = {
    accounts: [Account];
  };


  public type BalanceQueryResult = [(Account, Nat)]; 


  public type service = actor {
    icrc4_transfer_batch : (TransferBatchArgs) -> async (TransferBatchResult);
    icrc4_balance_of_batch : query (BalanceQueryResult) -> async  BalanceQueryResult;
  };
};