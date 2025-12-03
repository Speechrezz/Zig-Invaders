const std = @import("std");
const rl = @import("raylib");
const Game = @import("Game.zig");

const Shield = @This();

const shield_width = 80.0;
const shield_height = 60.0;

const num_shields = 4;
const shield_spacing = 100.0;

const shield_health = 10;

bounds: rl.Rectangle,
health: i32 = shield_health,

pub fn init(self: *@This(), position: rl.Vector2) void {
    self.* = .{
        .bounds = .{
            .x = position.x,
            .y = position.y,
            .width = shield_width,
            .height = shield_height,
        },
    };
}

pub fn update(self: *@This(), game: *Game) void {
    if (self.health == 0) return;

    if (game.player_bullet.is_active and self.bounds.checkCollision(game.player_bullet.bounds)) {
        game.player_bullet.is_active = false;
        self.health -= 1;
    }

    for (&game.enemy_bullet_pool.bullet_list) |*bullet| {
        if (bullet.is_active and self.bounds.checkCollision(bullet.bounds)) {
            bullet.is_active = false;
            self.health -= 1;
        }
    }
}

pub fn draw(self: @This()) void {
    if (self.health == 0) return;

    var alpha = @as(f32, @floatFromInt(self.health)) / @as(f32, @floatFromInt(shield_health));
    alpha = 0.1 + 0.9 * alpha;

    rl.drawRectangleRounded(
        self.bounds,
        0.2,
        4,
        rl.colorAlpha(.green, alpha),
    );
}

pub const Group = struct {
    shields: [num_shields]Shield = undefined,

    pub fn init(self: *@This(), bounds: rl.Rectangle) void {
        self.* = .{};

        for (&self.shields, 0..) |*shield, i| {
            const ratio_x = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(num_shields - 1));

            const position = rl.Vector2{
                .x = bounds.x + ratio_x * (bounds.width - shield_width),
                .y = bounds.y,
            };

            shield.init(position);
        }
    }

    pub fn update(self: *@This(), game: *Game) void {
        for (&self.shields) |*shield| {
            shield.update(game);
        }
    }

    pub fn draw(self: *@This()) void {
        for (&self.shields) |*shield| {
            shield.draw();
        }
    }
};
