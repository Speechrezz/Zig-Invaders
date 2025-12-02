const rl = @import("raylib");
const Player = @import("Player.zig");
const Enemy = @import("Enemy.zig");
const Shield = @import("Shield.zig");
const EndScreen = @import("EndScreen.zig");

level: Level = undefined,
player: Player = undefined,
player_bullet: Player.Bullet = undefined,
enemy_group: Enemy.Group = undefined,
enemy_bullet_pool: Enemy.BulletPool = undefined,
shield_group: Shield.Group = undefined,
state: State = .playing,

pub const State = enum { playing, win, lose };

pub const Level = struct {
    screen_width: i32,
    screen_height: i32,
};

pub fn init(self: *@This(), screen_width: i32, screen_height: i32) void {
    self.* = .{};

    self.level = .{
        .screen_width = screen_width,
        .screen_height = screen_height,
    };

    self.restart();
}

pub fn update(self: *@This(), delta_time: f32) void {
    switch (self.state) {
        .playing => {
            self.player.update(self, delta_time);
            self.player_bullet.update(delta_time);
            self.enemy_group.update(self, delta_time);
            self.enemy_bullet_pool.update(self, delta_time);
            self.shield_group.update(self);
        },
        .win, .lose => {
            if (EndScreen.update()) {
                self.restart();
            }
        },
    }
}

pub fn draw(self: *@This()) void {
    rl.clearBackground(.black);

    switch (self.state) {
        .playing => {
            self.player.draw();
            self.player_bullet.draw();
            self.enemy_group.draw();
            self.enemy_bullet_pool.draw();
            self.shield_group.draw();
        },
        .win, .lose => |v| EndScreen.draw(v == State.win),
    }
}

pub fn lose(self: *@This()) void {
    self.state = .lose;
}

pub fn win(self: *@This()) void {
    self.state = .win;
}

pub fn restart(self: *@This()) void {
    self.state = .playing;

    self.player.init(
        @floatFromInt(@divTrunc(self.level.screen_width, 2)),
        @floatFromInt(self.level.screen_height - 80),
    );
    self.player_bullet.init();

    self.enemy_group.init(.{ .x = 100.0, .y = 140.0 });
    self.enemy_bullet_pool.init();

    self.shield_group.init(.{
        .x = 100.0,
        .y = 620.0,
        .width = 600.0,
        .height = 100.0,
    });
}
