import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/level.dart';
import '../../../data/models/world_map.dart';
import '../../tracks/providers/tracks_providers.dart';
import '../engine/activity_session.dart';
import '../engine/coming_soon_activity.dart';

final worldMapProvider = FutureProvider<WorldMap>(
  (ref) => ref.watch(contentRepositoryProvider).loadWorldMap(),
);

final mapPinLevelProvider = FutureProvider.family<MapPinLevel, String>(
  (ref, levelId) => ref.watch(contentRepositoryProvider).loadMapPinLevel(levelId),
);

/// Drag the pin onto the right continent or country on the world map.
class MapPinsActivity extends ConsumerWidget {
  const MapPinsActivity({super.key, required this.level, required this.session});

  final Level level;
  final ActivitySession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final world = ref.watch(worldMapProvider);
    final data = ref.watch(mapPinLevelProvider(level.id));

    // Missing content: keep the level playable.
    if (world.hasError || data.hasError) {
      return ComingSoonActivity(level: level, session: session);
    }
    final w = world.valueOrNull;
    final m = data.valueOrNull;
    if (w == null || m == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (m.questions.isEmpty) {
      return ComingSoonActivity(level: level, session: session);
    }
    return _MapPinsBody(world: w, data: m, session: session);
  }
}

const _continentColors = <String, Color>{
  'africa': Color(0xFFFFD670),
  'asia': Color(0xFFFF9AA2),
  'europe': Color(0xFFB9A8FF),
  'north_america': Color(0xFF7ED6A5),
  'south_america': Color(0xFFFFB38A),
  'oceania': Color(0xFF9BE0C8),
};

class _Region {
  const _Region(this.country, this.path);

  final MapCountry country;
  final Path path;
}

class _MapPinsBody extends StatefulWidget {
  const _MapPinsBody({
    required this.world,
    required this.data,
    required this.session,
  });

  final WorldMap world;
  final MapPinLevel data;
  final ActivitySession session;

  @override
  State<_MapPinsBody> createState() => _MapPinsBodyState();
}

class _MapPinsBodyState extends State<_MapPinsBody> {
  // The pin graphic is _pinW x _pinH; its tip is the bottom-centre.
  // While dragging, the pin floats _lift pixels above the finger.
  static const _pinW = 48.0;
  static const _pinH = 52.0;
  static const _lift = 28.0;

  final _mapKey = GlobalKey();
  late final List<MapPinQuestion> _questions;
  int _step = 0;
  bool _busy = false;
  String? _solved; // target id that was just found
  Offset? _pin; // where the correct pin landed
  String? _caption;
  int _captionToken = 0;

  // Map geometry, rebuilt only when the map size changes.
  double _geoWidth = 0;
  List<_Region> _regions = const [];
  Map<String, Path> _targets = {};

  bool get _countryMode => widget.data.isCountryMode;

  @override
  void initState() {
    super.initState();
    _questions = [...widget.data.questions]..shuffle(Random());
    widget.session.begin(_questions.length, hints: _questions.first.hints);
  }

  void _ensureGeometry(double width) {
    if ((width - _geoWidth).abs() < 0.5) return;
    _geoWidth = width;

    final regions = <_Region>[];
    final targets = <String, Path>{};
    for (final c in widget.world.countries) {
      final path = Path();
      for (final poly in c.polys) {
        path.addPolygon(
          [for (final p in poly) Offset(p.dx * width, p.dy * width)],
          true,
        );
      }
      regions.add(_Region(c, path));
      final key = _countryMode ? c.id : c.continent;
      targets.putIfAbsent(key, () => Path()).addPath(path, Offset.zero);
    }
    _regions = regions;
    _targets = targets;
  }

  /// True if the pin tip is on the target, with a small forgiving margin
  /// (small countries are only a few pixels wide).
  bool _isHit(String target, Offset tip) {
    final path = _targets[target];
    if (path == null) return false;
    if (path.contains(tip)) return true;
    final r = _countryMode ? 12.0 : 6.0;
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4;
      if (path.contains(tip + Offset(cos(a) * r, sin(a) * r))) return true;
    }
    return false;
  }

  String? _nameAt(Offset tip) {
    for (final r in _regions) {
      if (r.path.contains(tip)) {
        return _countryMode
            ? r.country.name
            : continentNames[r.country.continent];
      }
    }
    return null;
  }

  void _showCaption(String text) {
    final token = ++_captionToken;
    setState(() => _caption = text);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && token == _captionToken) setState(() => _caption = null);
    });
  }

  void _onDrop(Offset feedbackTopLeft) {
    if (_busy) return;
    final box = _mapKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final tip =
        box.globalToLocal(feedbackTopLeft + const Offset(_pinW / 2, _pinH));
    final size = box.size;
    if (tip.dx < 0 || tip.dy < 0 || tip.dx > size.width || tip.dy > size.height) {
      _showCaption('Drop the pin on the map!');
      return;
    }

    final q = _questions[_step];
    if (_isHit(q.target, tip)) {
      _correct(q, tip);
    } else {
      widget.session.wrong();
      final name = _nameAt(tip);
      _showCaption(
        name == null ? "That's the ocean. Try again!" : "That's $name. Try again!",
      );
    }
  }

  Future<void> _correct(MapPinQuestion q, Offset tip) async {
    setState(() {
      _busy = true;
      _solved = q.target;
      _pin = tip;
      _caption = null;
    });

    final isLast = _step == _questions.length - 1;
    widget.session.correct(
      nextHints: isLast ? const [] : _questions[_step + 1].hints,
    );
    if (isLast) return;

    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() {
      _step++;
      _solved = null;
      _pin = null;
      _busy = false;
    });
  }

  static Offset _pinAnchor(
    Draggable<Object> draggable,
    BuildContext context,
    Offset position,
  ) =>
      const Offset(_pinW / 2, _pinH + _lift);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final q = _questions[_step];

    return Padding(
      padding: const EdgeInsets.all(AppSizes.pad),
      child: Column(
        children: [
          Text(q.prompt, style: text.headlineSmall, textAlign: TextAlign.center),
          SizedBox(
            height: 32,
            child: Center(
              child: Text(_caption ?? '', style: text.bodyMedium),
            ),
          ),
          Expanded(
            child: DragTarget<int>(
              onWillAcceptWithDetails: (_) => !_busy,
              onAcceptWithDetails: (details) => _onDrop(details.offset),
              builder: (context, candidateData, rejectedData) {
                return LayoutBuilder(
                  builder: (context, c) {
                    final aspect = widget.world.aspect;
                    final width = min(c.maxWidth, c.maxHeight / aspect);
                    final height = width * aspect;
                    _ensureGeometry(width);

                    return Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.radius),
                        child: SizedBox(
                          key: _mapKey,
                          width: width,
                          height: height,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _MapPainter(
                                    regions: _regions,
                                    countryMode: _countryMode,
                                    solved: _solved,
                                  ),
                                ),
                              ),
                              if (_pin != null)
                                Positioned(
                                  left: _pin!.dx - _pinW / 2,
                                  top: _pin!.dy - _pinH,
                                  child: const _PinGraphic(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSizes.pad),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Draggable<int>(
                data: 0,
                dragAnchorStrategy: _pinAnchor,
                feedback: const _PinGraphic(),
                childWhenDragging: const Opacity(
                  opacity: 0.3,
                  child: _PinChip(),
                ),
                child: const _PinChip(),
              ),
              const SizedBox(width: 16),
              Text('Drag the pin onto the map', style: text.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _PinGraphic extends StatelessWidget {
  const _PinGraphic();

  @override
  Widget build(BuildContext context) {
    return const Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: _MapPinsBodyState._pinW,
        height: _MapPinsBodyState._pinH,
        child: Center(
          child: Text('📍', style: TextStyle(fontSize: 40, height: 1)),
        ),
      ),
    );
  }
}

class _PinChip extends StatelessWidget {
  const _PinChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.coral, width: 3),
      ),
      child: const Text('📍', style: TextStyle(fontSize: 32)),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.regions,
    required this.countryMode,
    required this.solved,
  });

  final List<_Region> regions;
  final bool countryMode;
  final String? solved;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFCFEFFF));

    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = countryMode ? 0.8 : 0.7;

    for (final r in regions) {
      final c = r.country;
      final isSolved = solved != null &&
          (countryMode ? c.id == solved : c.continent == solved);
      final base = _continentColors[c.continent] ?? const Color(0xFFDDDDDD);
      final color = isSolved ? AppColors.success : base;

      fill.color = color;
      canvas.drawPath(r.path, fill);
      // Country mode: white borders. Continent mode: same-colour edge to hide seams.
      stroke.color = countryMode ? Colors.white : color;
      canvas.drawPath(r.path, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.regions != regions ||
      old.countryMode != countryMode ||
      old.solved != solved;
}
