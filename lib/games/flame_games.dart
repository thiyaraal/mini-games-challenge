import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'dart:math';
import 'package:flutter/cupertino.dart';

class SimpleGame extends FlameGame with PanDetector {
  late SpriteComponent player;
  late TextComponent scoreText;
  late TextComponent gameOverText;
  int score = 0;
  int burgerCount = 10; // Jumlah burger default untuk level 1
  int level = 1; // Level awal
  bool isGameOver = false; // Menandai status Game Over
  int missedBurgers = 0; // Counter untuk burger yang jatuh tanpa tertangkap
  int bomCount = 0; // Counter untuk jumlah bom yang sudah muncul di level ini
  Random random = Random();

  @override
  Future<void> onLoad() async {
    // Muat karakter pemain
    player = SpriteComponent()
      ..sprite = await loadSprite('player.png')
      ..size = Vector2(64, 64)
      ..position = Vector2(size.x / 2, size.y - 100); // Tempatkan di bawah
    add(player);

    // Tambahkan teks skor
    scoreText = TextComponent(
      text: 'Score: $score',
      position: Vector2(10, 10),
      anchor: Anchor.topLeft,
    );
    add(scoreText);

    // Tambahkan teks "Game Over" tapi sembunyikan dulu (tidak ditambahkan ke dalam game)
    gameOverText = TextComponent(
      text: 'Game Over',
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
    );

    // Spawn burger untuk level pertama
    startSpawningBurgers();
  }

  // Fungsi untuk spawn beberapa burger atau bom
  void spawnBurgers(int count) {
    for (int i = 0; i < count; i++) {
      spawnBurger();
    }
  }

 void spawnBurger() async {
  // Random 20% kemungkinan untuk spawn bom, tetapi hanya spawn bom jika bomCount == 0 (hanya 1 bom per level)
  bool isBom = random.nextDouble() < 0.2 && bomCount == 0;

  if (isBom) {
    Bom bom = Bom()
      ..sprite = await loadSprite('bom.png') // Muat sprite bom
      ..size = Vector2(50, 50)
      ..position = Vector2(random.nextDouble() * (size.x - 50), 0); // Random posisi x
    add(bom);

    bomCount += 1; // Tambah counter bom setelah spawn (hanya 1 per level)

    // Logika pergerakan bom
    bom.add(MoveEffect.to(
      Vector2(bom.position.x, size.y - 10),
      EffectController(duration: 5.0 + random.nextDouble() * 2, curve: Curves.linear),
      onComplete: () {
        remove(bom); // Hapus bom setelah jatuh
      },
    ));
  } else {
    // Jika bukan bom, spawn burger seperti biasa
    Burger burger = Burger()
      ..sprite = await loadSprite('burger.png')
      ..size = Vector2(50, 50)
      ..position = Vector2(random.nextDouble() * (size.x - 50), 0);
    add(burger);

    // Logika pergerakan burger
    burger.add(MoveEffect.to(
      Vector2(burger.position.x, size.y - 10),
      EffectController(duration: 5.0 + random.nextDouble() * 2, curve: Curves.linear),
      onComplete: () {
        if (!isGameOver) {
          missedBurgers += 1; // Tambah counter jika burger jatuh tanpa tertangkap

          if (missedBurgers >= 7) {
            gameOver(); // Panggil Game Over jika sudah 7 burger yang jatuh
          } else {
            remove(burger); // Hapus burger yang jatuh
          }
        }
      },
    ));
  }
}

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (isGameOver) return; // Tidak bisa gerak saat game over

    // Update posisi player berdasarkan input seret
    player.position.add(info.delta.global);

    // Pastikan player tidak keluar dari layar (termasuk batas bawah)
    player.position.clamp(
      Vector2(0, 0), // Batas atas dan kiri layar
      Vector2(size.x - player.size.x, size.y - player.size.y), // Batas kanan dan bawah layar
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Jika game over, jangan lanjutkan pengecekan
    if (isGameOver) return;

    // Cek kolisi antara player dan burger
    children.whereType<Burger>().forEach((burger) {
      if (player.toRect().overlaps(burger.toRect())) {
        score += 1; // Tambah skor sebanyak 1 untuk setiap burger yang tertangkap
        scoreText.text = 'Score: $score'; // Update teks skor
        remove(burger); // Hapus burger jika tertangkap

        // Cek apakah sudah mencapai skor untuk naik level
        if (score >= 8 && level == 1) {
          nextLevel(); // Panggil fungsi untuk masuk ke level berikutnya
        }
      }
    });

    // Cek kolisi antara player dan bom
    children.whereType<Bom>().forEach((bom) {
      if (player.toRect().overlaps(bom.toRect())) {
        gameOver(); // Jika tertangkap bom, langsung game over
      }
    });
  }

  // Fungsi untuk berpindah ke level berikutnya
void nextLevel() {
  level += 1; // Naik ke level berikutnya
  burgerCount += 5; // Tambah jumlah burger sebanyak 5 untuk setiap level baru
  scoreText.text = 'Level $level - Score: $score'; // Update teks untuk menunjukkan level
  bomCount = 0; // Reset jumlah bom saat naik level
  startSpawningBurgers(); // Lanjutkan spawning burger dengan burger tambahan
}

  // Fungsi untuk memulai spawning burger
  void startSpawningBurgers() {
    // Panggil secara berkala sampai game over
    if (!isGameOver) {
      Future.delayed(Duration(seconds: 1), () {
        spawnBurgers(burgerCount); // Tambah burger sesuai burgerCount
        startSpawningBurgers(); // Ulangi terus sampai game over
      });
    }
  }

  // Fungsi untuk menangani Game Over
  void gameOver() {
    isGameOver = true; // Set status game over

    // Reset skor
    score = 0;

    scoreText.text = 'Score: $score'; // Reset teks skor

    // Tambahkan teks Game Over ke dalam game
    add(gameOverText);

    // Setelah beberapa detik, restart game
    Future.delayed(Duration(seconds: 3), () {
      resetGame(); // Reset game setelah delay
    });
  }

  // Fungsi untuk mereset game
  void resetGame() {
    // Reset semua variabel
    score = 0;
    level = 1;
    burgerCount = 10;
    missedBurgers = 0; // Reset counter burger yang jatuh
    bomCount = 0; // Reset jumlah bom
    isGameOver = false;

    // Reset posisi player dan teks skor
    player.position = Vector2(size.x / 2, size.y - 100);
    scoreText.text = 'Score: $score';

    // Hapus teks "Game Over"
    remove(gameOverText);

    // Spawn burger untuk level awal
    startSpawningBurgers();
  }
}

// Kelas khusus untuk burger
class Burger extends SpriteComponent {
  Burger() : super();
}

// Kelas khusus untuk bom
class Bom extends SpriteComponent {
  Bom() : super();
}
