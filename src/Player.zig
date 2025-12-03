const std = @import("std");
const rl = @import("raylib");
const Game = @import("Game.zig");

bounds: rl.Rectangle,

pub fn init(self: *@This(), pos_x: f32, pos_y: f32) void {
    self.* = .{
        .bounds = .{
            .x = pos_x,
            .y = pos_y,
            .width = 40.0,
            .height = 24.0,
        },
    };
}

fn shoot(self: *@This(), game: *Game) void {
    game.player_bullet.shoot(.{
        .x = self.bounds.x + @divTrunc(self.bounds.width, 2),
        .y = self.bounds.y,
    });
}

fn checkLose(self: *@This(), game: *Game) void {
    for (game.enemy_bullet_pool.bullet_list) |enemy_bullet| {
        if (enemy_bullet.is_active and self.bounds.checkCollision(enemy_bullet.bounds)) {
            game.lose();
        }
    }

    for (game.enemy_group.alive_enemies.items) |enemy| {
        if (self.bounds.checkCollision(enemy.bounds)) {
            game.lose();
        }
    }
}

pub fn update(self: *@This(), game: *Game, delta_time: f32) void {
    const speed = 300.0 * delta_time;
    if (rl.isKeyDown(.left)) {
        self.bounds.x -= speed;
    }
    if (rl.isKeyDown(.right)) {
        self.bounds.x += speed;
    }

    if (rl.isKeyPressed(.space)) {
        self.shoot(game);
    }

    self.bounds.x = @max(self.bounds.x, 0.0);
    self.bounds.x = @min(self.bounds.x, @as(f32, @floatFromInt(game.level.screen_width)) - self.bounds.width);

    self.checkLose(game);
}

pub fn draw(self: @This()) void {
    const center_x = self.bounds.x + @divTrunc(self.bounds.width, 2);

    const gun_width = 4.0;
    const gun_height = 8.0;

    const gun_bounds: rl.Rectangle = .{
        .x = center_x - gun_width / 2,
        .y = self.bounds.y - gun_height,
        .width = gun_width,
        .height = gun_height,
    };
    rl.drawRectangleRounded(self.bounds, 0.5, 4, .green);
    rl.drawRectangleRec(gun_bounds, .green);
}

pub const Bullet = struct {
    bounds: rl.Rectangle,
    is_active: bool = false,

    pub fn init(self: *@This()) void {
        self.* = .{
            .bounds = .{
                .x = 0.0,
                .y = 0.0,
                .width = 4.0,
                .height = 12.0,
            },
        };
    }

    pub fn shoot(self: *@This(), position: rl.Vector2) void {
        if (self.is_active) return;

        self.is_active = true;

        self.bounds.x = position.x - self.bounds.width / 2;
        self.bounds.y = position.y - self.bounds.height;
    }

    pub fn update(self: *@This(), delta_time: f32) void {
        if (!self.is_active) return;

        const speed = 800.0 * delta_time;
        self.bounds.y -= speed;

        if (self.bounds.y + self.bounds.height < 0) {
            self.is_active = false;
        }
    }

    pub fn draw(self: @This()) void {
        if (self.is_active) {
            rl.drawRectangleRec(self.bounds, .green);
        }
    }
};
