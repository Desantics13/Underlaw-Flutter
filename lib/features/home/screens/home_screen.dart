import 'dart:async';

import 'package:flutter/material.dart';
import 'package:underlaw_flutter/features/home/models/lanzamiento_activo.dart';
import 'package:underlaw_flutter/core/api/api_service.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/features/home/widgets/drop_card.dart';
import 'package:underlaw_flutter/features/home/widgets/home_hero.dart';
import 'package:underlaw_flutter/features/home/widgets/faq_section.dart';
import 'package:underlaw_flutter/features/home/widgets/historia_section.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onVerColeccion;

  const HomeScreen({super.key, required this.onVerColeccion});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LanzamientoActivo? _lanzamiento;
  DateTime? _serverNow;
  Duration? _restante;
  bool _cargando = true;
  String? _error;
  Timer? _ticker;
  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);
  final _dropKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(
      () => _offset.value = _scroll.hasClients
          ? _scroll.offset.clamp(0.0, double.infinity)
          : 0,
    );
    _cargarLanzamiento();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  Future<void> _cargarLanzamiento() async {
    if (!_cargando || _error != null) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }
    try {
      final data = await ApiService.getLanzamientoHome();
      final lanzamientoJson = data['lanzamiento'] as Map<String, dynamic>?;
      final serverNowRaw = data['server_now']?.toString();

      setState(() {
        _lanzamiento = lanzamientoJson != null
            ? LanzamientoActivo.fromJson(lanzamientoJson)
            : null;
        _serverNow = serverNowRaw != null
            ? DateTime.parse(serverNowRaw).toUtc()
            : DateTime.now().toUtc();
        _cargando = false;
      });

      _ticker?.cancel();
      if (_lanzamiento != null && _lanzamiento!.estaProgramado) {
        // La hora del SERVIDOR es la fuente de verdad (igual que en la web);
        // el reloj local del dispositivo solo se usa para avanzar el tick.
        final desfaseServidor = _serverNow!.difference(DateTime.now().toUtc());
        _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
          final ahoraServidor = DateTime.now().toUtc().add(desfaseServidor);
          setState(() {
            _restante = _lanzamiento!.fechaLanzamiento.difference(
              ahoraServidor,
            );
          });
        });
      }
    } catch (e) {
      setState(() {
        _error = 'No se pudo cargar el lanzamiento: $e';
        _cargando = false;
      });
    }
  }

  // "PRÓXIMO DROP": desplaza suave hasta la tarjeta del drop (offset −60).
  void _irAlDrop() {
    final ctx = _dropKey.currentContext;
    final scrollCtx = _scroll.hasClients
        ? _scroll.position.context.storageContext
        : null;
    if (ctx == null || scrollCtx == null) return;
    final box = ctx.findRenderObject() as RenderBox;
    final scrollBox = scrollCtx.findRenderObject() as RenderBox;
    final dy = box.localToGlobal(Offset.zero, ancestor: scrollBox).dy;
    final destino = (_scroll.offset + dy - 60).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    _scroll.animateTo(
      destino,
      duration: const Duration(milliseconds: 600),
      curve: AppMotion.curve,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return SingleChildScrollView(
          controller: _scroll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeHero(
                height: c.maxHeight,
                offset: _offset,
                onVerColeccion: widget.onVerColeccion,
                onProximoDrop: _irAlDrop,
              ),
              Padding(
                key: _dropKey,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: DropCard(
                  cargando: _cargando,
                  error: _error,
                  lanzamiento: _lanzamiento,
                  restante: _restante,
                  onVerColeccion: widget.onVerColeccion,
                  onReintentar: _cargarLanzamiento,
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 40, 20, 0),
                child: HistoriaSection(),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 48, 20, 0),
                child: FaqSection(),
              ),
              const SizedBox(height: 140),
            ],
          ),
        );
      },
    );
  }
}
