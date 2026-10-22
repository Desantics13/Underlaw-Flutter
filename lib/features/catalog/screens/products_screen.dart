import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:underlaw_flutter/core/api/api_service.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';
import 'package:underlaw_flutter/core/widgets/ul_chip.dart';
import 'package:underlaw_flutter/features/catalog/models/producto.dart';
import 'package:underlaw_flutter/features/catalog/models/seccion.dart';
import 'package:underlaw_flutter/features/catalog/widgets/catalog_states.dart';
import 'package:underlaw_flutter/features/catalog/widgets/collection_header.dart';
import 'package:underlaw_flutter/features/catalog/widgets/product_card.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Producto> _productos = [];
  List<Seccion> _secciones = [];
  int? _seccionActivaId; // null = "Todo"
  bool _cargando = true;
  bool _hayError = false;
  int _gridKey =
      0; // cambia al elegir sección para repetir la entrada escalonada

  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(
      () =>
          _offset.value = _scroll.hasClients ? math.max(0, _scroll.offset) : 0,
    );
    _cargarDatos();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _hayError = false;
    });
    try {
      final results = await Future.wait([
        ApiService.getCatalogo(),
        ApiService.getSecciones(),
      ]);
      if (!mounted) return;
      setState(() {
        _productos = results[0]
            .whereType<Map<String, dynamic>>()
            .map(Producto.fromJson)
            .toList();
        _secciones =
            results[1]
                .whereType<Map<String, dynamic>>()
                .map(Seccion.fromJson)
                .toList()
              ..sort((a, b) => a.orden.compareTo(b.orden));
        _cargando = false;
        _gridKey++;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hayError = true;
        _cargando = false;
      });
    }
  }

  List<Producto> get _productosFiltrados {
    if (_seccionActivaId == null) return _productos;
    return _productos.where((p) => p.seccionId == _seccionActivaId).toList();
  }

  // Solo secciones que tienen al menos un producto activo, igual que en la web.
  List<Seccion> get _seccionesConProductos {
    final ids = _productos.map((p) => p.seccionId).whereType<int>().toSet();
    return _secciones.where((s) => ids.contains(s.id)).toList();
  }

  void _elegirSeccion(int? id) {
    if (_seccionActivaId == id) return;
    setState(() {
      _seccionActivaId = id;
      _gridKey++;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Widget _buildChips() {
    return SizedBox(
      height: CollectionHeader.chipsHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        children: [
          UlChip(
            label: 'Todo',
            count: _productos.length,
            selected: _seccionActivaId == null,
            onTap: () => _elegirSeccion(null),
          ),
          for (final s in _seccionesConProductos) ...[
            const SizedBox(width: 8),
            UlChip(
              label: s.nombre,
              count: _productos.where((p) => p.seccionId == s.id).length,
              selected: _seccionActivaId == s.id,
              onTap: () => _elegirSeccion(s.id),
            ),
          ],
        ],
      ),
    );
  }

  // Entrada escalonada: 420 ms, de y+16 y opacidad 0, retraso de 70 ms × índice.
  Widget _entrada(Widget child, int index) {
    if (index >= 8) return child;
    return child
        .animate(key: ValueKey('$_gridKey-$index'))
        .fadeIn(
          duration: 420.ms,
          delay: (70 * index).ms,
          curve: AppMotion.curve,
        )
        .moveY(
          begin: 16,
          end: 0,
          duration: 420.ms,
          delay: (70 * index).ms,
          curve: AppMotion.curve,
        );
  }

  Widget _buildGrid(double topPad) {
    final lista = _productosFiltrados;
    if (lista.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: topPad + 48),
        child: Align(
          alignment: Alignment.topCenter,
          child: Text(
            'No hay productos en esta sección.',
            style: GoogleFonts.jost(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    }
    final filas = (lista.length + 1) ~/ 2;
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      color: AppColors.gold,
      backgroundColor: AppColors.bgSecondary,
      edgeOffset: topPad,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, topPad, 20, 140),
            sliver: SliverList.builder(
              itemCount: filas,
              itemBuilder: (context, fila) {
                final i = fila * 2;
                return Padding(
                  padding: EdgeInsets.only(bottom: fila == filas - 1 ? 0 : 28),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _entrada(ProductCard(producto: lista[i]), i),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: i + 1 < lista.length
                            ? _entrada(
                                ProductCard(producto: lista[i + 1]),
                                i + 1,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // En el navegador no hay barra de estado: mínimo 20 para no pegar el título.
    final topInset = math.max(MediaQuery.paddingOf(context).top, 20.0);
    final headerMax = CollectionHeader.maxHeight(topInset);
    final topPad = headerMax + 8;

    final Widget cuerpo;
    if (_cargando) {
      cuerpo = SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, topPad, 20, 0),
        child: const CatalogSkeleton(),
      );
    } else if (_hayError) {
      cuerpo = Padding(
        padding: EdgeInsets.only(top: topPad, bottom: 100),
        child: Center(child: CatalogError(onRetry: _cargarDatos)),
      );
    } else {
      cuerpo = _buildGrid(topPad);
    }

    return Stack(
      children: [
        Positioned.fill(child: cuerpo),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: CollectionHeader(
            offset: _offset,
            topInset: topInset,
            chips: _buildChips(),
          ),
        ),
      ],
    );
  }
}
