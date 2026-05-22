# Oyuna eklenebilecek tüm dosyalar

Hepsi şu klasöre: **`sketch_260503a/data/`**  
Dosya yoksa oyun çoğu yerde yine çalışır (yerine çizim / sessizlik).

---

## Sesler (`data/sounds/`) — WAV

| Dosya adı | Ne zaman çalar | Öneri |
|-----------|----------------|--------|
| `gun_player.wav` veya `gun_player.mp3` | Sen ateş edince | Kısa, keskin tabanca |
| `gun_enemy.wav` | Düşman ateş edince | Daha ince / uzak |
| `hit_player.wav` | Sana vurulunca | Tok darbe |
| `hit_enemy.wav` | Düşmana isabet | Vücut darbesi |
| `gun_reload.wav` / `reload.wav` | R ile şarjör | Şarjör / levye |
| `pickup.wav` | Yerden loot toplama (isteğe bağlı) | Kısa “ting”; yoksa sessiz |
| `wave_clear.wav` | Dalga bitince | Kısa fanfar |
| `win.wav` | Kazanınca | 1–2 sn |
| `lose.wav` | Kaybedince / süre bitince | Alçak ton |
| `western_soundtrack.mp3` | **Title + controls menü** (döngü) | Western müzik |
| `music_loop.wav` | Oyun içi (isteğe bağlı) | Western ambient, 30–60 sn döngü |

**Format:** WAV (PCM), 44.1 kHz, mono veya stereo.

---

## Doku / 3D zemin (`data/textures/`)

| Dosya adı | Nerede kullanılır | Öneri boyut |
|-----------|-------------------|-------------|
| `barrel_wood.jpg` veya `.png` | Varil silindiri | 512×512 – 1024×1024, tekrarlanabilir |
| `roof_rust.jpg` veya `.png` | Çit direği koni çatı | 512×512 pas |
| `ground_dirt.jpg` veya `.png` | Arena zemin düzlemi | 1024×1024 toprak |
| `cactus.png` | Sahnedeki kaktüsler (silindir sarmal) | Dikey, tekrarlanabilir yeşil doku |
| `sky_stars.png` | (İsteğe bağlı) gökyüzü | Karanlık + yıldız |

---

## Arayüz / menü PNG (`data/ui/`)

| Dosya adı | Nerede kullanılır | Öneri |
|-----------|-------------------|--------|
| `western_bg.png` | **Title + controls** tam ekran arka plan | 1920×1080 veya oyun çözünürlüğüne yakın |
| `btn_controls.png` | Oyun içi **CONTROLS** butonu | ~108×30, şeffaf arka plan |
| `btn_controls_hot.png` | Fare üstünde (isteğe bağlı) | Aynı boyut |
| `hat_cowboy.png` | Başlık **WESTERN BOUNTY** sonunda yatık şapka | Şeffaf PNG |
| `hat_pixel.png` | Yukarıdakine alternatif isim | Aynı |
| `hat.png` | Üçüncü yedek isim | Aynı |

Arka plan: `western_bg.png` (yoksa koyu kahverengi düz renk).  
Şapka: `hat_cowboy.png` → `hat_pixel.png` → `hat.png` (yoksa çizilmiş şapka).

### İleride eklenebilir (kodda henüz yok)

Bunları eklemek için `loadUiAssets()` + çizim koduna bağlaman gerekir:

| Önerilen dosya | Amaç |
|----------------|------|
| `logo_title.png` | “WESTERN BOUNTY” yerine logo |
| `icon_move.png` | Controls satırı ikonu |
| `icon_shoot.png` | Controls satırı ikonu |
| `loot_gold.png` | Yerde altın kutusu (3D yerine sprite) |
| `loot_health.png` | Can loot |
| `loot_ammo.png` | Mermi kutusu |

---

## Otomatik dosya (elle ekleme)

| Dosya | Açıklama |
|-------|----------|
| `progression.txt` | Oyun kaydedince oluşur: `highScore`, `totalKills` |

---

## Klasör ağacı (kopyala-yapıştır)

```
sketch_260503a/data/
├── sounds/
│   ├── gun_player.wav
│   ├── gun_enemy.wav
│   ├── hit_player.wav
│   ├── hit_enemy.wav
│   ├── reload.wav
│   ├── wave_clear.wav
│   ├── win.wav
│   ├── lose.wav
│   └── music_loop.wav      (isteğe bağlı)
├── textures/
│   ├── barrel_wood.jpg
│   ├── roof_rust.jpg
│   ├── ground_dirt.jpg
│   └── sky_stars.png       (isteğe bağlı)
├── ui/
│   ├── btn_controls.png
│   ├── btn_controls_hot.png
│   └── hat_cowboy.png      (menü şapkası — şeffaf PNG)
└── progression.txt           (otomatik)
```

---

## Pixel şapka nereden bulunur?

- [OpenGameArt.org](https://opengameart.org) — “cowboy hat” / “western”
- [Kenney.nl](https://kenney.nl) — asset pack’ler (lisansa bak)
- [itch.io](https://itch.io/game-assets) — pixel hat sprite
- Kendin: Aseprite / Piskel, **şeffaf arka plan**, yan görünüm veya 3/4 görünüm

Dosyayı `data/ui/hat_cowboy.png` olarak kaydet; menüde otomatik kayar.

---

## Ücretsiz ses kaynakları

- [freesound.org](https://freesound.org) (lisans kontrolü)
- [OpenGameArt](https://opengameart.org)
- [Kenney.nl](https://kenney.nl) Sound Pack
