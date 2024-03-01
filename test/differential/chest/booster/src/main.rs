use alloy_primitives::{U128, U256, U32, U64};
use std::env;

fn booster(
    vesting_duration: U32,
    cliff_timestamp: U64,
    booster_timestamp: U64,
    current_timestamp: U64,
    accumulated_booster: U128,
    max_booster: U128,
) -> U128 {
    let initial_booster: U128 = U128::from(1_000_000_000_000_000_000u64);
    let time_factor: U64 = U64::from(7 * 24 * 60 * 60);
    let weekly_booster_increment = U128::from(6_410_256_410_256_410u64);

    if vesting_duration > U32::from(0) {
        return initial_booster;
    }

    if booster_timestamp == U64::from(0) {
        return initial_booster;
    }

    let timestamp: U64 = if cliff_timestamp > current_timestamp {
        current_timestamp
    } else {
        cliff_timestamp
    };

    let weeks_passed: U64 = (timestamp - booster_timestamp).div_ceil(time_factor);
    let booster: U128 = accumulated_booster + U128::from(weeks_passed) * weekly_booster_increment;

    if booster > max_booster {
        return max_booster;
    }

    return booster;
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let vesting_duration: U32 = args[1]
        .parse::<U32>()
        .expect("Can't parse vesting duration");
    let cliff_timestamp: U64 = args[2]
        .parse::<U64>()
        .expect("Can't parse cliff timestamp");
    let booster_timestamp: U64 = args[3]
        .parse::<U64>()
        .expect("Can't parse booster timestamp");
    let current_timestamp: U64 = args[4]
        .parse::<U64>()
        .expect("Can't parse current timestamp");
    let accumulated_booster: U128 = args[5]
        .parse::<U128>()
        .expect("Can't parse accumulated booster");
    let max_booster: U128 = args[6].parse::<U128>().expect("Can't parse max booster");

    let booster = booster(
        vesting_duration,
        cliff_timestamp,
        booster_timestamp,
        current_timestamp,
        accumulated_booster,
        max_booster,
    );

    if booster == U128::from(0) {
        // NOTE - This is needed as the ffi returns 0x307830 as result and then it decode as non zero value
        print!("0x{number:0>64x}", number = 0);
    } else {
        print!("{:#x}", U256::from(booster));
    }
}
