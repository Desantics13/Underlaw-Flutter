import 'dart:async';
import 'package:flutter/material.dart';
import '../models/lanzamiento_activo.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/faq_section.dart';
import '../widgets/historia_section.dart';

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

  @override
  void initState() {
    super.initState();
    _cargarLanzamiento();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _cargarLanzamiento() async {
    try {
      final data = await ApiService.getLanzamientoHome();
      final lanzamientoJson = data['lanzamiento'] as Map<String, dynamic>?;
      final serverNowRaw = data['server_now']?.toString();

      setState(() {
        _lanzamiento = lanzamientoJson != null ? LanzamientoActivo.fromJson(lanzamientoJson) : null;
        _serverNow = serverNowRaw != null ? DateTime.parse(serverNowRaw).toUtc() : DateTime.now().toUtc();
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
            _restante = _lanzamiento!.fechaLanzamiento.difference(ahoraServidor);
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHero(context),
          _buildLanzamiento(context),
          const HistoriaSection(),
          const FaqSection(),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text('LEGACY OF LUXURY · EST. MMXXVI', style: kickerStyle(), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Text('UNDERLAW', style: serifTitle(size: 64), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(
            'Under the rules, only yours.',
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.bgPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: const RoundedRectangleBorder(),
                ),
                onPressed: widget.onVerColeccion,
                child: const Text('VER COLECCIÓN'),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: const RoundedRectangleBorder(),
                ),
                onPressed: () {
                  ScrollController();
                },
                child: const Text('PRÓXIMO DROP'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanzamiento(BuildContext context) {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(_error!, style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
      );
    }
    if (_lanzamiento == null) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Text(
          'No hay ningún lanzamiento activo ahora mismo.',
          style: TextStyle(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      );
    }

    final l = _lanzamiento!;
    return Container(
      color: AppColors.bgSecondary,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.estaProgramado ? '${l.nombreLanzamiento} · PROGRAMADO' : '${l.nombreLanzamiento} · YA DISPONIBLE',
            style: kickerStyle(),
          ),
          const SizedBox(height: 12),
          Text(l.nombreProducto, style: serifTitle(size: 32)),
          const SizedBox(height: 8),
          Text(formatCOP(l.precio), style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 20),
          if (l.estaProgramado && _restante != null) _buildCronometro(_restante!),
        ],
      ),
    );
  }

  Widget _buildCronometro(Duration restante) {
    final total = restante.isNegative ? Duration.zero : restante;
    final dias = total.inDays;
    final horas = total.inHours % 24;
    final minutos = total.inMinutes % 60;
    final segundos = total.inSeconds % 60;

    Widget celda(String valor, String label) => Column(
          children: [
            Text(
              valor.padLeft(2, '0'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: AppColors.textPrimary,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        celda('$dias', 'DÍAS'),
        celda('$horas', 'HORAS'),
        celda('$minutos', 'MIN'),
        celda('$segundos', 'SEG'),
      ],
    );
  }
}
