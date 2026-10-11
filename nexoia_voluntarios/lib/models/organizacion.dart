class Organizacion {
  Organizacion({
    required this.id,
    required this.nombre,
    this.tipo,
    this.contacto,
    this.sitio,
    this.usuarioId,
    required this.estado,
  });

  final int id;
  final String nombre;
  final String? tipo;
  final String? contacto;
  final String? sitio;
  final int? usuarioId;
  final String estado;

  factory Organizacion.fromJson(Map<String, dynamic> json) => Organizacion(
        id: (json['id'] as num).toInt(),
        nombre: json['nombre'] as String,
        tipo: json['tipo'] as String?,
        contacto: json['contacto'] as String?,
        sitio: json['sitio'] as String?,
        usuarioId: (json['usuario_id'] as num?)?.toInt(),
        estado: json['estado'] as String? ?? 'pendiente',
      );
}
