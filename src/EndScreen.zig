const rl = @import("raylib");

const win_text = "YOU WIN!";
const win_color = rl.Color.gold;

const lose_text = "GAME OVER";
const lose_color = rl.Color.red;

pub fn update() bool {
    return rl.isKeyPressed(rl.KeyboardKey.r);
}

pub fn draw(is_win: bool) void {
    const header_text = if (is_win) win_text else lose_text;
    const header_color = if (is_win) win_color else lose_color;

    rl.drawText(header_text, if (is_win) 260 else 220, 250, 64, header_color);
    rl.drawText("Press <R> to restart.", 230, 400, 32, .light_gray);
}
