-- =============================================================================
-- SPWatch.lua : 敵の2時間アビリティ (SP) の警告 / Enemy 2-hour ability alert (Windower 4, v0.1.0)
-- =============================================================================
-- 目的 / Purpose:
--   敵が2時間アビリティを使ったら、小さな表示で知らせます。効果時間が分かっているものは残り秒数を数えます。
--   Shows a small HUD when an enemy uses a 2-hour ability, with a countdown for the ones whose duration is known.
--   画面に表示するだけで、ゲームには何も送りません。メモリの読み書きもしません。
--   It only displays. It sends nothing to the game and reads/writes no game memory.
--
-- しくみ / How it works:
--   - action イベント (アクションパケット 0x028) の category 7 (技の準備開始) と category 11 (技の発動) を見ます。
--     It watches the action event (action packet 0x028): category 7 (readying) and category 11 (monster ability used).
--   - 技の名前は Windower の res/monster_abilities.lua から (日本語・英語どちらも)。
--     Ability names come from res/monster_abilities.lua (Japanese and English).
--   - 効果時間 (DURATION) は、LandSandBoat のデータ (ソウルボイスだけ NM テレスとの戦闘の実感) によるもので、
--     敵ごとに違う可能性があります。目安として使ってください。
--     Durations come from LandSandBoat data (Soul Voice from play experience); they may differ per enemy. Treat them as a guide.
--   - 時間を数えないもの (女神の祝福・微塵がくれ・アストラルフロウは瞬時、明鏡止水はウェポンスキルを数回使うと終わる) は、「発動!」だけを数秒 (既定 10 秒) 表示します。
--     Instant ones (Benediction, Meikyo Shisui, ...) are shown for a few seconds without a countdown.
--   - 日本語クライアントでゲーム内確認済み (ディスメンバーブリゲード・天誅六人衆)。英語表示は英語クライアントで未確認 / Checked in game on the Japanese client; the English display is not tested on an English client.
-- =============================================================================

_addon.name     = "SPWatch"
_addon.author   = "hikaruoshino"
_addon.version  = "0.1.0"
_addon.commands = {"spwatch", "spw"}

local config  = require("config")
local texts   = require("texts")
local res     = require("resources")

-- -----------------------------------------------------------------------------
-- 設定 / Settings (data/settings.xml)
-- -----------------------------------------------------------------------------
local defaults = {}
defaults.show = true          -- 表示する / show the HUD
defaults.lang = "auto"        -- auto (クライアントの言語) / ja / en
defaults.alert_sec = 10       -- 効果時間を数えない技を表示する秒数 / seconds an alert without countdown stays
defaults.sound = false        -- 将来用 (今は何もしない) / reserved
defaults.pos = {x = 40, y = 260}
defaults.text = {font = "Meiryo", size = 12, alpha = 255}
defaults.bg = {alpha = 180, red = 10, green = 10, blue = 15}
defaults.padding = 6

local settings = config.load(defaults)
-- 初期版の既定フォント Consolas は日本語の字が無く、HUD が □ になる。保存済みの設定に残っていたら Meiryo に直す
if settings.text and settings.text.font == "Consolas" then settings.text.font = "Meiryo" end

-- -----------------------------------------------------------------------------
-- 言語 / Language
-- -----------------------------------------------------------------------------
local function resolve_lang()
    local s = tostring(settings.lang or "auto"):lower()
    if s == "ja" or s == "en" then return s end
    local ok, info = pcall(windower.ffxi.get_info)
    local l = ok and info and info.language and tostring(info.language):lower() or "japanese"
    return (l == "japanese") and "ja" or "en"
end
local LANG = resolve_lang()

local function L(ja, en)
    if LANG == "ja" then return ja end
    return en
end

-- チャットは Shift-JIS / chat output is Shift-JIS
local function chat(text, color)
    windower.add_to_chat(color or 207, windower.to_shift_jis and windower.to_shift_jis(text) or text)
end

-- -----------------------------------------------------------------------------
-- データ / Data
-- -----------------------------------------------------------------------------
-- 技 ID (res/monster_abilities.lua) -> 種類。同じ技の別バージョンの ID も含む。
-- key: 英名 / en name. DURATION が無いものは数えない / entries without a duration are not counted.
local ABILITY_KEY = {
    [688] = "Mighty Strikes", [1008] = "Mighty Strikes", [2242] = "Mighty Strikes",
    [689] = "Benediction", [1010] = "Benediction", [1486] = "Benediction",
    [690] = "Hundred Fists", [1009] = "Hundred Fists", [1485] = "Hundred Fists",
    [691] = "Manafont", [1011] = "Manafont",
    [692] = "Chainspell", [1012] = "Chainspell",
    [693] = "Perfect Dodge", [1013] = "Perfect Dodge",
    [694] = "Invincible", [1014] = "Invincible", [2248] = "Invincible",
    [695] = "Blood Weapon", [1015] = "Blood Weapon", [2249] = "Blood Weapon",
    [696] = "Soul Voice", [1018] = "Soul Voice",
    [730] = "Meikyo Shisui", [1020] = "Meikyo Shisui",
    [731] = "Mijin Gakure", [1021] = "Mijin Gakure",
    [734] = "Astral Flow", [1023] = "Astral Flow", [2256] = "Astral Flow",
}

-- 効果時間 (秒)。LandSandBoat の技のスクリプトの値。ソウルボイスは実戦 (NM テレス) の実感で 60 秒。
local DURATION = {
    ["Mighty Strikes"] = 45, ["Hundred Fists"] = 45, ["Invincible"] = 30, ["Chainspell"] = 60,
    ["Perfect Dodge"] = 30, ["Manafont"] = 60, ["Blood Weapon"] = 30, ["Soul Voice"] = 60,
}

-- 日本語名の補い (res に無い場合のみ使う) は不要: res/monster_abilities.lua の ja / en をそのまま使う。

local CAST_BEGIN = 24931   -- category 7 の param (技の準備開始) / readying started
local MAX_ROWS = 6

-- -----------------------------------------------------------------------------
-- 状態 / State
-- -----------------------------------------------------------------------------
local rows = {}   -- key = actor_id .. ":" .. 技名 / value = {actor, ability, until_time, timed, start}

local function num(v, default)
    if type(v) == "number" then return v end
    return tonumber(v) or default or 0
end

local function ability_label(id, key)
    local def = res.monster_abilities and res.monster_abilities[id]
    if def then
        local n = (LANG == "ja") and def.ja or def.en
        if n and n ~= "" then return n end
    end
    return key
end

local function is_enemy(actor)
    return actor and actor.spawn_type == 16 and not actor.in_party
end

-- 技を使われた (準備開始 or 発動)。発動のときだけ効果時間を数え始める
local function register(actor_id, id, used, now)
    local key = ABILITY_KEY[id]
    if not key then return end
    local actor = windower.ffxi.get_mob_by_id(actor_id)
    if not is_enemy(actor) then return end
    local rkey = tostring(actor_id) .. ":" .. key
    local dur = DURATION[key]
    local row = rows[rkey]
    if dur and used then
        rows[rkey] = {actor = actor.name or "?", actor_id = actor_id, label = ability_label(id, key), key = key,
            until_time = now + dur, timed = true, start = now}
    elseif not row or not row.timed or now >= row.until_time then
        -- 準備開始 (まだ効果時間は数えない) / 時間の無い技
        rows[rkey] = {actor = actor.name or "?", actor_id = actor_id, label = ability_label(id, key), key = key,
            until_time = now + num(settings.alert_sec, 10), timed = false, start = now, readying = (not used)}
    end
end

-- Windower の action イベント (パケットを解析済み)。SwapLog と同じ読み方で、ゲーム内で動作確認済み
local function on_action(act)
    if not act then return end
    local cat = num(act.category, 0)
    local now = os.clock()
    if cat == 11 then
        register(act.actor_id, num(act.param, 0), true, now)
    elseif cat == 7 and num(act.param, 0) == CAST_BEGIN then
        local target = act.targets and act.targets[1]
        local action = target and target.actions and target.actions[1]
        if action then register(act.actor_id, num(action.param, 0), false, now) end
    elseif cat == 6 and num(act.param, 0) == 30 then
        -- アビリティ (category 6) の「アストラルフロウ」が届く場合もある / Astral Flow can also arrive as a job ability
        register(act.actor_id, 734, true, now)
    end
end

-- -----------------------------------------------------------------------------
-- 表示 / Display
-- -----------------------------------------------------------------------------
local hud = texts.new("", settings)
local last_text = nil
local next_refresh = 0
local test_until = 0
local REFRESH_SEC = 0.1
-- 秒数が 0 になってもすぐには消さない。動画で測ったところ (インビンシブル)、実際の効果は表示より約 3 秒長かった (サーバーの切れの処理が 3 秒刻みと思われる)
local GRACE_SEC = 3

local function color(str, r, g, b)
    return string.format("\\cs(%d,%d,%d)%s\\cr", r, g, b, str)
end

local function remove_dead(now)
    for k, row in pairs(rows) do
        local m = windower.ffxi.get_mob_by_id(row.actor_id)
        if now >= row.until_time + (row.timed and GRACE_SEC or 0) or (m and m.hpp and m.hpp <= 0) or (not m and not row.test) then
            rows[k] = nil
        end
    end
end

local function build(now)
    remove_dead(now)
    local list = {}
    for _, row in pairs(rows) do list[#list + 1] = row end
    table.sort(list, function(a, b) return a.start > b.start end)
    if #list == 0 then return nil end
    local lines = {color(L("敵のSPアビリティ", "Enemy SP ability"), 255, 215, 90)}
    for i = 1, math.min(#list, MAX_ROWS) do
        local r = list[i]
        local line
        if r.timed then
            local left = r.until_time - now
            if left > 0 then
                local c = left <= 10 and {255, 90, 90} or {255, 200, 90}
                line = string.format("%s %s %s", r.actor, color(r.label, 255, 255, 255), color(string.format("%2d%s", math.ceil(left), L("秒", "s")), c[1], c[2], c[3]))
            else
                -- 数え終わったあと、実際の効果が切れるまでの数秒
                line = string.format("%s %s %s", r.actor, color(r.label, 255, 255, 255), color(L(" 0秒 (まもなく切れる)", " 0s (ending soon)"), 255, 90, 90))
            end
        elseif r.readying then
            line = string.format("%s %s %s", r.actor, color(r.label, 255, 255, 255), color(L("準備中", "readying"), 200, 200, 200))
        else
            line = string.format("%s %s %s", r.actor, color(r.label, 255, 255, 255), color(L("発動!", "used!"), 255, 120, 120))
        end
        lines[#lines + 1] = line
    end
    return table.concat(lines, "\n")
end

local function refresh(now)
    if not settings.show then hud:hide() return end
    local s = build(now)
    if not s then
        if test_until > now then return end
        last_text = nil
        hud:hide()
        return
    end
    if s ~= last_text then hud:text(s); last_text = s end
    hud:show()
end

local function hide_all()
    rows = {}
    last_text = nil
    if hud then hud:hide() end
end

windower.register_event("prerender", function()
    local now = os.clock()
    if now < next_refresh then return end
    next_refresh = now + REFRESH_SEC
    local ok, err = pcall(refresh, now)
    if not ok then
        next_refresh = now + 5
        chat("[SPWatch] " .. L("表示エラー: ", "display error: ") .. tostring(err):match("^[^\n]*"), 123)
    end
end)

windower.register_event("action", function(act)
    local ok, err = pcall(on_action, act)
    if not ok then chat("[SPWatch] " .. L("パケットエラー: ", "packet error: ") .. tostring(err):match("^[^\n]*"), 123) end
end)

windower.register_event("zone change", hide_all)
windower.register_event("logout", hide_all)

windower.register_event("unload", function()
    config.save(settings)
    if hud then hud:destroy() end
end)

-- -----------------------------------------------------------------------------
-- マウス: HUD のドラッグで移動 (libs/texts が位置を保存)、HUD の上でホイールで拡大縮小
-- Mouse: drag the HUD to move it (libs/texts saves the position), wheel over it to scale the text
-- -----------------------------------------------------------------------------
local MOUSE_WHEEL = 10
local SIZE_MIN, SIZE_MAX = 6, 40

local function set_size(size)
    size = math.max(SIZE_MIN, math.min(SIZE_MAX, math.floor(size + 0.5)))
    settings.text.size = size
    hud:size(size)
    last_text = nil
    return size
end

windower.register_event("mouse", function(mtype, x, y, delta, blocked)
    if blocked or mtype ~= MOUSE_WHEEL then return end
    local ok, result = pcall(function()
        if not hud:visible() or not hud:hover(x, y) then return nil end
        local step = num(delta, 0) > 0 and 1 or -1
        set_size(num(hud:size(), num(settings.text and settings.text.size, 12)) + step)
        config.save(settings)
        return true
    end)
    if ok then return result end
end)

-- -----------------------------------------------------------------------------
-- コマンド / Commands (//spw or //spwatch)
-- -----------------------------------------------------------------------------
local function print_help()
    chat("[SPWatch] //spw on|off          : " .. L("表示 / 非表示", "show / hide the HUD"))
    chat("[SPWatch] //spw lang auto|ja|en : " .. L("表示の言語", "display language"))
    chat("[SPWatch] //spw sec <n>         : " .. L("時間を数えない技を表示する秒数 (既定 10)", "seconds an alert without countdown stays (default 10)"))
    chat("[SPWatch] //spw pos <x> <y>     : " .. L("位置 (マウスのドラッグでも動かせます)", "position (you can also drag it with the mouse)"))
    chat("[SPWatch] //spw size <n>        : " .. L("文字の大きさ (HUD の上でホイールでも変えられます)", "text size (or use the wheel over the HUD)"))
    chat("[SPWatch] //spw test            : " .. L("表示の試し (10秒)", "show a sample (10 s)"))
    chat("[SPWatch] //spw status          : " .. L("今の設定", "current settings"))
end

local function sample_row(actor, key, id, dur, now)
    rows["test:" .. key] = {actor = actor, actor_id = -1, test = true, label = ability_label(id, key), key = key,
        until_time = now + dur, timed = dur > 20 and true or false, start = now}
end

windower.register_event("addon command", function(cmd, ...)
    local args = {...}
    cmd = cmd and cmd:lower() or "help"
    local ok, err = pcall(function()
        if cmd == "on" or cmd == "off" then
            settings.show = (cmd == "on")
            config.save(settings)
            if not settings.show then hud:hide() end
            chat("[SPWatch] " .. (settings.show and "on" or "off"))
        elseif cmd == "lang" then
            local a = tostring(args[1] or ""):lower()
            if a == "auto" or a == "ja" or a == "en" then
                settings.lang = a
                config.save(settings)
                LANG = resolve_lang()
                last_text = nil
                chat("[SPWatch] lang: " .. settings.lang .. " (" .. LANG .. ")")
            else
                chat("[SPWatch] //spw lang auto|ja|en")
            end
        elseif cmd == "sec" and tonumber(args[1]) then
            settings.alert_sec = math.max(1, math.min(60, math.floor(tonumber(args[1]))))
            config.save(settings)
            chat("[SPWatch] alert_sec: " .. settings.alert_sec)
        elseif cmd == "pos" and tonumber(args[1]) and tonumber(args[2]) then
            settings.pos.x, settings.pos.y = tonumber(args[1]), tonumber(args[2])
            hud:pos(settings.pos.x, settings.pos.y)
            config.save(settings)
        elseif cmd == "size" and tonumber(args[1]) then
            set_size(tonumber(args[1]))
            config.save(settings)
        elseif cmd == "test" then
            local now = os.clock()
            sample_row("Telus", "Soul Voice", 696, 60, now)
            sample_row("Telus", "Benediction", 689, 10, now)
            test_until = now + 10
        elseif cmd == "status" then
            chat(string.format("[SPWatch] v%s show=%s lang=%s(%s) alert_sec=%d size=%d", _addon.version, tostring(settings.show),
                tostring(settings.lang), LANG, num(settings.alert_sec, 10), num(settings.text and settings.text.size, 12)))
        else
            print_help()
        end
    end)
    if not ok then chat("[SPWatch] error: " .. tostring(err):match("^[^\n]*"), 123) end
end)

chat("[SPWatch] v" .. _addon.version .. " " .. L("読み込み完了。//spw でヘルプ", "loaded. //spw for help"))
