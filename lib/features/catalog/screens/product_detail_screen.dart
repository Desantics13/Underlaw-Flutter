import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:underlaw_flutter/app/app_nav.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/core/utils/format.dart';
import 'package:underlaw_flutter/core/widgets/ul_button.dart';
import 'package:underlaw_flutter/core/widgets/ul_stepper.dart';
import 'package:underlaw_flutter/core/widgets/ul_toast.dart';
import 'package:underlaw_flutter/features/cart/state/cart_model.dart';
import 'package:underlaw_flutter/features/catalog/models/producto.dart';
import 'package:underlaw_flutter/features/catalog/widgets/product_image.dart';

enum _Agregar { idle, cargando, agregado }

// Detalle de producto como ruta propia (no modal). La foto llega con una
// transición Hero desde la tarjeta; el panel entra en 400 ms (+80 ms).
class ProductDetailScreen extends StatefulWidget {
  final Producto producto;

  const ProductDetailScreen({super.key, required this.producto});

  static String heroTag(Producto p) => 'producto-${p.id}';

  /// Abre el detalle con transición de 380 ms.
  static Future<void> abrir(BuildContext context, Producto p) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, _, _) => ProductDetailScreen(producto: p),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: AppMotion.curve),
          child: child,
        ),
      ),
    );
  }

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _talla;
  int _cantidad = 1;
  String? _tallaAgotada; // talla agotada que el usuario tocó (aviso inline)
  int _galeriaIdx = 0;
  _Agregar _estado = _Agregar.idle;

  Producto get _p => widget.producto;
  bool get _requiereTalla => _p.tallas.isNotEmpty;
  bool get _todoAgotado =>
      _requiereTalla && _p.tallas.every((t) => !t.disponible);

  @override
  void initState() {
    super.initState();
    final disponibles = _p.tallas.where((t) => t.disponible);
    if (disponibles.isNotEmpty) _talla = disponibles.first.talla;
  }

  int get _maxCompra {
    if (_p.tallas.isEmpty) return 10;
    final t = _p.tallas.where((x) => x.talla == _talla);
    return t.isEmpty ? 10 : t.first.maxCompra;
  }

  void _elegirTalla(String talla, bool disponible) {
    if (!disponible) {
      HapticFeedback.vibrate();
      setState(() => _tallaAgotada = talla);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _talla = talla;
      _tallaAgotada = null;
      _cantidad = math.min(_cantidad, _maxCompra);
    });
  }

  void _incrementar() {
    if (_cantidad >= _maxCompra) {
      UlToast.show(
        context,
        'Máximo $_maxCompra por pedido',
        icon: Symbols.block,
        bottom: 118,
      );
      return;
    }
    setState(() => _cantidad++);
  }

  Future<void> _agregar() async {
    if (_estado != _Agregar.idle) return;
    HapticFeedback.mediumImpact();
    setState(() => _estado = _Agregar.cargando);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    context.read<CartModel>().agregar(_p, talla: _talla, cantidad: _cantidad);
    setState(() => _estado = _Agregar.agregado);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _estado = _Agregar.idle);
  }

  void _irAlCarrito() {
    shellTab.value = 2;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void _abrirDetalleCuidado() {
    final filas = (_p.detalle ?? '')
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.replaceFirst(RegExp(r'^[\s•\-–·*]+'), '').trim())
        .where((l) => l.isNotEmpty)
        .toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSecondary,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (_) =>
          _DetalleCuidadoSheet(nombre: _p.nombreProducto, filas: filas),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final alto = ancho * 5 / 4; // galería 4:5 (488 en 390)
    final topBtn = math.max(MediaQuery.paddingOf(context).top, 20.0) + 7;
    final cantidadCarrito = context.select<CartModel, int>(
      (c) => c.cantidadTotal,
    );
    final imagenes = _p.imagen != null ? [_p.imagen!] : <String?>[null];

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Stack(
              children: [
                SizedBox(
                  height: alto,
                  child: Stack(
                    children: [
                      PageView.builder(
                        itemCount: imagenes.length,
                        onPageChanged: (i) => setState(() => _galeriaIdx = i),
                        itemBuilder: (_, i) {
                          final foto = ProductImage(
                            url: imagenes[i],
                            stripe: 12,
                          );
                          return i == 0
                              ? Hero(
                                  tag: ProductDetailScreen.heroTag(_p),
                                  child: foto,
                                )
                              : foto;
                        },
                      ),
                      if (imagenes.length > 1)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 40,
                          child: IgnorePointer(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < imagenes.length; i++)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: AppMotion.curve,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    height: 3,
                                    width: i == _galeriaIdx ? 20 : 6,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      color: i == _galeriaIdx
                                          ? AppColors.textPrimary
                                          : AppColors.textPrimary.withValues(
                                              alpha: 0.35,
                                            ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    SizedBox(height: alto - 24), // el panel se superpone 24 px
                    _panel()
                        .animate()
                        .fadeIn(
                          duration: 400.ms,
                          delay: 80.ms,
                          curve: AppMotion.curve,
                        )
                        .moveY(
                          begin: 16,
                          end: 0,
                          duration: 400.ms,
                          delay: 80.ms,
                          curve: AppMotion.curve,
                        ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: topBtn,
            left: 16,
            child: _BotonFlotante(
              icon: Symbols.arrow_back,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            top: topBtn,
            right: 16,
            child: _BotonFlotante(
              icon: Symbols.shopping_bag,
              badge: cantidadCarrito,
              onTap: _irAlCarrito,
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _barraInferior()),
        ],
      ),
    );
  }

  Widget _panel() {
    final p = _p;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text((p.nombreLanzamiento ?? '').toUpperCase(), style: kickerStyle()),
          const SizedBox(height: 14),
          Text(
            p.nombreProducto.toUpperCase(),
            style: serifTitle(size: 34).copyWith(height: 1),
          ),
          const SizedBox(height: 12),
          Text(formatCOP(p.precio), style: precioStyle(size: 20)),
          if (p.descripcion != null && p.descripcion!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              p.descripcion!,
              style: GoogleFonts.jost(
                fontSize: 15,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (_requiereTalla) ...[
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('TALLA', style: labelStyle()),
                Text(
                  'Corte oversized unisex',
                  style: GoogleFonts.jost(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.15,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final t in p.tallas)
                  _ChipTalla(
                    talla: t.talla,
                    seleccionada: t.talla == _talla,
                    disponible: t.disponible,
                    onTap: () => _elegirTalla(t.talla, t.disponible),
                  ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: AppMotion.curve,
              alignment: Alignment.topCenter,
              child: _tallaAgotada == null
                  ? const SizedBox(width: double.infinity)
                  : Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(AppRadius.field),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Symbols.block,
                            size: 18,
                            weight: 300,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'La talla $_tallaAgotada se agotó en este drop. Los drops no se reponen.',
                              style: GoogleFonts.jost(
                                fontSize: 13,
                                height: 1.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CANTIDAD', style: labelStyle()),
                  const SizedBox(height: 6),
                  Text(
                    'Máximo $_maxCompra por pedido',
                    style: GoogleFonts.jost(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              UlStepper(
                value: _cantidad,
                onDecrement: _cantidad > 1
                    ? () => setState(() => _cantidad--)
                    : null,
                onIncrement: _incrementar,
                incrementDimmed: _cantidad >= _maxCompra,
              ),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _abrirDetalleCuidado,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detalle y cuidado',
                    style: GoogleFonts.jost(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Icon(
                    Symbols.expand_less,
                    size: 22,
                    weight: 300,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 150), // libra la barra fija inferior
        ],
      ),
    );
  }

  Widget _barraInferior() {
    final inset = MediaQuery.paddingOf(context).bottom;
    final agotado = _todoAgotado;
    final String etiqueta = agotado
        ? 'Agotado'
        : _estado == _Agregar.agregado
        ? 'Agregado'
        : 'Agregar al carrito';

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, math.max(34, inset + 14)),
          decoration: BoxDecoration(
            color: AppColors.bgPrimary.withValues(alpha: 0.9),
            border: const Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 92),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TOTAL',
                      style: GoogleFonts.jost(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCOPShort(_p.precio * _cantidad),
                      style: precioStyle(size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: UlButton(
                  label: etiqueta,
                  icon: _estado == _Agregar.agregado ? Symbols.check : null,
                  loading: _estado == _Agregar.cargando,
                  onPressed: agotado || (_requiereTalla && _talla == null)
                      ? null
                      : _agregar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Botón circular flotante sobre la foto: 44×44, fondo #060606 55% + blur 12.
class _BotonFlotante extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;

  const _BotonFlotante({
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgPrimary.withValues(alpha: 0.55),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    weight: 300,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            if (badge > 0)
              Positioned(
                top: -2,
                right: -2,
                child:
                    Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            '$badge',
                            style: GoogleFonts.jost(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.bgPrimary,
                            ),
                          ),
                        )
                        .animate(key: ValueKey(badge))
                        .scale(
                          begin: const Offset(0.4, 0.4),
                          end: const Offset(1, 1),
                          duration: 260.ms,
                          curve: AppMotion.curve,
                        ),
              ),
          ],
        ),
      ),
    );
  }
}

// Chip de talla: alto 56, radio 14. Seleccionada: borde gold + fondo gold 10%.
// Agotada: borde punteado, texto tachado y en textTertiary.
class _ChipTalla extends StatelessWidget {
  final String talla;
  final bool seleccionada;
  final bool disponible;
  final VoidCallback onTap;

  const _ChipTalla({
    required this.talla,
    required this.seleccionada,
    required this.disponible,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = seleccionada
        ? AppColors.gold
        : disponible
        ? AppColors.textPrimary
        : AppColors.textTertiary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: CustomPaint(
        foregroundPainter: disponible ? null : _DashedRRectPainter(),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: seleccionada ? AppColors.goldA10 : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: disponible
                ? Border.all(
                    color: seleccionada ? AppColors.gold : AppColors.border,
                  )
                : null,
          ),
          child: Text(
            talla,
            style: GoogleFonts.jost(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: color,
              decoration: disponible ? null : TextDecoration.lineThrough,
              decorationColor: AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadius.field),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 3, metric.length)),
          paint,
        );
        d += 6;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) => false;
}

// Bottom sheet "Detalle y cuidado": manija de 36×4, kicker con el nombre,
// título, filas separadas al 12% y CERRAR. Arrastrar hacia abajo lo cierra.
class _DetalleCuidadoSheet extends StatelessWidget {
  final String nombre;
  final List<String> filas;

  const _DetalleCuidadoSheet({required this.nombre, required this.filas});

  @override
  Widget build(BuildContext context) {
    final contenido = filas.isEmpty
        ? ['Sin información adicional por ahora.']
        : filas;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        math.max(40, MediaQuery.paddingOf(context).bottom + 16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 32,
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Text(
            nombre.toUpperCase(),
            style: kickerStyle(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Text(
            'DETALLE Y CUIDADO',
            style: serifTitle(size: 26).copyWith(height: 1),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < contenido.length; i++)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Text(
                contenido[i],
                style: GoogleFonts.jost(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Center(
            child: UlButton.tertiary(
              label: 'Cerrar',
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
