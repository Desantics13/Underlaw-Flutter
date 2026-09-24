import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/producto.dart';
import '../models/seccion.dart';
import '../services/api_service.dart';
import '../state/cart_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

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
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getCatalogo(),
        ApiService.getSecciones(),
      ]);
      final productosJson = results[0];
      final seccionesJson = results[1];

      setState(() {
        _productos = productosJson.whereType<Map<String, dynamic>>().map(Producto.fromJson).toList();
        _secciones = seccionesJson.whereType<Map<String, dynamic>>().map(Seccion.fromJson).toList()
          ..sort((a, b) => a.orden.compareTo(b.orden));
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo cargar la colección: $e';
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
    final idsConProducto = _productos.map((p) => p.seccionId).whereType<int>().toSet();
    return _secciones.where((s) => idsConProducto.contains(s.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _cargarDatos, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      color: AppColors.gold,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text('COLECCIÓN', style: serifTitle(size: 36)),
            ),
          ),
          if (_seccionesConProductos.isNotEmpty)
            SliverToBoxAdapter(child: _buildFiltros()),
          _productosFiltrados.isEmpty
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: Text('No hay productos en esta sección.', style: TextStyle(color: AppColors.textMuted)),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.68,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ProductCard(producto: _productosFiltrados[index]),
                      childCount: _productosFiltrados.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FiltroChip(label: 'Todo', selected: _seccionActivaId == null, onTap: () => setState(() => _seccionActivaId = null)),
          for (final s in _seccionesConProductos)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _FiltroChip(
                label: s.nombre,
                selected: _seccionActivaId == s.id,
                onTap: () => setState(() => _seccionActivaId = s.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FiltroChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? AppColors.gold : AppColors.border),
          color: selected ? AppColors.gold.withValues(alpha: 0.12) : Colors.transparent,
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            color: selected ? AppColors.gold : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Producto producto;

  const _ProductCard({required this.producto});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _abrirDetalle(context, producto),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: AppColors.bgSecondary,
              child: producto.imagen != null
                  ? Image.network(
                      producto.imagen!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported, color: AppColors.textMuted),
                    )
                  : const Icon(Icons.checkroom, color: AppColors.textMuted, size: 40),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            producto.nombreProducto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(formatCOP(producto.precio), style: const TextStyle(color: AppColors.gold, fontSize: 13)),
        ],
      ),
    );
  }

  void _abrirDetalle(BuildContext context, Producto p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      isScrollControlled: true,
      builder: (context) => _ProductDetailSheet(producto: p),
    );
  }
}

class _ProductDetailSheet extends StatefulWidget {
  final Producto producto;

  const _ProductDetailSheet({required this.producto});

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  String? _tallaSeleccionada;
  int _cantidad = 1;

  @override
  void initState() {
    super.initState();
    final disponibles = widget.producto.tallas.where((t) => t.disponible);
    if (disponibles.isNotEmpty) _tallaSeleccionada = disponibles.first.talla;
  }

  int get _maxCompra {
    if (widget.producto.tallas.isEmpty) return 10;
    final t = widget.producto.tallas.where((x) => x.talla == _tallaSeleccionada);
    return t.isEmpty ? 10 : t.first.maxCompra;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final requiereTalla = p.tallas.isNotEmpty;
    final puedeComprar = !requiereTalla || _tallaSeleccionada != null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.nombreProducto, style: serifTitle(size: 26)),
          const SizedBox(height: 8),
          Text(formatCOP(p.precio), style: const TextStyle(color: AppColors.gold, fontSize: 16)),
          if (p.descripcion != null && p.descripcion!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(p.descripcion!, style: const TextStyle(color: AppColors.textSecondary)),
          ],
          if (requiereTalla) ...[
            const SizedBox(height: 16),
            const Text('TALLA', style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: p.tallas.map((t) {
                final seleccionada = t.talla == _tallaSeleccionada;
                return ChoiceChip(
                  label: Text(t.talla),
                  selected: seleccionada,
                  onSelected: t.disponible
                      ? (_) => setState(() {
                            _tallaSeleccionada = t.talla;
                            _cantidad = 1;
                          })
                      : null,
                  disabledColor: AppColors.bgPrimary.withValues(alpha: 0.3),
                  selectedColor: AppColors.gold,
                  backgroundColor: AppColors.bgPrimary,
                  labelStyle: TextStyle(
                    color: seleccionada
                        ? AppColors.bgPrimary
                        : (t.disponible ? AppColors.textPrimary : AppColors.textMuted),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('CANTIDAD', style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.2)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary),
                onPressed: _cantidad > 1 ? () => setState(() => _cantidad--) : null,
              ),
              Text('$_cantidad', style: const TextStyle(color: AppColors.textPrimary)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.textSecondary),
                onPressed: _cantidad < _maxCompra ? () => setState(() => _cantidad++) : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: AppColors.bgPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const RoundedRectangleBorder(),
              ),
              onPressed: puedeComprar
                  ? () {
                      context.read<CartModel>().agregar(p, talla: _tallaSeleccionada, cantidad: _cantidad);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${p.nombreProducto} agregado al carrito.')),
                      );
                    }
                  : null,
              child: const Text('AGREGAR AL CARRITO'),
            ),
          ),
        ],
      ),
    );
  }
}
