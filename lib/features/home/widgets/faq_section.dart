import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:underlaw_flutter/core/widgets/ul_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:underlaw_flutter/core/theme/app_theme.dart';

// Mismas preguntas que FAQS en Home.jsx.
const _faqs = [
  [
    '¿Cómo funcionan los drops?',
    'Cada drop se anuncia con fecha y hora exacta. Te inscribes con tu correo y te avisamos cuando abre la compra. Las unidades son limitadas y no se reponen.',
  ],
  [
    '¿Cuánto tarda el envío?',
    'Entre 2 y 5 días hábiles a ciudades principales de Colombia. Te enviamos la guía de rastreo por WhatsApp en cuanto el pedido sale.',
  ],
  [
    '¿Qué talla pido?',
    'El corte es oversized unisex. Si prefieres un calce más ajustado, pide una talla menos de la que usas normalmente.',
  ],
  [
    '¿Cómo cuido la prenda?',
    'Lavado a mano o en ciclo delicado con agua fría, al revés. Sin secadora ni blanqueador. Plancha por el lado interno para proteger el estampado.',
  ],
  [
    '¿Puedo cambiar o devolver?',
    'Sí. Tienes 5 días desde que recibes el pedido para solicitar cambio de talla, siempre que la prenda esté sin uso y con su etiqueta.',
  ],
  [
    '¿Qué medios de pago aceptan?',
    'Tarjeta débito y crédito, PSE y Nequi a través de Wompi. Recibes la factura en PDF por correo al confirmar el pago.',
  ],
];

const _whatsappUrl =
    'https://api.whatsapp.com/send/?phone=573103184180&text&type=phone_number&app_absent=0';

class FaqSection extends StatefulWidget {
  const FaqSection({super.key});

  @override
  State<FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends State<FaqSection> {
  int _abierta = 0; // solo una abierta a la vez; la primera por defecto

  void _toggle(int i) {
    HapticFeedback.lightImpact();
    setState(() => _abierta = _abierta == i ? -1 : i);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AYUDA', style: kickerStyle()),
        const SizedBox(height: 14),
        Text(
          'PREGUNTAS FRECUENTES',
          style: serifTitle(size: 30).copyWith(height: 1),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < _faqs.length; i++) ...[
          _FaqItem(
            pregunta: _faqs[i][0],
            respuesta: _faqs[i][1],
            abierta: _abierta == i,
            onTap: () => _toggle(i),
          ),
          if (i < _faqs.length - 1) const SizedBox(height: 8),
        ],
        const SizedBox(height: 28),
        Center(
          child: Column(
            children: [
              Text(
                '¿Otra duda? Escríbenos por WhatsApp.',
                style: GoogleFonts.jost(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              UlButton.tertiary(
                label: 'Hablar con la marca',
                onPressed: () => launchUrl(
                  Uri.parse(_whatsappUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String pregunta;
  final String respuesta;
  final bool abierta;
  final VoidCallback onTap;

  const _FaqItem({
    required this.pregunta,
    required this.respuesta,
    required this.abierta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: AppMotion.curve,
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: abierta ? AppColors.goldA45 : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 58),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        pregunta,
                        style: GoogleFonts.jost(
                          fontSize: 15,
                          height: 1.35,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    AnimatedRotation(
                      turns: abierta ? 0.125 : 0,
                      duration: const Duration(milliseconds: 320),
                      curve: AppMotion.curve,
                      child: const Icon(
                        Symbols.add,
                        size: 22,
                        weight: 300,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: AppMotion.curve,
            alignment: Alignment.topCenter,
            child: abierta
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Text(
                      respuesta,
                      style: GoogleFonts.jost(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
