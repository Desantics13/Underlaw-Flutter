import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

// Mismas preguntas que FAQS en Home.jsx.
const _faqs = [
  ['¿Cómo funcionan los drops?',
      'Cada drop se anuncia con fecha y hora exacta. Te inscribes con tu correo y te avisamos cuando abre la compra. Las unidades son limitadas y no se reponen.'],
  ['¿Cuánto tarda el envío?',
      'Entre 2 y 5 días hábiles a ciudades principales de Colombia. Te enviamos la guía de rastreo por WhatsApp en cuanto el pedido sale.'],
  ['¿Qué talla pido?',
      'El corte es oversized unisex. Si prefieres un calce más ajustado, pide una talla menos de la que usas normalmente.'],
  ['¿Cómo cuido la prenda?',
      'Lavado a mano o en ciclo delicado con agua fría, al revés. Sin secadora ni blanqueador. Plancha por el lado interno para proteger el estampado.'],
  ['¿Puedo cambiar o devolver?',
      'Sí. Tienes 5 días desde que recibes el pedido para solicitar cambio de talla, siempre que la prenda esté sin uso y con su etiqueta.'],
  ['¿Qué medios de pago aceptan?',
      'Tarjeta débito y crédito, PSE y Nequi a través de Wompi. Recibes la factura en PDF por correo al confirmar el pago.'],
];

const _whatsappUrl = 'https://api.whatsapp.com/send/?phone=573103184180&text&type=phone_number&app_absent=0';

class FaqSection extends StatefulWidget {
  const FaqSection({super.key});

  @override
  State<FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends State<FaqSection> {
  int _abierta = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Preguntas frecuentes', style: serifTitle(size: 30), textAlign: TextAlign.center),
          const SizedBox(height: 28),
          for (var i = 0; i < _faqs.length; i++) _buildItem(i),
          const SizedBox(height: 28),
          Column(
            children: [
              const Text('¿Otra duda? Escríbenos por WhatsApp.', style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => launchUrl(Uri.parse(_whatsappUrl), mode: LaunchMode.externalApplication),
                child: const Text('Hablar con la marca', style: TextStyle(color: AppColors.gold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItem(int i) {
    final abierta = _abierta == i;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: InkWell(
        onTap: () => setState(() => _abierta = abierta ? -1 : i),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(_faqs[i][0], style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
                  ),
                  Text(abierta ? '−' : '+', style: const TextStyle(color: AppColors.gold, fontSize: 20)),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity, height: 0),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_faqs[i][1], style: const TextStyle(color: AppColors.textMuted, height: 1.5)),
                ),
                crossFadeState: abierta ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
