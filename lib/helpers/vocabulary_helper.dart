class VocabularyHelper {
  static Map<String, String> _vocab(String type) {
    switch (type.toLowerCase()) {
      case 'clínica':
      case 'médico':
        return {
          'turno': 'cita',
          'cliente': 'paciente',
          'servicio': 'consulta',
          'agenda': 'agenda médica',
          'cobro': 'honorarios',
        };
      case 'psicología':
        return {
          'turno': 'sesión',
          'cliente': 'paciente',
          'servicio': 'terapia',
          'agenda': 'agenda',
          'cobro': 'honorarios',
        };
      case 'veterinaria':
        return {
          'turno': 'consulta',
          'cliente': 'dueño',
          'servicio': 'atención',
          'agenda': 'agenda',
          'cobro': 'honorarios',
        };
      case 'abogado':
        return {
          'turno': 'reunión',
          'cliente': 'cliente',
          'servicio': 'consultoría',
          'agenda': 'agenda',
          'cobro': 'honorarios',
        };
      default:
        return {
          'turno': 'turno',
          'cliente': 'cliente',
          'servicio': 'servicio',
          'agenda': 'agenda',
          'cobro': 'cobro',
        };
    }
  }

  static String get(String key, String businessType) =>
      _vocab(businessType)[key] ?? key;
}
