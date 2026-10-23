# SPWatch

日本語 | [English](#english)

FFXI (Windower 4) 用のアドオンです。敵が 2 時間アビリティ (SP アビリティ) を使ったら、画面の小さな表示で知らせます。効果時間が分かっているものは、残り秒数を数えます。表示するだけで、ゲームには何も送りません。メモリの読み書きもしません。

> **ゲーム内での確認 (v0.1.0)**: ディスメンバーブリゲードと天誅六人衆で、日本語クライアントで確かめました。表示を見た技は、魔力の泉・百烈拳・明鏡止水・微塵がくれ・女神の祝福・ソウルボイス・マイティストライク・インビンシブルです。連続魔・絶対回避・ブラッドウェポン・アストラルフロウは、同じ仕組みで動くはずですが、表示は見ていません。英語の表示は、英語クライアントでは試していません。秒数が実際の効果の終わりと合っているかは、インビンシブルの 1 件だけ測りました。

## 注意

FFXI の利用規約はサードパーティ製ツールを禁止しており、Windower もその対象になる可能性があります。使うかどうかはご自身の判断で、自己責任でお願いします。このアドオンの利用で生じた不利益について、作者は責任を負いません。

## 表示するもの

| 技 | 表示 |
| :--- | :--- |
| マイティストライク / 百烈拳 | 45 秒を数える |
| インビンシブル / 絶対回避 / ブラッドウェポン | 30 秒を数える |
| 連続魔 / 魔力の泉 / ソウルボイス | 60 秒を数える |
| 女神の祝福 / 明鏡止水 / 微塵がくれ / アストラルフロウ | 「発動!」を表示 (既定 10 秒。秒数は数えない) |

- 明鏡止水は、LandSandBoat のデータでは 30 秒ですが、ウェポンスキルを数回使うと終わるので、時間は数えず「発動!」だけにしています。女神の祝福・微塵がくれは瞬時、アストラルフロウは直後のペイクトが瞬時に発動するので、同じ扱いです。
- 残り 10 秒以下は赤になります。
- 秒数が 0 になっても、3 秒間は赤字で「0秒 (まもなく切れる)」を出してから消えます。インビンシブルで実測したところ、実際の効果は表示より約 3 秒長かったためです (確かめたのはこの 1 件だけです)。
- 敵が技を準備しているのを見つけたときは「準備中」と出て、発動すると秒数に変わります。
- 敵が倒れたとき、ゾーンを移動したときは消えます。
- 味方・フェイスの技は対象外です。

効果時間は、LandSandBoat (私設サーバー) の技のデータをもとにしています。ソウルボイスだけは、LandSandBoat では 180 秒ですが、NM テレスとの戦闘の実感に合わせて 60 秒にしました。**本家の値は確認できていません。敵ごとに違う可能性があるので、目安として使ってください。**

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

An addon for FFXI (Windower 4). When an enemy uses a 2-hour ability (SP ability), it shows a small HUD, and counts down the remaining seconds for the abilities whose duration is known. It only displays. It sends nothing to the game and reads or writes no game memory (it only listens to Windower's action events and Windower's own functions).

> **Checked in game (v0.1.0)**: on the Japanese client, in Dismemberment Brigade and its Yagudo counterpart. I saw the display for Manafont, Hundred Fists, Meikyo Shisui, Mijin Gakure, Benediction, Soul Voice, Mighty Strikes and Invincible. Chainspell, Perfect Dodge, Blood Weapon and Astral Flow use the same code, but I have not seen their display. I have not tested the English display on an English client. I measured how well the countdown matches the real end of the effect for Invincible only.

### Notice

The FFXI Terms of Service prohibit third-party tools, and Windower may fall under that. Use this at your own risk. The author accepts no responsibility for any harm from using it.

### What it shows

| Ability | Display |
| :--- | :--- |
| Mighty Strikes / Hundred Fists | counts down 45 s |
| Invincible / Perfect Dodge / Blood Weapon | counts down 30 s |
| Chainspell / Manafont / Soul Voice | counts down 60 s |
| Benediction / Meikyo Shisui / Mijin Gakure / Astral Flow | "used!" for 10 seconds by default (no countdown) |

- Meikyo Shisui is 30 s in LandSandBoat's data, but it ends after a few weapon skills, so it is shown as an alert without a countdown. Benediction and Mijin Gakure are instant, and Astral Flow is followed by instant blood pacts, so they are treated the same way.
- The last 10 seconds turn red.
- When the count reaches 0, it stays for 3 more seconds as a red "0s (ending soon)" and then disappears. I measured Invincible once and the real effect lasted about 3 seconds longer than the countdown (that is the only ability I checked).
- When an enemy is seen readying an ability it shows "readying", then switches to the countdown when the ability is used.
- It clears when the enemy dies or you change zones.
- Abilities of party members and trusts are ignored.

The durations come from LandSandBoat's (a private server) ability data. Only Soul Voice differs: it is 180 s in LandSandBoat, but I set it to 60 s to match what I saw. **I have not confirmed the retail values, and they may differ per enemy, so treat them as a guide.**

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
