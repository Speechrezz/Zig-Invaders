const std = @import("std");
const rl = @import("raylib");
const Game = @import("Game.zig");
const Random = @import("Random.zig");

const Enemy = @This();

bounds: rl.Rectangle,
is_alive: bool = true,

const enemy_width = 40.0;
const enemy_height = 20.0;
const enemy_total_width = 600.0;
const enemy_total_height = 240.0;
const enemy_cols = 11;
const enemy_rows = 5;

const seconds_per_move = 0.5;
const distance_per_move = 4.0;
const distance_per_drop = 20.0;

const reload_time_seconds = 1.2;

pub fn init(self: *@This()) void {
    self.* = .{
        .bounds = .{
            .x = 0.0,
            .y = 0.0,
            .width = 40.0,
            .height = 30.0,
        },
    };
}

fn shoot(self: *@This(), game: *Game) void {
    game.enemy_bullet_pool.shoot(.{
        .x = self.bounds.x + @divTrunc(self.bounds.width, 2),
        .y = self.bounds.y + self.bounds.height,
    });
}

pub fn setPosition(self: *@This(), position: rl.Vector2) void {
    self.bounds.x = position.x;
    self.bounds.y = position.y;
}

pub fn update(self: *@This(), game: *Game) void {
    if (!self.is_alive or !game.player_bullet.is_active) return;

    if (game.player_bullet.bounds.checkCollision(self.bounds)) {
        game.player_bullet.is_active = false;
        self.kill(game);
    }
}

fn kill(self: *@This(), game: *Game) void {
    self.is_alive = false;
    game.enemy_group.kill(game, self);
}

pub fn draw(self: @This()) void {
    if (self.is_alive) {
        rl.drawRectangleRounded(self.bounds, 0.25, 2, .white);
    }
}

pub const Group = struct {
    bounds: rl.Rectangle,
    enemies: [enemy_rows][enemy_cols]Enemy = undefined,
    alive_enemies: std.ArrayList(*Enemy) = undefined,
    alive_enemies_buffer: [enemy_rows * enemy_cols]*Enemy = undefined,
    time_passed: f32 = 0.0,
    time_passed_reload: f32 = 0.0,
    move_direction: f32 = 1.0,
    state: State = .horizontal,

    const State = enum { horizontal, drop };

    pub fn init(self: *@This(), position: rl.Vector2) void {
        self.* = .{
            .bounds = .{
                .x = position.x,
                .y = position.y,
                .width = enemy_total_width,
                .height = enemy_total_height,
            },
        };

        self.alive_enemies = std.ArrayList(*Enemy).initBuffer(&self.alive_enemies_buffer);

        for (&self.enemies) |*row| {
            for (row) |*enemy| {
                enemy.init();
                self.alive_enemies.appendAssumeCapacity(enemy);
            }
        }

        self.updatePositions();
    }

    fn kill(self: *@This(), game: *Game, enemy: *Enemy) void {
        for (self.alive_enemies.items, 0..) |ptr, i| {
            if (ptr == enemy) {
                _ = self.alive_enemies.orderedRemove(i);
                break;
            }
        }

        if (self.alive_enemies.items.len == 0) {
            game.win();
        }
    }

    fn moveStep(self: *@This(), game: *Game) void {
        var adjusted_distance_per_move: f32 = distance_per_move;
        if (self.alive_enemies.items.len <= 10) {
            adjusted_distance_per_move *= 2.0;
        } else if (self.alive_enemies.items.len <= 25) {
            adjusted_distance_per_move *= 1.5;
        }

        switch (self.state) {
            .horizontal => {
                self.bounds.x += adjusted_distance_per_move * self.move_direction;
                const screen_width: f32 = @floatFromInt(game.level.screen_width);

                if (self.bounds.x <= 0) {
                    self.bounds.x = 0;
                    self.move_direction = 1.0;
                    self.state = .drop;
                } else if (self.bounds.x + self.bounds.width >= screen_width) {
                    self.bounds.x = screen_width - self.bounds.width;
                    self.move_direction = -1.0;
                    self.state = .drop;
                }
            },
            .drop => {
                self.bounds.y += distance_per_drop;
                self.state = .horizontal;
            },
        }
    }

    fn updatePositions(self: *@This()) void {
        for (&self.enemies, 0..) |*row, i| {
            for (row, 0..) |*enemy, j| {
                const ratio_x = @as(f32, @floatFromInt(j)) / @as(f32, @floatFromInt(enemy_cols - 1));
                const ratio_y = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(enemy_rows - 1));

                const position = rl.Vector2{
                    .x = self.bounds.x + ratio_x * (self.bounds.width - enemy_width),
                    .y = self.bounds.y + ratio_y * (self.bounds.height - enemy_height),
                };

                enemy.setPosition(position);
            }
        }
    }

    fn tryShoot(self: *@This(), game: *Game, dead_enemy_ratio: f32) void {
        const reload_time_adjusted = reload_time_seconds * (0.5 + 0.5 * dead_enemy_ratio);

        if (self.time_passed_reload >= reload_time_adjusted) {
            self.time_passed_reload -= reload_time_adjusted;

            const enemy_index: usize = @intCast(Random.getRandomInt(0, @intCast(self.alive_enemies.items.len - 1)) catch 0);
            self.alive_enemies.items[enemy_index].shoot(game);
        }
    }

    pub fn update(self: *@This(), game: *Game, delta_time: f32) void {
        defer self.time_passed += delta_time;
        defer self.time_passed_reload += delta_time;

        const dead_enemy_ratio = @as(f32, @floatFromInt(self.alive_enemies.items.len)) / @as(f32, @floatFromInt(self.alive_enemies_buffer.len));
        const adjusted_seconds_per_move = seconds_per_move * (0.1 + 0.9 * dead_enemy_ratio);

        if (self.time_passed >= adjusted_seconds_per_move) {
            self.time_passed -= adjusted_seconds_per_move;
            self.moveStep(game);
            self.updatePositions();
            self.tryShoot(game, dead_enemy_ratio);
        }

        for (&self.enemies) |*row| {
            for (row) |*enemy| {
                enemy.update(game);
            }
        }
    }

    pub fn draw(self: *@This()) void {
        for (self.alive_enemies.items) |enemy| {
            enemy.draw();
        }
    }
};

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
        self.is_active = true;

        self.bounds.x = position.x - self.bounds.width / 2;
        self.bounds.y = position.y;
    }

    pub fn update(self: *@This(), game: *Game, delta_time: f32) void {
        if (!self.is_active) return;

        const speed = 400.0 * delta_time;
        self.bounds.y += speed;

        if (self.bounds.y > @as(f32, @floatFromInt(game.level.screen_height))) {
            self.is_active = false;
        }
    }

    pub fn draw(self: @This()) void {
        if (self.is_active) {
            rl.drawRectangleRec(self.bounds, .white);
        }
    }
};

pub const BulletPool = struct {
    bullet_list: [8]Bullet = undefined,

    pub fn init(self: *@This()) void {
        for (&self.bullet_list) |*bullet| {
            bullet.init();
        }
    }

    pub fn shoot(self: *@This(), position: rl.Vector2) void {
        for (&self.bullet_list) |*bullet| {
            if (!bullet.is_active) {
                bullet.shoot(position);
                break;
            }
        }
    }

    pub fn update(self: *@This(), game: *Game, delta_time: f32) void {
        for (&self.bullet_list) |*bullet| {
            bullet.update(game, delta_time);
        }
    }

    pub fn draw(self: @This()) void {
        for (&self.bullet_list) |bullet| {
            bullet.draw();
        }
    }
};
