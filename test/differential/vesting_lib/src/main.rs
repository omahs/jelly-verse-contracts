use alloy_primitives::{U256, U32, U64};
use std::env;

fn vested_amount(
    total_vested_amount: U256,
    block_timestamp: U64,
    cliff_timestamp: U64,
    vesting_duration: U32,
) -> U256 {
    if block_timestamp < cliff_timestamp {
        return U256::from(0);
    } else if block_timestamp >= (cliff_timestamp + U64::from(vesting_duration)) {
        return total_vested_amount;
    } else {
        return total_vested_amount * U256::from(block_timestamp - cliff_timestamp)
            / U256::from(vesting_duration);
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let total_vested_amount: U256 = args[1]
        .parse::<U256>()
        .expect("Can't parse total vested amount");
    let block_timestamp: U64 = args[2].parse::<U64>().expect("Can't parse block timestamp");
    let cliff_timestamp: U64 = args[3]
        .parse::<U64>()
        .expect("Can't parse cliff timestampt");
    let vesting_duration: U32 = args[4].parse::<U32>().expect("Can't parse total duration");

    let vested_amount = vested_amount(
        total_vested_amount,
        block_timestamp,
        cliff_timestamp,
        vesting_duration,
    );

    if vested_amount == U256::from(0) {
        // NOTE - This is needed as the ffi returns 0x307830 as result and then it decode as non zero value
        print!("0x{number:0>64x}", number = 0);
    } else {
        print!("{:#x}", vested_amount);
    }
}
