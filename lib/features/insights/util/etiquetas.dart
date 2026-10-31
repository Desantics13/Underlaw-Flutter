/// Nombres legibles de las métricas que devuelve el servicio.
const _metricas = {
  'MAE': 'MAE',
  'RMSE': 'RMSE',
  'MAPE_%': 'MAPE',
  'R2': 'R²',
  'CV_RMSE': 'RMSE (CV)',
  'CV_ROC_AUC': 'ROC-AUC (CV)',
  'ROC_AUC': 'ROC-AUC',
  'accuracy': 'Exactitud',
  'precision': 'Precisión',
  'recall': 'Sensibilidad',
  'F1': 'F1',
  'silueta': 'Silueta',
  'davies_bouldin': 'Davies-Bouldin',
  'calinski_harabasz': 'Calinski-Harabasz',
};

String etiquetaMetrica(String clave) => _metricas[clave] ?? clave;

/// Valor de una métrica con coma decimal; MAPE con %.
String valorMetrica(String clave, dynamic valor) {
  if (valor is! num) return '$valor';
  final texto = valor.abs() >= 100
      ? valor.toStringAsFixed(1)
      : valor.toStringAsFixed(clave == 'MAPE_%' ? 1 : 3);
  return '${texto.replaceAll('.', ',')}${clave == 'MAPE_%' ? ' %' : ''}';
}

/// Fecha ISO (2026-09-28) en formato corto colombiano (28/09).
String fechaCorta(String iso) {
  final p = iso.split('-');
  return p.length >= 3 ? '${p[2].substring(0, 2)}/${p[1]}' : iso;
}
