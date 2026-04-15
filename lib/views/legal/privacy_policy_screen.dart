import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de privacidad'),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: _PolicyContent(),
      ),
    );
  }
}

class _PolicyContent extends StatelessWidget {
  const _PolicyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _Title('Política de Privacidad de BizPulse'),
        _Body(
          'Última actualización: febrero de 2026\n\n'
          'En BizPulse valoramos tu privacidad. Esta política explica qué información '
          'recopilamos, cómo la usamos y cuáles son tus derechos como usuario.',
        ),
        SizedBox(height: 20),

        // 1
        _Heading('1. Datos que recopilamos'),
        _Body(
          'Al usar BizPulse recopilamos los siguientes datos personales y de negocio:\n\n'
          '• Correo electrónico: utilizado para crear y gestionar tu cuenta.\n'
          '• Nombre del negocio y rubro: para personalizar tu experiencia dentro de la app.\n'
          '• Turnos / Agenda: fecha, hora, nombre del cliente y servicio asociado.\n'
          '• Productos / Inventario: nombre, precio y stock de tus productos.\n'
          '• Finanzas: registro de ingresos y gastos de tu negocio.\n'
          '• Logo del negocio (opcional): imagen que subís voluntariamente.',
        ),
        SizedBox(height: 20),

        // 2
        _Heading('2. Cómo almacenamos tus datos'),
        _Body(
          'Toda la información se almacena de forma segura en los servidores de '
          'Google Firebase (Firestore y Firebase Storage), ubicados en la nube. '
          'Firebase cumple con los estándares de seguridad ISO 27001 y SOC 2/3. '
          'Los datos se transmiten siempre mediante conexiones cifradas (TLS/HTTPS).',
        ),
        SizedBox(height: 20),

        // 3
        _Heading('3. Para qué usamos tus datos'),
        _Body(
          'Utilizamos tu información exclusivamente para:\n\n'
          '• Brindarte acceso a las funciones de la app (agenda, inventario, finanzas).\n'
          '• Personalizar la interfaz con el nombre y colores de tu negocio.\n'
          '• Enviarte notificaciones locales de recordatorio de turnos.\n'
          '• Permitirte exportar e importar tus propios datos (función de respaldo).',
        ),
        SizedBox(height: 20),

        // 4
        _Heading('4. Compartir datos con terceros'),
        _Body(
          'BizPulse NO vende, alquila ni comparte tus datos personales con terceros '
          'con fines comerciales o publicitarios.\n\n'
          'Los únicos proveedores de servicio que procesan tus datos son:\n\n'
          '• Google Firebase (almacenamiento y autenticación) — '
          'bajo los términos de privacidad de Google.\n\n'
          'No utilizamos servicios de analítica ni publicidad de terceros.',
        ),
        SizedBox(height: 20),

        // 5
        _Heading('5. Retención de datos'),
        _Body(
          'Tus datos se conservan mientras tu cuenta esté activa. '
          'Si eliminás tu cuenta, todos tus datos (turnos, productos, finanzas, '
          'perfil y logo) son eliminados permanentemente de nuestros servidores '
          'en un plazo máximo de 30 días.',
        ),
        SizedBox(height: 20),

        // 6
        _Heading('6. Tus derechos'),
        _Body(
          'Como usuario de BizPulse tenés derecho a:\n\n'
          '• Acceder a tus datos en cualquier momento desde la app.\n'
          '• Exportar una copia de todos tus datos usando la función de Respaldo.\n'
          '• Corregir o actualizar tus datos desde la sección Cuenta.\n'
          '• Eliminar tu cuenta y todos tus datos asociados contactándonos por '
          'correo electrónico.\n\n'
          'Para ejercer cualquiera de estos derechos escribinos a:\n'
          'networklayers49@gmail.com',
        ),
        SizedBox(height: 20),

        // 7
        _Heading('7. Seguridad'),
        _Body(
          'Implementamos medidas técnicas y organizativas para proteger tus datos '
          'contra accesos no autorizados, pérdida o alteración. Sin embargo, '
          'ningún sistema de transmisión por Internet es 100% seguro. '
          'Te recomendamos usar una contraseña fuerte y no compartirla.',
        ),
        SizedBox(height: 20),

        // 8
        _Heading('8. Cambios en esta política'),
        _Body(
          'Podemos actualizar esta política de privacidad en cualquier momento. '
          'Cuando lo hagamos, actualizaremos la fecha al comienzo del documento. '
          'Te notificaremos sobre cambios significativos a través de la app.',
        ),
        SizedBox(height: 20),

        // 9
        _Heading('9. Contacto'),
        _Body(
          'Si tenés preguntas, dudas o solicitudes relacionadas con tu privacidad, '
          'podés contactarnos en:\n\n'
          'networklayers49@gmail.com\n\n'
          'Respondemos en un plazo máximo de 72 horas hábiles.',
        ),
        SizedBox(height: 32),

        Divider(),
        SizedBox(height: 12),
        Center(
          child: Text(
            'BizPulse © 2026 · Todos los derechos reservados',
            style: TextStyle(fontSize: 11, color: Colors.white38),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final String text;
  const _Body(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.white70,
        height: 1.55,
      ),
    );
  }
}
