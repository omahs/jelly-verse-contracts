use alloy_primitives::{U256, I256};
use std::env;
use std::convert::TryInto;

fn minter(number_of_days_since_minting_started: I256) -> U256 {
    let days: i128 = number_of_days_since_minting_started
        .try_into()
        .expect("Value too large for i128");

    let days_f64 = days as f64;
    let result = 900_000.0 * f64::exp(-0.0015 * days_f64);

    U256::from(result as u128)
}


fn main() {
    let args: Vec<String> = env::args().collect();
    let number_of_days_since_minting_started: I256 = args[1]
        .parse::<I256>()
        .expect("Can't parse number of days since minting started");

    let mint_amount = minter(number_of_days_since_minting_started);

    if mint_amount == U256::from(0) {
        // NOTE - This is needed as the ffi returns 0x307830 as result and then it decode as non zero value
        print!("0x{number:0>64x}", number = 0);
    } else {
        print!("{:#x}", mint_amount);
    }
}
