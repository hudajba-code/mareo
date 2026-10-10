<!DOCTYPE html>
<html lang="ar" dir="ltr">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Mario Style Game</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      background: #111;
      display: grid;
      place-items: center;
      min-height: 100vh;
      font-family: Arial, sans-serif;
      color: white;
    }

    canvas {
      width: min(96vw, 960px);
      height: auto;
      border: 4px solid #fff;
      background: linear-gradient(#7ad1ff, #d9f6ff);
      box-shadow: 0 0 25px rgba(0,0,0,0.5);
    }
  </style>
</head>
<body>
  <canvas id="game" width="960" height="540"></canvas>

  <script>
    const canvas = document.getElementById("game");
    const ctx = canvas.getContext("2d");

    const TILE = 32;
    const WIDTH = canvas.width;
    const HEIGHT = canvas.height;
    const GRAVITY = 1500;
    const MAP_COLS = 200;
    const MAP_ROWS = 18;
    const WORLD_WIDTH = MAP_COLS * TILE;
    const WORLD_HEIGHT = MAP_ROWS * TILE;

    const keys = {
      left: false,
      right: false,
      jump: false
    };

    const state = {
      score: 0,
      lives: 3,
      timeLeft: 200,
      won: false,
      gameOver: false
    };

    const level = [];
    for (let y = 0; y < MAP_ROWS; y++) {
      const row = Array(MAP_COLS).fill(" ");
      level.push(row);
    }

    function setTile(x, y, ch) {
      if (y >= 0 && y < MAP_ROWS && x >= 0 && x < MAP_COLS) {
        level[y][x] = ch;
      }
    }

    function isSolid(ch) {
      return ch === "1" || ch === "2" || ch === "3";
    }

    function solidAtWorld(x, y) {
      const tx = Math.floor(x / TILE);
      const ty = Math.floor(y / TILE);
      if (ty < 0 || ty >= level.length || tx < 0 || tx >= level[0].length) return true;
      return isSolid(level[ty][tx]);
    }

    function buildLevel() {
      // Ground
      for (let x = 0; x < MAP_COLS; x++) {
        setTile(x, MAP_ROWS - 1, "2");
      }

      // Small platform sections
      for (let x = 10; x < 24; x++) setTile(x, 12, "1");
      for (let x = 28; x < 38; x++) setTile(x, 10, "1");
      for (let x = 45; x < 60; x++) setTile(x, 9, "1");
      for (let x = 65; x < 78; x++) setTile(x, 11, "1");
      for (let x = 82; x < 96; x++) setTile(x, 8, "1");
      for (let x = 110; x < 124; x++) setTile(x, 10, "1");
      for (let x = 135; x < 150; x++) setTile(x, 9, "1");
      for (let x = 158; x < 176; x++) setTile(x, 11, "1");
      for (let x = 180; x < 194; x++) setTile(x, 8, "1");

      // Decorative bricks
      for (let x = 4; x < 8; x++) setTile(x, 13, "3");
      for (let x = 90; x < 94; x++) setTile(x, 13, "3");
      for (let x = 130; x < 136; x++) setTile(x, 13, "3");
      for (let x = 170; x < 175; x++) setTile(x, 13, "3");

      // Coins
      const coinPositions = [
        [12, 10], [14, 10], [16, 10], [30, 8], [33, 8], [48, 7],
        [52, 7], [69, 9], [84, 6], [118, 8], [138, 7], [162, 9], [186, 6]
      ];
      coinPositions.forEach(([x, y]) => setTile(x, y, "c"));

      // Flag pole
      for (let y = 5; y <= 15; y++) setTile(188, y, "f");
      setTile(189, 5, "f");
      setTile(190, 5, "f");
      setTile(191, 5, "f");
    }

    function resetPlayer() {
      if (!player) {
        player = {
          x: 80,
          y: 100,
          w: 28,
          h: 40,
          vx: 0,
          vy: 0,
          onGround: false,
          facing: 1
        };
      } else {
        player.x = 80;
        player.y = 100;
        player.vx = 0;
        player.vy = 0;
        player.onGround = false;
      }
    }

    let player = {
      x: 80,
      y: 100,
      w: 28,
      h: 40,
      vx: 0,
      vy: 0,
      onGround: false,
      facing: 1
    };

    let enemies = [];
    function spawnEnemies() {
      enemies = [
        { x: 500, y: 440, w: 28, h: 30, minX: 470, maxX: 620, vx: 80, alive: true },
        { x: 820, y: 440, w: 28, h: 30, minX: 780, maxX: 930, vx: 100, alive: true },
        { x: 1180, y: 430, w: 28, h: 30, minX: 1080, maxX: 1350, vx: 90, alive: true }
      ];
    }

    function getCameraX() {
      return Math.max(0, Math.min(player.x - WIDTH / 2, WORLD_WIDTH - WIDTH));
    }

    function drawBackground(cameraX) {
      ctx.fillStyle = "#8ed7ff";
      ctx.fillRect(0, 0, WIDTH, HEIGHT);

      // Mountains
      ctx.fillStyle = "#7ebc7a";
      for (let i = 0; i < 8; i++) {
        const x = i * 180 - (cameraX * 0.2) % 180;
        ctx.beginPath();
        ctx.moveTo(x, HEIGHT);
        ctx.lineTo(x + 90, 200);
        ctx.lineTo(x + 180, HEIGHT);
        ctx.closePath();
        ctx.fill();
      }

      // Clouds
      ctx.fillStyle = "rgba(255,255,255,0.8)";
      for (let i = 0; i < 8; i++) {
        const cx = (i * 170 - cameraX * 0.4) % (WIDTH + 200) - 100;
        const cy = 70 + (i % 3) * 50;
        ctx.beginPath();
        ctx.arc(cx, cy, 25, 0, Math.PI * 2);
        ctx.arc(cx + 25, cy - 10, 28, 0, Math.PI * 2);
        ctx.arc(cx + 55, cy, 22, 0, Math.PI * 2);
        ctx.fill();
      }
    }

    function drawTile(x, y, ch) {
      const px = x * TILE;
      const py = y * TILE;

      if (ch === "1" || ch === "3") {
        ctx.fillStyle = "#c6702d";
        ctx.fillRect(px, py, TILE, TILE);
        ctx.fillStyle = "#8d4a17";
        ctx.fillRect(px, py, TILE, 5);
        ctx.fillStyle = "#d98d4a";
        ctx.fillRect(px + 4, py + 6, TILE - 8, TILE - 12);

        if (ch === "3") {
          ctx.fillStyle = "#9f5c2a";
          ctx.fillRect(px + 4, py + 4, TILE - 8, 5);
        }
      }

      if (ch === "2") {
        ctx.fillStyle = "#35a63a";
        ctx.fillRect(px, py, TILE, TILE);
        ctx.fillStyle = "#238f2f";
        ctx.fillRect(px, py, TILE, 7);
        ctx.fillStyle = "#2ca041";
        for (let i = 0; i < 8; i++) {
          ctx.fillRect(px + (i * 4) + 2, py + 12 + (i % 2) * 7, 2, 8);
        }
      }

      if (ch === "c") {
        ctx.fillStyle = "#ffd93b";
        ctx.beginPath();
        ctx.arc(px + TILE / 2, py + TILE / 2, 8, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = "#f2b400";
        ctx.fillRect(px + TILE / 2 - 2, py + 2, 4, 6);
      }

      if (ch === "f") {
        ctx.fillStyle = "#e9e9e9";
        ctx.fillRect(px, py, 6, TILE);
        ctx.fillStyle = "#ff3d3d";
        ctx.fillRect(px - 10, py, 26, 12);
        ctx.fillStyle = "#fff";
        ctx.fillRect(px - 9, py + 2, 5, 5);
      }
    }

    function drawLevel(cameraX) {
      ctx.save();
      ctx.translate(-cameraX, 0);

      for (let y = 0; y < MAP_ROWS; y++) {
        for (let x = 0; x < MAP_COLS; x++) {
          const ch = level[y][x];
          if (ch !== " ") drawTile(x, y, ch);
        }
      }

      // Draw enemies
      enemies.forEach(e => {
        if (!e.alive) return;
        ctx.fillStyle = "#8b3a22";
        ctx.fillRect(e.x, e.y, e.w, e.h);
        ctx.fillStyle = "#fff";
        ctx.fillRect(e.x + 6, e.y + 7, 4, 4);
        ctx.fillRect(e.x + e.w - 10, e.y + 7, 4, 4);
        ctx.fillStyle = "#111";
        ctx.fillRect(e.x + 8, e.y + 9, 2, 2);
        ctx.fillRect(e.x + e.w - 10, e.y + 9, 2, 2);
      });

      // Draw player
      ctx.fillStyle = "#ff5252";
      ctx.fillRect(player.x, player.y, player.w, 10); // hat
      ctx.fillStyle = "#1e67ff";
      ctx.fillRect(player.x, player.y + 10, player.w, player.h - 10); // body
      ctx.fillStyle = "#f1c27d";
      ctx.fillRect(player.x + 4, player.y + 18, player.w - 8, 12); // face
      ctx.fillStyle = "#000";
      ctx.fillRect(player.x + 6, player.y + 22, 3, 3);
      ctx.fillRect(player.x + player.w - 9, player.y + 22, 3, 3);

      // Shoes
      ctx.fillStyle = "#8a4d19";
      ctx.fillRect(player.x + 2, player.y + player.h - 6, 10, 6);
      ctx.fillRect(player.x + player.w - 12, player.y + player.h - 6, 10, 6);

      ctx.restore();
    }

    function updatePlayer(dt) {
      const move = (keys.right ? 1 : 0) - (keys.left ? 1 : 0);
      player.vx = move * 240;

      if (move !== 0) player.facing = move;

      if (keys.jump && player.onGround) {
        player.vy = -520;
        player.onGround = false;
      }

      // Horizontal collision
      const oldX = player.x;
      player.x += player.vx * dt;
      for (let y = Math.floor(player.y / TILE); y <= Math.floor((player.y + player.h) / TILE); y++) {
        for (let x = Math.floor(player.x / TILE); x <= Math.floor((player.x + player.w) / TILE); x++) {
          if (x < 0 || y < 0 || x >= MAP_COLS || y >= MAP_ROWS) continue;
          if (isSolid(level[y][x])) {
            if (player.vx > 0) {
              player.x = x * TILE - player.w;
            } else if (player.vx < 0) {
              player.x = x * TILE + TILE;
            }
            player.vx = 0;
          }
        }
      }

      // Vertical physics
      player.vy += GRAVITY * dt;
      const oldY = player.y;
      player.y += player.vy * dt;
      player.onGround = false;

      for (let y = Math.floor(player.y / TILE); y <= Math.floor((player.y + player.h) / TILE); y++) {
        for (let x = Math.floor(player.x / TILE); x <= Math.floor((player.x + player.w) / TILE); x++) {
          if (x < 0 || y < 0 || x >= MAP_COLS || y >= MAP_ROWS) continue;
          if (isSolid(level[y][x])) {
            if (player.vy > 0) {
              player.y = y * TILE - player.h;
              player.vy = 0;
              player.onGround = true;
            } else if (player.vy < 0) {
              player.y = y * TILE + TILE;
              player.vy = 0;
            }
          }
        }
      }

      // Collect coins
      const coinX = Math.floor((player.x + player.w / 2) / TILE);
      const coinY = Math.floor((player.y + player.h / 2) / TILE);
      if (coinY >= 0 && coinY < level.length && coinX >= 0 && coinX < level[0].length) {
        if (level[coinY][coinX] === "c") {
          level[coinY][coinX] = " ";
          state.score += 10;
        }
      }

      // Flag finish
      if (player.x > 188 * TILE - 20 && player.y + player.h > 5 * TILE) {
        state.won = true;
        state.score += 1000;
      }

      // Fall death
      if (player.y > WORLD_HEIGHT + 80) {
        loseLife();
      }
    }

    function updateEnemies(dt) {
      enemies.forEach(e => {
        if (!e.alive) return;

        e.x += e.vx * dt;
        if (e.x < e.minX || e.x + e.w > e.maxX) {
          e.vx *= -1;
          e.x = Math.max(e.minX, Math.min(e.x, e.maxX - e.w));
        }

        const topHit =
          player.y + player.h <= e.y + 12 &&
          player.y + player.h >= e.y - 5 &&
          player.x + player.w > e.x &&
          player.x < e.x + e.w &&
          player.vy > 80;

        if (topHit) {
          e.alive = false;
          player.vy = -350;
          state.score += 100;
        } else if (
          player.x + player.w > e.x &&
          player.x < e.x + e.w &&
          player.y + player.h > e.y &&
          player.y < e.y + e.h
        ) {
          loseLife();
        }
      });
    }

    function loseLife() {
      if (state.gameOver) return;

      state.lives -= 1;

      if (state.lives <= 0) {
        state.gameOver = true;
        return;
      }

      resetPlayer();
      enemies.forEach(e => e.alive = true);
    }

    function drawHUD() {
      ctx.fillStyle = "rgba(0,0,0,0.35)";
      ctx.fillRect(10, 10, 250, 80);

      ctx.fillStyle = "#fff";
      ctx.font = "20px Arial";
      ctx.fillText("Score: " + state.score, 22, 38);
      ctx.fillText("Lives: " + state.lives, 22, 62);
      ctx.fillText("Time: " + Math.ceil(state.timeLeft), 22, 86);

      if (state.won) {
        ctx.fillStyle = "rgba(0,0,0,0.6)";
        ctx.fillRect(250, 190, 460, 140);
        ctx.fillStyle = "#fff";
        ctx.font = "bold 42px Arial";
        ctx.fillText("YOU WIN!", 360, 250);
        ctx.font = "24px Arial";
        ctx.fillText("Press R to restart", 360, 290);
      } else if (state.gameOver) {
        ctx.fillStyle = "rgba(0,0,0,0.6)";
        ctx.fillRect(250, 190, 460, 140);
        ctx.fillStyle = "#fff";
        ctx.font = "bold 42px Arial";
        ctx.fillText("GAME OVER", 330, 250);
        ctx.font = "24px Arial";
        ctx.fillText("Press R to restart", 360, 290);
      }
    }

    function update(dt) {
      if (state.won || state.gameOver) {
        if (keys.restart) {
          restartGame();
        }
        return;
      }

      state.timeLeft -= dt;
      if (state.timeLeft <= 0) {
        loseLife();
        state.timeLeft = 200;
      }

      updatePlayer(dt);
      updateEnemies(dt);
    }

    function restartGame() {
      buildLevel();
      resetPlayer();
      spawnEnemies();
      state.score = 0;
      state.lives = 3;
      state.timeLeft = 200;
      state.won = false;
      state.gameOver = false;
    }

    document.addEventListener("keydown", (e) => {
      if (e.key === "ArrowLeft" || e.key.toLowerCase() === "a") keys.left = true;
      if (e.key === "ArrowRight" || e.key.toLowerCase() === "d") keys.right = true;
      if (e.key === "ArrowUp" || e.key === " " || e.key.toLowerCase() === "w") {
        keys.jump = true;
      }
      if (e.key.toLowerCase() === "r") {
        keys.restart = true;
        restartGame();
      }
    });

    document.addEventListener("keyup", (e) => {
      if (e.key === "ArrowLeft" || e.key.toLowerCase() === "a") keys.left = false;
      if (e.key === "ArrowRight" || e.key.toLowerCase() === "d") keys.right = false;
      if (e.key === "ArrowUp" || e.key === " " || e.key.toLowerCase() === "w") {
        keys.jump = false;
      }
      if (e.key.toLowerCase() === "r") keys.restart = false;
    });

    let lastTime = 0;
    function loop(ts) {
      const dt = Math.min((ts - lastTime) / 1000, 0.033);
      lastTime = ts;

      update(dt);
      const cameraX = getCameraX();

      drawBackground(cameraX);
      drawLevel(cameraX);
      drawHUD();

      requestAnimationFrame(loop);
    }

    buildLevel();
    spawnEnemies();
    resetPlayer();
    requestAnimationFrame(loop);
  </script>
</body>
</html>import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaskMasterApp());
}

class AppTheme {
  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceAlt = Color(0xFF21262D);
  static const Color border = Color(0xFF30363D);
  static const Color primary = Color(0xFF1F6FEB);
  static const Color primaryLight = Color(0xFF58A6FF);
  static const Color success = Color(0xFF2EA043);
  static const Color danger = Color(0xFFCF222E);
  static const Color warning = Color(0xFFD29922);
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textMuted = Color(0xFF8B949E);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: primaryLight,
          surface: surface,
          error: danger,
          onPrimary: Colors.white,
          onSurface: textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceAlt,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primaryLight, width: 1.5),
          ),
        ),
      );
}

class Task {
  final String id;
  String title;
  bool done;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.done = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'done': done,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        done: json['done'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class TaskMasterApp extends StatelessWidget {
  const TaskMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mareo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const TaskHomePage(),
    );
  }
}

enum TaskFilter { all, active, completed }

class TaskHomePage extends StatefulWidget {
  const TaskHomePage({super.key});

  @override
  State<TaskHomePage> createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage>
    with SingleTickerProviderStateMixin {
  static const String _storageKey = 'klencod_tasks_v1';

  final List<Task> _tasks = [];
  final TextEditingController _searchController = TextEditingController();
  TaskFilter _filter = TaskFilter.all;
  String _searchQuery = '';
  bool _loading = true;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadTasks();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data != null && data.isNotEmpty) {
        final list = jsonDecode(data) as List<dynamic>;
        _tasks.clear();
        _tasks.addAll(list.map((e) => Task.fromJson(e as Map<String, dynamic>)));
      }
    } catch (_) {}
    setState(() => _loading = false);
    _fadeController.forward();
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_tasks.map((t) => t.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (_) {}
  }

  void _addTask(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _tasks.insert(
        0,
        Task(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: trimmed,
          createdAt: DateTime.now(),
        ),
      );
    });
    _saveTasks();
    HapticFeedback.lightImpact();
    _showSnack('تمت إضافة المهمة', success: true);
  }

  void _toggleTask(Task task) {
    setState(() => task.done = !task.done);
    _saveTasks();
    HapticFeedback.selectionClick();
  }

  void _deleteTask(Task task) {
    final index = _tasks.indexOf(task);
    if (index == -1) return;
    setState(() => _tasks.removeAt(index));
    _saveTasks();
    _showSnack(
      'تم حذف المهمة',
      actionLabel: 'تراجع',
      onAction: () {
        setState(() => _tasks.insert(index, task));
        _saveTasks();
      },
    );
  }

  void _clearCompleted() {
    final completed = _tasks.where((t) => t.done).toList();
    if (completed.isEmpty) {
      _showSnack('لا توجد مهام مكتملة');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => _buildConfirmDialog(
        ctx,
        title: 'حذف المهام المكتملة',
        message: 'سيتم حذف ${completed.length} مهمة مكتملة. لا يمكن التراجع.',
        onConfirm: () {
          setState(() => _tasks.removeWhere((t) => t.done));
          _saveTasks();
          Navigator.pop(ctx);
          _showSnack('تم حذف ${completed.length} مهمة', success: true);
        },
      ),
    );
  }

  void _showSnack(String message,
      {String? actionLabel, VoidCallback? onAction, bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: success ? AppTheme.success : AppTheme.textPrimary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceAlt,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: AppTheme.primaryLight,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }

  Widget _buildConfirmDialog(
    BuildContext ctx, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
      content: Text(message, style: const TextStyle(color: AppTheme.textMuted)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إلغاء',
              style: TextStyle(color: AppTheme.textMuted)),
        ),
        TextButton(
          onPressed: onConfirm,
          child: const Text('تأكيد',
              style: TextStyle(
                  color: AppTheme.danger, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _openAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.add_task_rounded, color: AppTheme.primaryLight),
            SizedBox(width: 10),
            Text('مهمة جديدة',
                style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) {
            _addTask(v);
            Navigator.pop(ctx);
          },
          decoration: const InputDecoration(
            hintText: 'اكتب المهمة...',
            prefixIcon: Icon(Icons.edit_rounded),
          ),
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          FilledButton(
            onPressed: () {
              _addTask(controller.text);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  List<Task> get _visibleTasks {
    Iterable<Task> result = _tasks;
    if (_filter == TaskFilter.active) {
      result = result.where((t) => !t.done);
    } else if (_filter == TaskFilter.completed) {
      result = result.where((t) => t.done);
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((t) => t.title.toLowerCase().contains(q));
    }
    return result.toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryLight),
        ),
      );
    }

    final visible = _visibleTasks;
    final total = _tasks.length;
    final completed = _tasks.where((t) => t.done).length;
    final active = total - completed;
    final progress = total == 0 ? 0.0 : completed / total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('mareo'),
        actions: [
          if (completed > 0)
            IconButton(
              tooltip: 'حذف المكتملة',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _clearCompleted,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('مهمة جديدة',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildHeader(total, completed, active, progress),
          _buildSearchBar(),
          _buildFilters(total, active, completed),
          Expanded(
            child: visible.isEmpty
                ? _buildEmptyState()
                : _buildTaskList(visible),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int total, int completed, int active, double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1F6FEB), Color(0xFF0D419D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.task_alt_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(width: 10),
                Text(
                  total == 0 ? 'لا توجد مهام بعد' : 'مهامك',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statChip('الإجمالي', total, Colors.white),
                _statChip('نشطة', active, AppTheme.warning),
                _statChip('مكتملة', completed, AppTheme.success),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 600),
                builder: (_, value, __) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% إنجاز',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'بحث في المهام...',
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppTheme.textMuted),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppTheme.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilters(int total, int active, int completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _filterChip('الكل', TaskFilter.all, total),
          const SizedBox(width: 8),
          _filterChip('نشطة', TaskFilter.active, active),
          const SizedBox(width: 8),
          _filterChip('مكتملة', TaskFilter.completed, completed),
        ],
      ),
    );
  }

  Widget _filterChip(String label, TaskFilter filter, int count) {
    final selected = _filter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : AppTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primaryLight : AppTheme.border,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: selected ? Colors.white : AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white70 : AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Task> visible) {
    return FadeTransition(
      opacity: _fadeController,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
        itemCount: visible.length,
        itemBuilder: (context, index) {
          final task = visible[index];
          return _buildTaskItem(task);
        },
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.danger,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_rounded,
            color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) async {
        _deleteTask(task);
        return false;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: task.done
                ? AppTheme.success.withOpacity(0.4)
                : AppTheme.border,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _toggleTask(task),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: task.done
                          ? AppTheme.success
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: task.done
                            ? AppTheme.success
                            : AppTheme.textMuted,
                        width: 2,
                      ),
                    ),
                    child: task.done
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            color: task.done
                                ? AppTheme.textMuted
                                : AppTheme.textPrimary,
                            fontSize: 15,
                            decoration: task.done
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(task.createdAt),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'حذف',
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.textMuted),
                    onPressed: () => _deleteTask(task),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays == 1) return 'أمس';
    return 'منذ ${diff.inDays} يوم';
  }

  Widget _buildEmptyState() {
    final String message;
    final IconData icon;
    if (_searchQuery.isNotEmpty) {
      message = 'لا توجد نتائج للبحث';
      icon = Icons.search_off_rounded;
    } else if (_filter == TaskFilter.completed) {
      message = 'لا توجد مهام مكتملة بعد';
      icon = Icons.check_circle_outline_rounded;
    } else if (_filter == TaskFilter.active) {
      message = 'كل المهام مكتملة!';
      icon = Icons.celebration_rounded;
    } else {
      message = 'ابدأ بإضافة مهمتك الأولى';
      icon = Icons.playlist_add_rounded;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(icon, size: 56, color: AppTheme.primaryLight),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'استخدم الزر أدناه للبدء',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}