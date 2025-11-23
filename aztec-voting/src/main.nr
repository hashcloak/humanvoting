use dep::aztec::macros::aztec;

#[aztec]
pub contract Vote {
    use aztec::context;
    use aztec::macros::functions::external;
    use aztec::{macros::storage::{self, storage}, state_vars::{Map, PublicMutable}};
    use aztec::protocol_types::address::AztecAddress;
    use aztec::protocol_types::traits::FromField;
    use poseidon::poseidon2::Poseidon2;
    use semaphore::Semaphore;

    #[storage]
    struct Storage<Context> {
        vote_counts: Map<Field, PublicMutable<Field, Context>, Context>, // (candidate -> vote_count)
    }

    #[contract_library_method]
    fn poseidon2_hash_2(input: [Field; 2]) -> Field {
        Poseidon2::hash(input, 2)
    }

    global MAX_DEPTH: u32 = 10;
    // This is a 251 bit value.
    global L: Field = 2736030358979909402780800718157159386076813972158567259200215660948447373041;

    // Generator point of Baby Jubjub curve.
    // ref: https://github.com/noir-lang/noir-edwards/blob/main/src/test.nr#L6C8-L6C13
    global BASE8: [Field; 2] = [
        5299619240641551281634865583518297030282874472190772894086521144482721001553,
        16950150798460657717958625567821834550301663161624707787222815936182638968203,
    ];

    global SEMAPHOREADDRESS: AztecAddress = AztecAddress::from_field(0x1);

    #[external("public")]
    fn call_back(candidate: Field) {
        assert(context.msg_sender().unwrap() == SEMAPHOREADDRESS);
        let new_count = storage.vote_counts.at(candidate).read() + 1;
        storage.vote_counts.at(candidate).write(new_count);
    }

    #[external("public")]
    fn callback(candidate: Field) {
        storage.vote_counts.at(candidate).write(
            storage.vote_counts.at(candidate).read() + Field::from(1),
        );
    }

    #[external("private")]
    fn vote(
        secret_key: Field,
        index_bits: [u1; MAX_DEPTH], // these bits indicate the order of inputs for hashing of the merkle proof
        hash_path: [Field; MAX_DEPTH], // the Merkle Tree inclusion proof
        merkle_proof_length: u32, // the number of non-zero elements in hash_path
        hashed_scope: Field,
        passport_id: Field,
        candidate: Field,
        semaphore_address: AztecAddress,
        group_id: Field,
        tree_address: AztecAddress,
    ) {
        Semaphore::at(semaphore_address)
            .verify_proof(
                secret_key,
                passport_id,
                index_bits,
                hash_path,
                merkle_proof_length,
                hashed_scope,
                candidate,
                group_id,
                tree_address,
            )
            .call(&mut context);
    }

    #[external("utility")]
    unconstrained fn get_vote(candidate: Field) -> Field {
        storage.vote_counts.at(candidate).read()
    }

}
