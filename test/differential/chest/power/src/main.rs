use alloy_primitives::U256;
use std::env;

const TIME_FACTOR: u8 = 2;

fn power(
    timestamp: U256,
    amount: U256,
    cliff_timestamp: U256,
    vesting_duration: U256,
    booster: U256,
    nerf_parameter: U256,
) -> U256 {
    let decimals: U256 = U256::from(1_000_000_000_000_000_000u64);

    if timestamp > cliff_timestamp + vesting_duration {
        return U256::from(0);
    }
    let unfreezing_time: U256;

    if timestamp > cliff_timestamp {
        let vesting_end_time: U256 = cliff_timestamp + vesting_duration;
        unfreezing_time = (vesting_end_time - timestamp) / U256::from(TIME_FACTOR);
    } else {
        unfreezing_time = cliff_timestamp - timestamp;
    }

    if vesting_duration == U256::from(0) {
        return booster * amount * unfreezing_time / decimals;
    } else {
        return amount * unfreezing_time * nerf_parameter / U256::from(10);
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
    let booster: U256 = args[5].parse::<U256>().expect("Can't parse booster");
    let nerf_parameter: U256 = args[6].parse::<U256>().expect("Can't parse nerf parameter");

    let power = power(
        timestamp,
        amount,
        cliff_timestamp,
        vesting_duration,
        booster,
        nerf_parameter,
    );

    if power == U256::from(0) {
        // NOTE - This is needed as the ffi returns 0x307830 as result and then it decode as non zero value
        print!("0x{number:0>64x}", number = 0);
    } else {
        print!("{:#x}", power);
    }
}
