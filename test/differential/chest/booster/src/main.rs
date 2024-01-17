use alloy_primitives::{U128, U256, U32};
use std::env;

const THREE_YEARS_IN_SECONDS: u32 = 3 * 365 * 24 * 60 * 60;

fn booster(
    freezing_period: U32,
    vesting_duration: U32,
    current_booster: U128,
    max_booster: U128,
) -> U128 {
    let initial_booster: U128 = U128::from(1_000_000_000_000_000_000u64);
    let max_freezing_period: U32 = U32::from(THREE_YEARS_IN_SECONDS);

    if vesting_duration > U32::from(0) {
        return initial_booster;
    }

    let booster: U128 = current_booster
        + ((U128::from(freezing_period) * (max_booster - initial_booster))
            / U128::from(max_freezing_period));

    if booster > max_booster {
        return max_booster;
    }

    return booster;
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let freezing_period: U32 = args[1].parse::<U32>().expect("Can't parse freezing period");
    let vesting_duration: U32 = args[2]
        .parse::<U32>()
        .expect("Can't parse vesting duration");
    let current_booster: U128 = args[3]
        .parse::<U128>()
        .expect("Can't parse current booster");
    let max_booster: U128 = args[4].parse::<U128>().expect("Can't parse max booster");

    let booster = booster(
        freezing_period,
        vesting_duration,
        current_booster,
        max_booster,
    );

    if booster == U128::from(0) {
        // NOTE - This is needed as the ffi returns 0x307830 as result and then it decode as non zero value
        print!("0x{number:0>64x}", number = 0);
    } else {
        print!("{:#x}", U256::from(booster));
    }
}
