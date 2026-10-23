# SPWatch

日本語 | [English](#english)

FFXI (Windower 4) 用のアドオンです。敵が 2 時間アビリティ (SP アビリティ) を使ったら、画面の小さな表示で知らせます。効果時間が分かっているものは、残り秒数を数えます。表示するだけで、ゲームには何も送りません。メモリの読み書きもしません。

> **ゲーム内では未確認です (v0.1.0)。** 模擬環境の試験は通っていますが、実際の戦闘で確かめていません。

## 注意

FFXI の利用規約はサードパーティ製ツールを禁止しており、Windower もその対象になる可能性があります。使うかどうかはご自身の判断で、自己責任でお願いします。このアドオンの利用で生じた不利益について、作者は責任を負いません。

## 表示するもの

| 技 | 表示 |
| :--- | :--- |
| マイティストライク / 百烈拳 | 45 秒を数える |
| インビンシブル / 絶対回避 / ブラッドウェポン | 30 秒を数える |
| 連続魔 / 魔力の泉 / ソウルボイス | 60 秒を数える |
| 女神の祝福 / 明鏡止水 / 微塵がくれ / アストラルフロウ | 「発動!」を数秒だけ表示 (時間は数えない) |

- 残り 10 秒以下は赤になります。
- 敵が技を準備しているのを見つけたときは「準備中」と出て、発動すると秒数に変わります。
- 敵が倒れたとき、ゾーンを移動したときは消えます。
- 味方・フェイスの技は対象外です。

効果時間は、LandSandBoat の技のデータと BG-Wiki、NM テレスとの戦闘での実感をもとにしています。**敵ごとに違う可能性があります。目安として使ってください。** ソウルボイスは、LandSandBoat のデータでは 180 秒ですが、実戦の実感に合わせて 60 秒にしています。

## インストール

1. このリポジトリをダウンロードして展開します (Code > Download ZIP)。
2. `SPWatch` フォルダーを `Windower4/addons/` に置きます。
3. ゲーム内で `//lua load spwatch` を実行します。自動で読み込むなら `init.txt` に `lua load spwatch` を足します。

## 操作

- **移動**: 表示をマウスでドラッグします。
- **拡大・縮小**: 表示の上でマウスのホイールを回します。

| コマンド | 内容 |
| :--- | :--- |
| `//spw on` / `//spw off` | 表示 / 非表示 |
| `//spw lang auto\|ja\|en` | 表示の言語。auto はクライアントの言語に合わせる |
| `//spw sec <n>` | 時間を数えない技を表示する秒数 (既定 10) |
| `//spw pos <x> <y>` | 位置 |
| `//spw size <n>` | 文字の大きさ |
| `//spw test` | 表示の試し |
| `//spw status` | 今の設定 |

## ライセンス

[LICENSE](LICENSE) を参照してください。

---

## English

An addon for FFXI (Windower 4). When an enemy uses a 2-hour ability (SP ability), it shows a small HUD, and counts down the remaining seconds for the abilities whose duration is known. It only displays. It sends nothing to the game and reads or writes no game memory.

> **Not verified in game yet (v0.1.0).** It passes a simulated test, but I have not checked it in a real fight.

### Notice

The FFXI Terms of Service prohibit third-party tools, and Windower may fall under that. Use this at your own risk. The author accepts no responsibility for any harm from using it.

### What it shows

| Ability | Display |
| :--- | :--- |
| Mighty Strikes / Hundred Fists | counts down 45 s |
| Invincible / Perfect Dodge / Blood Weapon | counts down 30 s |
| Chainspell / Manafont / Soul Voice | counts down 60 s |
| Benediction / Meikyo Shisui / Mijin Gakure / Astral Flow | "used!" for a few seconds (no countdown) |

- The last 10 seconds turn red.
- When an enemy is seen readying an ability it shows "readying", then switches to the countdown when the ability is used.
- It clears when the enemy dies or you change zones.
- Abilities of party members and trusts are ignored.

The durations come from LandSandBoat's ability data, BG-Wiki and my own experience fighting the NM Telus. **They may differ per enemy; treat them as a guide.** Soul Voice is 180 s in LandSandBoat's data, but I set it to 60 s to match what I saw in play.

### Installation

1. Download this repository (Code > Download ZIP) and unzip it.
2. Put the `SPWatch` folder in `Windower4/addons/`.
3. In game, run `//lua load spwatch`. To load it automatically, add `lua load spwatch` to `init.txt`.

### Controls

- **Move**: drag the HUD with the mouse.
- **Resize**: scroll the mouse wheel over the HUD.

| Command | What it does |
| :--- | :--- |
| `//spw on` / `//spw off` | show / hide |
| `//spw lang auto\|ja\|en` | display language. auto follows the client |
| `//spw sec <n>` | seconds an ability without countdown stays (default 10) |
| `//spw pos <x> <y>` | position |
| `//spw size <n>` | text size |
| `//spw test` | show a sample |
| `//spw status` | current settings |

### License

See [LICENSE](LICENSE).
