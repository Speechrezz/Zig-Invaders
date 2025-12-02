const std = @import("std");

pub fn getRandomInt(min: i32, max: i32) !i32 {
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random = prng.random();
    return random.intRangeAtMost(i32, min, max);
}
