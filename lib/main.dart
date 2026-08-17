import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_feedback.dart';
import 'word_data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: navy,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const UndercoverApp());
}

const navy = Color(0xFF0D1020);
const panel = Color(0xFF171B2E);
const cream = Color(0xFFF7F4EC);
const muted = Color(0xFF9DA4BA);
const lime = Color(0xFFC8F36A);
const coral = Color(0xFFFF706A);
const ease = Cubic(0.23, 1, 0.32, 1);

class UndercoverApp extends StatefulWidget {
  const UndercoverApp({super.key});
  @override
  State<UndercoverApp> createState() => _UndercoverAppState();
}

class _UndercoverAppState extends State<UndercoverApp> {
  bool lightMode = false;
  bool soundEnabled = true;
  bool hapticsEnabled = true;
  bool animationsEnabled = true;
  double textScale = 1;
  bool showFirstRunGuide = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      lightMode = prefs.getBool('lightMode') ?? false;
      soundEnabled = prefs.getBool('soundEnabled') ?? true;
      hapticsEnabled = prefs.getBool('hapticsEnabled') ?? true;
      animationsEnabled = prefs.getBool('animationsEnabled') ?? true;
      textScale = prefs.getDouble('textScale') ?? 1;
      showFirstRunGuide = !(prefs.getBool('firstRunGuideSeen') ?? false);
      AppAudio.enabled = soundEnabled;
      AppAudio.hapticsEnabled = hapticsEnabled;
    });
  }

  Future<void> _save(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    switch (value) {
      case bool value:
        await prefs.setBool(key, value);
      case double value:
        await prefs.setDouble(key, value);
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'El Impostor',
    themeMode: lightMode ? ThemeMode.light : ThemeMode.dark,
    darkTheme: ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: navy,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6C8CFF),
        onPrimary: navy,
        secondary: coral,
        onSecondary: navy,
        surface: panel,
        onSurface: cream,
        onSurfaceVariant: Color(0xFFB8BFD2),
        outline: Color(0xFF30364E),
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: cream,
        displayColor: cream,
        fontFamily: 'sans',
      ),
    ),
    theme: ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF3F5ED),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF3568E8),
        onPrimary: Colors.white,
        secondary: coral,
        onSecondary: navy,
        surface: Color(0xFFFAFCF5),
        onSurface: Color(0xFF15182A),
        onSurfaceVariant: Color(0xFF5D6478),
        outline: Color(0xFFD5DAE5),
      ),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: Color(0xFF15182A),
        displayColor: Color(0xFF15182A),
        fontFamily: 'sans',
      ),
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: !animationsEnabled,
      ),
      child: child!,
    ),
    home: GameShell(
      lightMode: lightMode,
      soundEnabled: soundEnabled,
      hapticsEnabled: hapticsEnabled,
      animationsEnabled: animationsEnabled,
      textScale: textScale,
      onToggleTheme: () {
        setState(() => lightMode = !lightMode);
        _save('lightMode', lightMode);
      },
      onSoundChanged: (value) {
        setState(() => soundEnabled = value);
        AppAudio.enabled = value;
        _save('soundEnabled', value);
      },
      onHapticsChanged: (value) {
        setState(() => hapticsEnabled = value);
        AppAudio.hapticsEnabled = value;
        _save('hapticsEnabled', value);
      },
      onAnimationsChanged: (value) {
        setState(() => animationsEnabled = value);
        _save('animationsEnabled', value);
      },
      onTextScaleChanged: (value) {
        setState(() => textScale = value);
        _save('textScale', value);
      },
      showFirstRunGuide: showFirstRunGuide,
      onFirstRunGuideShown: () {
        setState(() => showFirstRunGuide = false);
        _save('firstRunGuideSeen', true);
      },
    ),
  );
}

enum GameStep { home, setup, reveal, discussion, result, settings }

class PlayerRole {
  const PlayerRole(this.name, this.isImpostor);
  final String name;
  final bool isImpostor;
}

ColorScheme colorsOf(BuildContext context) => Theme.of(context).colorScheme;

const categoryEmoji = <String, String>{
  'Al azar': '🎲',
  'Lugares': '📍',
  'Comida': '🍽️',
  'Objetos': '🎒',
  'Animales': '🐾',
  'Profesiones': '💼',
  'Deportes': '🏅',
  'Transportes': '🚗',
  'Instrumentos': '🎵',
  'Personajes': '🎭',
  'Acciones': '⚡',
  'Actores': '🎬',
  'Cantantes': '🎤',
  'Escuela': '🏫',
  'Infantiles': '🧸',
};

const categoryDescription = <String, String>{
  'Al azar': 'Una sorpresa en cada ronda',
  'Lugares': 'Sitios y destinos',
  'Comida': 'Platos y sabores',
  'Objetos': 'Cosas de cada día',
  'Animales': 'De tierra, mar y aire',
  'Profesiones': 'Oficios y trabajos',
  'Deportes': 'Juegos y competición',
  'Transportes': 'Formas de moverse',
  'Instrumentos': 'Sonidos y música',
  'Personajes': 'Historias y leyendas',
  'Acciones': 'Cosas que hacemos',
  'Actores': 'Estrellas del cine',
  'Cantantes': 'Voces y escenarios',
  'Escuela': 'Clases y aprendizaje',
  'Infantiles': 'Juegos y fantasía',
};

class GameShell extends StatefulWidget {
  const GameShell({
    required this.lightMode,
    required this.onToggleTheme,
    required this.soundEnabled,
    required this.hapticsEnabled,
    required this.animationsEnabled,
    required this.textScale,
    required this.onSoundChanged,
    required this.onHapticsChanged,
    required this.onAnimationsChanged,
    required this.onTextScaleChanged,
    required this.showFirstRunGuide,
    required this.onFirstRunGuideShown,
    super.key,
  });
  final bool lightMode;
  final bool soundEnabled, hapticsEnabled, animationsEnabled;
  final double textScale;
  final bool showFirstRunGuide;
  final VoidCallback onToggleTheme;
  final VoidCallback onFirstRunGuideShown;
  final ValueChanged<bool> onSoundChanged,
      onHapticsChanged,
      onAnimationsChanged;
  final ValueChanged<double> onTextScaleChanged;
  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell> {
  GameStep step = GameStep.home;
  final players = <String>[];
  final nameController = TextEditingController();
  int impostorCount = 1;
  int revealIndex = 0;
  int round = 0;
  bool hintEnabled = true;
  int roundMinutes = 3;
  int totalRounds = 5;
  String category = 'Al azar';
  String activeCategory = 'Lugares';
  String secretWord = '';
  List<PlayerRole> roles = const [];
  bool guideScheduled = false;

  @override
  void didUpdateWidget(covariant GameShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showFirstRunGuide && !guideScheduled) {
      guideScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onFirstRunGuideShown();
        showHowToPlay(context, firstTime: true);
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void go(GameStep next) => setState(() => step = next);

  void startMatch() {
    round = 0;
    startRound();
  }

  void startRound() {
    final random = Random();
    activeCategory = category == 'Al azar'
        ? wordBank.keys.elementAt(random.nextInt(wordBank.length))
        : category;
    final shuffled = [...players]..shuffle(random);
    final impostors = shuffled.take(impostorCount).toSet();
    final categoryWords = wordBank[activeCategory]!.keys.toList();
    secretWord = categoryWords[random.nextInt(categoryWords.length)];
    roles = players
        .map((name) => PlayerRole(name, impostors.contains(name)))
        .toList();
    revealIndex = 0;
    round++;
    go(GameStep.reveal);
  }

  void nextPlayer() {
    if (revealIndex == roles.length - 1) {
      go(GameStep.discussion);
      return;
    }
    setState(() {
      revealIndex++;
      step = GameStep.reveal;
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: step == GameStep.home,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) go(step == GameStep.setup ? GameStep.home : GameStep.setup);
    },
    child: Scaffold(
      body: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.lightMode
                    ? const [
                        Color(0xFFF9FBF4),
                        Color(0xFFF1F4E9),
                        Color(0xFFE9EEE0),
                      ]
                    : const [Color(0xFF191D34), navy, Color(0xFF111729)],
              ),
            ),
            child: SizedBox.expand(),
          ),
          SafeArea(
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              reverseDuration: const Duration(milliseconds: 130),
              switchInCurve: ease,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(.055, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: ease)),
                  child: child,
                ),
              ),
              child: switch (step) {
                GameStep.home => HomeScreen(
                  key: const ValueKey('home'),
                  onStart: () => go(GameStep.setup),
                  lightMode: widget.lightMode,
                  onToggleTheme: widget.onToggleTheme,
                  onSettings: () => go(GameStep.settings),
                ),
                GameStep.setup => SetupScreen(
                  key: const ValueKey('setup'),
                  players: players,
                  controller: nameController,
                  category: category,
                  impostors: impostorCount,
                  hintEnabled: hintEnabled,
                  roundMinutes: roundMinutes,
                  totalRounds: totalRounds,
                  onBack: () => go(GameStep.home),
                  onCategory: (v) => setState(() => category = v),
                  onImpostors: (v) => setState(() => impostorCount = v),
                  onHintChanged: (v) => setState(() => hintEnabled = v),
                  onRoundMinutes: (v) => setState(() => roundMinutes = v),
                  onTotalRounds: (v) => setState(() => totalRounds = v),
                  onAdd: () {
                    var n = nameController.text.trim();
                    if (n.isEmpty) {
                      var number = 1;
                      while (players.contains('Jugador $number')) {
                        number++;
                      }
                      n = 'Jugador $number';
                    }
                    if (players.length < 12 && !players.contains(n)) {
                      setState(() {
                        players.add(n);
                        nameController.clear();
                      });
                    }
                  },
                  onRemove: (n) => setState(() {
                    players.remove(n);
                    impostorCount = min(
                      impostorCount,
                      max(1, players.length - 2),
                    );
                  }),
                  onStart: startMatch,
                ),
                GameStep.reveal => RevealScreen(
                  key: ValueKey('role-$revealIndex'),
                  role: roles[revealIndex],
                  index: revealIndex + 1,
                  total: roles.length,
                  word: secretWord,
                  hint: hintEnabled
                      ? wordBank[activeCategory]![secretWord]!
                      : '',
                  onNext: nextPlayer,
                ),
                GameStep.discussion => DiscussionScreen(
                  key: ValueKey('discussion-$round'),
                  durationSeconds: roundMinutes * 60,
                  round: round,
                  totalRounds: totalRounds,
                  onReveal: () => go(GameStep.result),
                ),
                GameStep.result => ResultScreen(
                  key: ValueKey('result-$round'),
                  word: secretWord,
                  impostors: roles
                      .where((r) => r.isImpostor)
                      .map((r) => r.name)
                      .toList(),
                  round: round,
                  totalRounds: totalRounds,
                  onAgain: totalRounds == 0 || round < totalRounds
                      ? startRound
                      : () => go(GameStep.setup),
                  onHome: () => go(GameStep.home),
                ),
                GameStep.settings => SettingsScreen(
                  key: const ValueKey('settings'),
                  lightMode: widget.lightMode,
                  soundEnabled: widget.soundEnabled,
                  hapticsEnabled: widget.hapticsEnabled,
                  animationsEnabled: widget.animationsEnabled,
                  textScale: widget.textScale,
                  onBack: () => go(GameStep.home),
                  onToggleTheme: widget.onToggleTheme,
                  onSoundChanged: widget.onSoundChanged,
                  onHapticsChanged: widget.onHapticsChanged,
                  onAnimationsChanged: widget.onAnimationsChanged,
                  onTextScaleChanged: widget.onTextScaleChanged,
                ),
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onStart,
    required this.lightMode,
    required this.onToggleTheme,
    required this.onSettings,
    super.key,
  });
  final VoidCallback onStart;
  final bool lightMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onSettings;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 52,
          child: Row(
            children: [
              const Brand(),
              const Spacer(),
              IconButton(
                onPressed: onSettings,
                tooltip: 'Ajustes',
                style: IconButton.styleFrom(
                  backgroundColor: colorsOf(context).surface,
                  foregroundColor: colorsOf(context).onSurface,
                  side: BorderSide(color: colorsOf(context).outline),
                ),
                icon: const Icon(Icons.settings_rounded),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onToggleTheme,
                tooltip: lightMode ? 'Usar tema oscuro' : 'Usar tema claro',
                style: IconButton.styleFrom(
                  backgroundColor: colorsOf(context).surface,
                  foregroundColor: colorsOf(context).onSurface,
                  side: BorderSide(color: colorsOf(context).outline),
                ),
                icon: Icon(
                  lightMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          '¿Podrás pasar\ndesapercibido?',
          style: TextStyle(
            fontSize: 46,
            height: .98,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Todos conocen la palabra. Todos menos uno. Haz preguntas, sospecha y no te delates.',
          style: TextStyle(
            color: colorsOf(context).onSurfaceVariant,
            fontSize: 17,
            height: 1.45,
          ),
        ),
        const Spacer(),
        PrimaryButton(
          label: 'Jugar ahora',
          icon: Icons.arrow_forward_rounded,
          onTap: onStart,
        ),
        TextButton.icon(
          onPressed: () => showHowToPlay(context),
          icon: const Icon(Icons.help_outline_rounded, size: 18),
          label: const Text('Cómo jugar'),
          style: TextButton.styleFrom(
            foregroundColor: colorsOf(context).onSurfaceVariant,
          ),
        ),
        Center(
          child: Text(
            'Un móvil · Cero cuentas · Diversión instantánea',
            style: TextStyle(
              color: colorsOf(context).onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}

void showHowToPlay(BuildContext context, {bool firstTime = false}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              firstTime ? 'Bienvenido a Impostor' : 'Cómo jugar',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              firstTime
                  ? 'En menos de un minuto estaréis jugando.'
                  : 'Encuentra al impostor sin revelar la palabra secreta.',
              style: TextStyle(
                color: colorsOf(context).onSurfaceVariant,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 22),
            const HowToStep(
              number: '1',
              title: 'Añade al grupo',
              text: 'Introduce al menos tres nombres y elige una categoría.',
            ),
            const HowToStep(
              number: '2',
              title: 'Desliza y descubre',
              text:
                  'Pasa el móvil. Cada persona desliza la tarjeta hacia arriba para ver su rol.',
            ),
            const HowToStep(
              number: '3',
              title: 'Da una pista',
              text:
                  'Todos dicen algo relacionado. El impostor improvisa para no ser descubierto.',
            ),
            const HowToStep(
              number: '4',
              title: 'Debate por rondas',
              text:
                  'Inicia el tiempo, votad y revelad al impostor. Puedes elegir cuántas rondas jugar.',
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: firstTime ? 'Empezar a jugar' : 'Entendido',
              icon: Icons.check_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    ),
  );
}

class HowToStep extends StatelessWidget {
  const HowToStep({
    required this.number,
    required this.title,
    required this.text,
    super.key,
  });
  final String number, title, text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorsOf(context).primary,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            number,
            style: TextStyle(
              color: colorsOf(context).onPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: TextStyle(
                  color: colorsOf(context).onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class SetupScreen extends StatelessWidget {
  const SetupScreen({
    required this.players,
    required this.controller,
    required this.category,
    required this.impostors,
    required this.hintEnabled,
    required this.roundMinutes,
    required this.totalRounds,
    required this.onBack,
    required this.onCategory,
    required this.onImpostors,
    required this.onHintChanged,
    required this.onRoundMinutes,
    required this.onTotalRounds,
    required this.onAdd,
    required this.onRemove,
    required this.onStart,
    super.key,
  });
  final List<String> players;
  final TextEditingController controller;
  final String category;
  final int impostors;
  final bool hintEnabled;
  final int roundMinutes;
  final int totalRounds;
  final VoidCallback onBack, onAdd, onStart;
  final ValueChanged<String> onCategory, onRemove;
  final ValueChanged<int> onImpostors;
  final ValueChanged<bool> onHintChanged;
  final ValueChanged<int> onRoundMinutes;
  final ValueChanged<int> onTotalRounds;

  Future<void> pickCategory(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colorsOf(context).surface,
      elevation: 0,
      showDragHandle: false,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SizedBox(
        height: min(MediaQuery.sizeOf(context).height * .72, 620),
        child: Material(
          color: colorsOf(context).surface,
          surfaceTintColor: Colors.transparent,
          child: Column(
            children: [
              SizedBox(
                height: 30,
                child: Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorsOf(
                        context,
                      ).onSurfaceVariant.withValues(alpha: .65),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                color: colorsOf(context).surface,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
                child: const Text(
                  'Elige una categoría',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: colorsOf(context).outline.withValues(alpha: .65),
              ),
              Expanded(
                child: ClipRect(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(overscroll: false),
                    child: ListView.separated(
                      physics: const ClampingScrollPhysics(),
                      clipBehavior: Clip.hardEdge,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: wordBank.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final item = index == 0
                            ? 'Al azar'
                            : wordBank.keys.elementAt(index - 1);
                        final selected = item == category;
                        return ListTile(
                          onTap: () => Navigator.pop(context, item),
                          leading: Text(
                            categoryEmoji[item]!,
                            style: const TextStyle(fontSize: 25),
                          ),
                          title: Text(
                            item,
                            style: TextStyle(
                              color: selected
                                  ? colorsOf(context).primary
                                  : colorsOf(context).onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            categoryDescription[item]!,
                            style: TextStyle(
                              color: colorsOf(context).onSurfaceVariant,
                            ),
                          ),
                          trailing: selected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: colorsOf(context).primary,
                                )
                              : null,
                          selected: selected,
                          selectedColor: colorsOf(context).primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) onCategory(selected);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Header(title: 'Nueva partida', onBack: onBack),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
          children: [
            SectionTitle('JUGADORES', '${players.length}/12'),
            const SizedBox(height: 12),
            if (players.length < 3) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorsOf(context).primary.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorsOf(context).primary.withValues(alpha: .22),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.group_add_rounded,
                      color: colorsOf(context).primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        players.isEmpty
                            ? 'Introduce al menos tres jugadores.'
                            : 'Añade ${3 - players.length} ${3 - players.length == 1 ? 'jugador más' : 'jugadores más'}.',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => onAdd(),
                    decoration: inputDecoration(
                      context,
                      'Nombre del jugador (sugerido)',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SquareButton(
                  icon: Icons.add_rounded,
                  onTap: players.length < 12 ? onAdd : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: players
                  .map(
                    (n) => InputChip(
                      label: Text(n),
                      onDeleted: () => onRemove(n),
                      deleteIconColor: colorsOf(context).onSurfaceVariant,
                      backgroundColor: colorsOf(context).surface,
                      side: BorderSide(color: colorsOf(context).outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 28),
            const SectionTitle('CATEGORÍA', 'Una palabra al azar'),
            const SizedBox(height: 12),
            Material(
              color: colorsOf(context).surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: colorsOf(context).outline),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                onTap: () => pickCategory(context),
                leading: Text(
                  categoryEmoji[category]!,
                  style: const TextStyle(fontSize: 25),
                ),
                title: Text(
                  category,
                  style: TextStyle(
                    color: colorsOf(context).onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  category == 'Al azar'
                      ? 'Se elegirá automáticamente'
                      : categoryDescription[category]!,
                  style: TextStyle(
                    color: colorsOf(context).onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                trailing: Icon(
                  Icons.expand_more_rounded,
                  color: colorsOf(context).onSurface,
                ),
              ),
            ),
            const SizedBox(height: 28),
            const SectionTitle('IMPOSTORES', 'Que no sea demasiado fácil'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorsOf(context).surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colorsOf(context).outline),
              ),
              child: Row(
                children: List.generate(min(3, max(1, players.length - 2)), (
                  i,
                ) {
                  final v = i + 1;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: SelectTile(
                        label: '$v',
                        selected: impostors == v,
                        onTap: () => onImpostors(v),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            const SectionTitle('TIEMPO DE RONDA', 'Duración del debate'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorsOf(context).surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colorsOf(context).outline),
              ),
              child: Row(
                children: [1, 2, 3, 5]
                    .map(
                      (minutes) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: SelectTile(
                            label: '$minutes min',
                            selected: roundMinutes == minutes,
                            onTap: () => onRoundMinutes(minutes),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            const SectionTitle('RONDAS', 'Cuántas veces queréis jugar'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorsOf(context).surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colorsOf(context).outline),
              ),
              child: Row(
                children: [3, 5, 10, 0]
                    .map(
                      (rounds) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: SelectTile(
                            label: rounds == 0 ? '∞' : '$rounds',
                            selected: totalRounds == rounds,
                            onTap: () => onTotalRounds(rounds),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: colorsOf(context).surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: colorsOf(context).outline),
              ),
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile.adaptive(
                value: hintEnabled,
                onChanged: onHintChanged,
                activeTrackColor: colorsOf(context).primary,
                activeThumbColor: colorsOf(context).onPrimary,
                secondary: Icon(
                  Icons.lightbulb_outline_rounded,
                  color: colorsOf(context).primary,
                ),
                title: const Text(
                  'Pista para el impostor',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  'Recibirá una única palabra relacionada',
                  style: TextStyle(
                    color: colorsOf(context).onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: PrimaryButton(
          label: 'Repartir roles',
          icon: Icons.shuffle_rounded,
          onTap: players.length >= 3 ? onStart : null,
        ),
      ),
    ],
  );
}

class RevealScreen extends StatefulWidget {
  const RevealScreen({
    required this.role,
    required this.index,
    required this.total,
    required this.word,
    required this.hint,
    required this.onNext,
    super.key,
  });
  final PlayerRole role;
  final int index, total;
  final String word;
  final String hint;
  final VoidCallback onNext;
  @override
  State<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends State<RevealScreen> {
  static const playerEmojis = ['🙂', '😎', '🤠', '🤓', '🥸', '😊', '🧐', '😄'];
  bool hasViewed = false;
  bool isDragging = false;
  double dragY = 0;

  void updateDrag(DragUpdateDetails details) {
    final next = (dragY + details.delta.dy).clamp(-300.0, 0.0);
    final firstReveal = !hasViewed && next < -72;
    setState(() {
      dragY = next;
      if (firstReveal) hasViewed = true;
    });
    if (firstReveal) AppAudio.feedback(AppSound.reveal);
  }

  void closeCard() {
    setState(() {
      isDragging = false;
      dragY = 0;
    });
  }

  @override
  Widget build(BuildContext context) => PageColumn(
    children: [
      Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: LinearProgressIndicator(
                value: widget.index / widget.total,
                minHeight: 6,
                backgroundColor: colorsOf(context).surface,
                color: colorsOf(context).primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '${widget.index} de ${widget.total}',
            style: TextStyle(color: colorsOf(context).onSurfaceVariant),
          ),
        ],
      ),
      const Spacer(),
      Container(
        width: 58,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorsOf(context).primary.withValues(alpha: .14),
          shape: BoxShape.circle,
          border: Border.all(
            color: colorsOf(context).primary.withValues(alpha: .28),
          ),
        ),
        child: Text(
          playerEmojis[(widget.index - 1) % playerEmojis.length],
          style: const TextStyle(fontSize: 31),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Turno de',
        style: TextStyle(
          color: colorsOf(context).onSurfaceVariant,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        widget.role.name,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 22),
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => setState(() => isDragging = true),
        onVerticalDragUpdate: updateDrag,
        onVerticalDragEnd: (_) => closeCard(),
        onVerticalDragCancel: closeCard,
        child: SizedBox(
          width: double.infinity,
          height: 326,
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                key: const ValueKey('reveal-back'),
                decoration: BoxDecoration(
                  color: colorsOf(context).primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 34,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.role.isImpostor
                              ? Icons.theater_comedy_rounded
                              : Icons.key_rounded,
                          size: 42,
                          color: colorsOf(context).onPrimary,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          widget.role.isImpostor
                              ? 'ERES EL IMPOSTOR'
                              : 'LA PALABRA ES',
                          style: TextStyle(
                            color: colorsOf(context).onPrimary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.role.isImpostor ? 'Disimula' : widget.word,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorsOf(context).onPrimary,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (widget.role.isImpostor &&
                            widget.hint.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colorsOf(
                                context,
                              ).onPrimary.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'PISTA · ${widget.hint}',
                              style: TextStyle(
                                color: colorsOf(context).onPrimary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        Text(
                          widget.role.isImpostor
                              ? 'Escucha bien y finge que sabes la palabra.'
                              : 'Memorízala. No la digas en voz alta.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorsOf(
                              context,
                            ).onPrimary.withValues(alpha: .78),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -2,
                right: -2,
                top: -2,
                bottom: -2,
                child: AnimatedContainer(
                  key: const ValueKey('reveal-cover'),
                  duration:
                      isDragging || MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  curve: ease,
                  transform: Matrix4.translationValues(0, dragY, 0),
                  decoration: BoxDecoration(
                    color: colorsOf(context).surface,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: colorsOf(context).outline,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .16),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.keyboard_double_arrow_up_rounded,
                        size: 48,
                        color: colorsOf(context).primary,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'DESLIZA Y MANTÉN',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dragY < -30
                            ? 'Suelta para volver a ocultar'
                            : 'La palabra está debajo',
                        style: TextStyle(
                          color: colorsOf(context).onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const Spacer(),
      if (hasViewed)
        PrimaryButton(
          label: widget.index == widget.total
              ? 'Empezar la ronda'
              : 'Pasar al siguiente',
          icon: Icons.arrow_forward_rounded,
          onTap: widget.onNext,
        )
      else
        const SizedBox(height: 58),
    ],
  );
}

class DiscussionScreen extends StatefulWidget {
  const DiscussionScreen({
    required this.durationSeconds,
    this.round = 1,
    this.totalRounds = 0,
    required this.onReveal,
    super.key,
  });
  final int durationSeconds;
  final int round, totalRounds;
  final VoidCallback onReveal;
  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  late int seconds;
  Timer? timer;
  bool running = false;
  @override
  void initState() {
    super.initState();
    seconds = widget.durationSeconds;
  }

  void toggle() {
    setState(() => running = !running);
    timer?.cancel();
    if (running) {
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (seconds > 0) seconds--;
        if (seconds == 0) {
          timer?.cancel();
          setState(() => running = false);
          AppAudio.play(AppSound.timerEnd);
        } else {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time =
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    return PageColumn(
      children: [
        const Align(alignment: Alignment.centerLeft, child: Brand()),
        const Spacer(),
        const Text(
          'Hora de sospechar',
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          widget.totalRounds == 0
              ? 'Ronda ${widget.round}'
              : 'Ronda ${widget.round} de ${widget.totalRounds}',
          style: TextStyle(
            color: colorsOf(context).primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Por turnos, da una pista sin decir la palabra.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorsOf(context).onSurfaceVariant,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 34),
        SizedBox(
          width: 224,
          height: 224,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: seconds / widget.durationSeconds,
                  strokeWidth: 9,
                  backgroundColor: colorsOf(context).surface,
                  color: colorsOf(context).primary,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'DEBATE',
                    style: TextStyle(
                      color: colorsOf(context).onSurfaceVariant,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        PrimaryButton(
          label: running ? 'Pausar tiempo' : 'Iniciar tiempo',
          icon: running ? Icons.pause_rounded : Icons.play_arrow_rounded,
          onTap: toggle,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: widget.onReveal,
            icon: const Icon(Icons.how_to_vote_rounded, size: 19),
            label: const Text('Revelar impostor'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorsOf(context).onSurfaceVariant,
              side: BorderSide(color: colorsOf(context).outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    required this.word,
    required this.impostors,
    required this.onAgain,
    required this.onHome,
    this.round = 1,
    this.totalRounds = 0,
    super.key,
  });
  final String word;
  final List<String> impostors;
  final int round, totalRounds;
  final VoidCallback onAgain, onHome;
  @override
  Widget build(BuildContext context) => PageColumn(
    children: [
      const Spacer(),
      Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          color: colorsOf(context).secondary,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Icon(
          Icons.person_search_rounded,
          color: colorsOf(context).onSecondary,
          size: 42,
        ),
      ),
      const SizedBox(height: 26),
      Text(
        'El impostor era…',
        style: TextStyle(
          color: colorsOf(context).onSurfaceVariant,
          fontSize: 17,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        totalRounds == 0 ? 'Ronda $round' : 'Ronda $round de $totalRounds',
        style: TextStyle(
          color: colorsOf(context).primary,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        impostors.join(' y '),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 46,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
        ),
      ),
      const SizedBox(height: 28),
      Pill(
        icon: Icons.key_rounded,
        label: 'La palabra era $word',
        color: colorsOf(context).primary,
      ),
      const Spacer(),
      PrimaryButton(
        label: totalRounds != 0 && round >= totalRounds
            ? 'Nueva partida'
            : 'Siguiente ronda',
        icon: Icons.refresh_rounded,
        onTap: onAgain,
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: onHome,
        child: Text(
          'Volver al inicio',
          style: TextStyle(color: colorsOf(context).onSurfaceVariant),
        ),
      ),
    ],
  );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.lightMode,
    required this.soundEnabled,
    required this.hapticsEnabled,
    required this.animationsEnabled,
    required this.textScale,
    required this.onBack,
    required this.onToggleTheme,
    required this.onSoundChanged,
    required this.onHapticsChanged,
    required this.onAnimationsChanged,
    required this.onTextScaleChanged,
    super.key,
  });

  final bool lightMode, soundEnabled, hapticsEnabled, animationsEnabled;
  final double textScale;
  final VoidCallback onBack, onToggleTheme;
  final ValueChanged<bool> onSoundChanged,
      onHapticsChanged,
      onAnimationsChanged;
  final ValueChanged<double> onTextScaleChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Header(title: 'Ajustes', onBack: onBack),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          children: [
            _SettingsCard(
              children: [
                _SettingsSwitch(
                  icon: lightMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  title: 'Tema claro',
                  subtitle: 'Cambia la apariencia de la aplicación',
                  value: lightMode,
                  onChanged: (_) => onToggleTheme(),
                ),
                _SettingsSwitch(
                  icon: Icons.volume_up_rounded,
                  title: 'Sonidos',
                  subtitle: 'Confirma botones y revelaciones',
                  value: soundEnabled,
                  onChanged: onSoundChanged,
                ),
                _SettingsSwitch(
                  icon: Icons.vibration_rounded,
                  title: 'Vibración',
                  subtitle: 'Respuesta táctil al interactuar',
                  value: hapticsEnabled,
                  onChanged: onHapticsChanged,
                ),
                _SettingsSwitch(
                  icon: Icons.animation_rounded,
                  title: 'Animaciones',
                  subtitle: 'Movimientos y transiciones suaves',
                  value: animationsEnabled,
                  onChanged: onAnimationsChanged,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const SectionTitle('TAMAÑO DEL TEXTO', 'Accesibilidad'),
            const SizedBox(height: 12),
            _SettingsCard(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  child: Row(
                    children: [
                      const Text('A', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Slider(
                          value: textScale,
                          min: .9,
                          max: 1.2,
                          divisions: 3,
                          label: '${(textScale * 100).round()} %',
                          onChanged: onTextScaleChanged,
                        ),
                      ),
                      const Text(
                        'A',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Material(
    color: colorsOf(context).surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: colorsOf(context).outline),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    secondary: Icon(icon, color: colorsOf(context).primary),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: Text(
      subtitle,
      style: TextStyle(color: colorsOf(context).onSurfaceVariant),
    ),
    value: value,
    activeTrackColor: colorsOf(context).primary,
    onChanged: (next) {
      AppAudio.feedback(AppSound.toggle);
      onChanged(next);
    },
  );
}

class PageColumn extends StatelessWidget {
  const PageColumn({required this.children, super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
    child: Column(children: children),
  );
}

class Brand extends StatelessWidget {
  const Brand({this.iconSize = 24, super.key});
  final double iconSize;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.theater_comedy_rounded,
        color: colorsOf(context).primary,
        size: iconSize,
      ),
      const SizedBox(width: 9),
      const Text(
        'IMPOSTOR',
        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.8),
      ),
    ],
  );
}

class Header extends StatelessWidget {
  const Header({required this.title, required this.onBack, super.key});
  final String title;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 12, 24, 10),
    child: Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, this.caption, {super.key});
  final String title, caption;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Flexible(
        child: Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 12,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            caption,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorsOf(context).onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
      ),
    ],
  );
}

class Pill extends StatelessWidget {
  const Pill({required this.icon, required this.label, this.color, super.key});
  final IconData icon;
  final String label;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? colorsOf(context).onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: resolvedColor.withValues(alpha: .25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: resolvedColor),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: resolvedColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
    super.key,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final background = color ?? colorsOf(context).primary;
    final foreground = color == null
        ? colorsOf(context).onPrimary
        : colorsOf(context).onSecondary;
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton(
        onPressed: onTap == null
            ? null
            : () {
                AppAudio.feedback(AppSound.confirm);
                onTap!();
              },
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: colorsOf(context).surface,
          disabledForegroundColor: colorsOf(context).onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label),
            const SizedBox(width: 10),
            Icon(icon, size: 20),
          ],
        ),
      ),
    );
  }
}

class SquareButton extends StatelessWidget {
  const SquareButton({required this.icon, required this.onTap, super.key});
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 56,
    height: 56,
    child: FilledButton(
      onPressed: onTap == null
          ? null
          : () {
              AppAudio.feedback(AppSound.tap);
              onTap!();
            },
      style: FilledButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: colorsOf(context).primary,
        foregroundColor: colorsOf(context).onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Icon(icon),
    ),
  );
}

class SelectTile extends StatelessWidget {
  const SelectTile({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () {
      AppAudio.feedback(AppSound.select);
      onTap();
    },
    borderRadius: BorderRadius.circular(12),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: ease,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? colorsOf(context).primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: selected
              ? colorsOf(context).onPrimary
              : colorsOf(context).onSurfaceVariant,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

InputDecoration inputDecoration(BuildContext context, String hint) =>
    InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colorsOf(context).onSurfaceVariant),
      filled: true,
      fillColor: colorsOf(context).surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorsOf(context).outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorsOf(context).primary, width: 1.5),
      ),
    );
