use alloy_primitives::{U128, U256, U32, U64};
use std::env;

const TIME_FACTOR: u32 = 7 * 24 * 60 * 60; // 7 days in seconds

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

    let weeks_passed: U64 = (timestamp - booster_timestamp) / time_factor;
    let booster: U128 = accumulated_booster + U128::from(weeks_passed) * weekly_booster_increment;

    if booster > max_booster {
        return max_booster;
    }

    return booster;
}

fn power(
    timestamp: U256,
    amount: U256,
    cliff_timestamp: U256,
    vesting_duration: U256,
    accumulated_booster: U256,
    nerf_parameter: U256,
    booster_timestamp: U64,
) -> U256 {
    let decimals: U256 = U256::from(1_000_000_000_000_000_000u64);
    let min_amount: U256 = U256::from(1_000_000_000_000_000_000_000u128);
    let unfreeze_time: U256 = cliff_timestamp + vesting_duration;
    let max_booster: U128 = U128::from(2_000_000_000_000_000_000u64);

    if timestamp > unfreeze_time {
        return U256::from(0);
    }

    let regular_freezing_time: U256;

    if cliff_timestamp > timestamp {
        regular_freezing_time = (cliff_timestamp - timestamp).div_ceil(U256::from(TIME_FACTOR));
    } else {
        regular_freezing_time = U256::from(0);
    }

    if vesting_duration == U256::from(0) {
        let booster_value = booster(
            U32::from(vesting_duration),
            U64::from(cliff_timestamp),
            booster_timestamp,
            U64::from(timestamp),
            U128::from(accumulated_booster),
            max_booster
        );

        return (U256::from(booster_value) * amount * regular_freezing_time) / (decimals * min_amount);
    } else {
        let linear_freezing_time: U256;
        if timestamp < cliff_timestamp {
            linear_freezing_time =
                vesting_duration.div_ceil(U256::from(TIME_FACTOR)) / U256::from(2);
        } else {
            linear_freezing_time =
                (unfreeze_time - timestamp).div_ceil(U256::from(TIME_FACTOR)) / U256::from(2);
        }
        return amount * (regular_freezing_time + linear_freezing_time) * nerf_parameter
            / (U256::from(10) * min_amount);
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let timestamp: U256 = args[1].parse::<U256>().expect("Can't parse timestamp");
    let amount: U256 = args[2].parse::<U256>().expect("Can't parse amount");
    let cliff_timestamp: U256 = args[3]
        .parse::<U256>()
        .expect("Can't parse cliff timestamp");
    let vesting_duration: U256 = args[4]
        .parse::<U256>()
        .expect("Can't parse vesting duration");
    let accumulated_booster: U256 = args[5].parse::<U256>().expect("Can't parse booster");
    let nerf_parameter: U256 = args[6].parse::<U256>().expect("Can't parse nerf parameter");
    let booster_timestamp: U64 = args[7].parse::<U64>().expect("Can't parse booster timestamp");

    let power = power(
        timestamp,
        amount,
        cliff_timestamp,
        vesting_duration,
        accumulated_booster,
        nerf_parameter,
        booster_timestamp,
    );

    if power == U256::from(0) {
        // NOTE - This is needed as the ffi returns 0x307830 as result and then it decode as non zero value
        print!("0x{number:0>64x}", number = 0);
    } else {
        print!("{:#x}", power);
    }
}
