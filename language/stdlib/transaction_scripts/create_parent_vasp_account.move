script {
use 0x1::LibraAccount;
use 0x1::SlidingNonce;

/// # Summary
/// Creates a Parent VASP account with the specified human name. Must be called by the Treasury Compliance account.
///
/// # Technical Description
/// Creates an account with the Parent VASP role at `address` with authentication key
/// `auth_key_prefix` | `new_account_address` and a 0 balance of type `CoinType`. If
/// `add_all_currencies` is true, 0 balances for all available currencies in the system will
/// also be added. This can only be invoked by an TreasuryCompliance account.
/// `sliding_nonce` is a unique nonce for operation, see `SlidingNonce` for details.
///
/// # Parameters
/// | Name                  | Type         | Description                                                                                                                                                    |
/// | ------                | ------       | -------------                                                                                                                                                  |
/// | `CoinType`            | Type         | The Move type for the `CoinType` currency that the Parent VASP account should be initialized with. `CoinType` must be an already-registered currency on-chain. |
/// | `tc_account`          | `&signer`    | The signer reference of the sending account of this transaction. Must be the Treasury Compliance account.                                                      |
/// | `sliding_nonce`       | `u64`        | The `sliding_nonce` (see: `SlidingNonce`) to be used for this transaction.                                                                                     |
/// | `new_account_address` | `address`    | Address of the to-be-created Parent VASP account.                                                                                                              |
/// | `auth_key_prefix`     | `vector<u8>` | The authentication key prefix that will be used initially for the newly created account.                                                                       |
/// | `human_name`          | `vector<u8>` | ASCII-encoded human name for the Parent VASP.                                                                                                                  |
/// | `add_all_currencies`  | `bool`       | Whether to publish balance resources for all known currencies when the account is created.                                                                     |
///
/// # Common Abort Conditions
/// | Error Category              | Error Reason                            | Description                                                                                |
/// | ----------------            | --------------                          | -------------                                                                              |
/// | `Errors::INVALID_ARGUMENT`  | `SlidingNonce::ENONCE_TOO_OLD`          | The `sliding_nonce` is too old and it's impossible to determine if it's duplicated or not. |
/// | `Errors::INVALID_ARGUMENT`  | `SlidingNonce::ENONCE_TOO_NEW`          | The `sliding_nonce` is too far in the future.                                              |
/// | `Errors::INVALID_ARGUMENT`  | `SlidingNonce::ENONCE_ALREADY_RECORDED` | The `sliding_nonce` has been previously recorded.                                          |
/// | `Errors::REQUIRES_ADDRESS`  | `CoreAddresses::ETREASURY_COMPLIANCE`   | The sending account is the Treasury Compliance account.                                    |
/// | `Errors::NOT_PUBLISHED`     | `Libra::ECURRENCY_INFO`                 | The `CoinType` is not a registered currency on-chain.                                      |
/// | `Errors::ALREADY_PUBLISHED` | `Roles::EROLE_ID`                       | The `new_account_address` address is already taken.                                        |
///
/// # Related Scripts
/// * `Script::create_child_vasp_account`
/// * `Script::add_currency_to_account`
/// * `Script::rotate_authentication_key`
/// * `Script::add_recovery_rotation_capability`
/// * `Script::create_recovery_address`
/// * `Script::rotate_dual_attestation_info`

fun create_parent_vasp_account<CoinType>(
    tc_account: &signer,
    sliding_nonce: u64,
    new_account_address: address,
    auth_key_prefix: vector<u8>,
    human_name: vector<u8>,
    add_all_currencies: bool
) {
    SlidingNonce::record_nonce_or_abort(tc_account, sliding_nonce);
    LibraAccount::create_parent_vasp_account<CoinType>(
        tc_account,
        new_account_address,
        auth_key_prefix,
        human_name,
        add_all_currencies
    );
}

spec fun create_parent_vasp_account {
    use 0x1::Errors;

    include LibraAccount::TransactionChecks{sender: tc_account}; // properties checked by the prologue.
    include SlidingNonce::RecordNonceAbortsIf{account: tc_account, seq_nonce: sliding_nonce};
    include LibraAccount::CreateParentVASPAccountAbortsIf<CoinType>{creator_account: tc_account};
    include LibraAccount::CreateParentVASPAccountEnsures<CoinType>;

    aborts_with [check]
        Errors::INVALID_ARGUMENT,
        Errors::REQUIRES_ADDRESS,
        Errors::NOT_PUBLISHED,
        Errors::ALREADY_PUBLISHED,
        Errors::REQUIRES_ROLE; // TODO: undocumented abort code
                               // from Roles::AbortsIfNotTreasuryCompliance, occurs together with REQUIRES_ADDRESS

}
}
