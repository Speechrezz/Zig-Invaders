const std = @import("std");
const rl = @import("raylib");
const Game = @import("Game.zig");
const Player = @import("Player.zig");

var game: Game = undefined;

pub fn main() !void {
    const screen_width = 800;
    const screen_height = 800;

    game.init(screen_width, screen_height);

    rl.initWindow(game.level.screen_width, game.level.screen_height, "Zig Invaders");
    defer rl.closeWindow();

    const refresh_rate = rl.getMonitorRefreshRate(0);
    std.debug.print("Refresh rate: {}\n", .{refresh_rate});
    rl.setTargetFPS(refresh_rate);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        const delta_time = rl.getFrameTime();
        game.update(delta_time);
        game.draw();
    }
}
