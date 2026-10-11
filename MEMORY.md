# MEMORY.md — NexoIA

Memoria viva y **guía de implementación** del proyecto **NexoIA**: plataforma de
gestión de voluntariado de la Universidad Central de Nicaragua (UCN).

> Este archivo es la **fuente de verdad**. Si retomas el proyecto (o haces la app
> móvil por aparte), todo lo necesario está aquí.
> Regla: actualizarlo junto con `NexoIA-Plan-de-Trabajo.md` (Escritorio) tras cada avance.

---

## 0. Stack y roles

- **Backend / IA:** Python 3.12, FastAPI, SQLAlchemy, Alembic, JWT (bcrypt + PyJWT).
  Después: scikit-learn + sentence-transformers.
- **App móvil + panel web:** Dart / Flutter (mismo proyecto para ambos).
- **Base de datos:** SQLite en desarrollo; PostgreSQL (Railway/Supabase) en prod.
- **Editores:** VS Code (Python), Android Studio (Flutter). Dispositivo físico por USB.
- **Roles del equipo:** Roberto → backend/BD/IA; Rafael → Flutter (app + web) + UX/UI;
  Wilmer (mentor) → alianzas con organizaciones.

---

## 1. Visión: el ecosistema de 4 componentes

1. **App móvil para voluntarios (estudiantes).** Perfil → oportunidades con **% de
   coincidencia** → detalle (aceptar/rechazar) → **asistencia por QR**.
2. **App móvil/web para organizaciones.** Publicar necesidades → **candidatos
   sugeridos con %** e invitar → aprobar equipos → evaluar resultados.
3. **Panel administrativo web (coordinadores UCN).** Dashboard (organizaciones,
   proyectos, estudiantes, horas), aprobar registros, supervisar, formar equipos,
   estadísticas por carrera/comunidad, certificados, reportes.
4. **Algoritmo inteligente de apoyo a la decisión (IA).** Compatibilidad %,
   recomendaciones, equipos multidisciplinarios, clasificación por prioridad,
   detección de sobrecarga, resúmenes. Premisa: **"IA de apoyo, decisión humana".**

---

## 2. Estado actual (lo que YA funciona)

**Backend**
- Auth JWT. Registro con `@gmail.com` obligatorio, correos y contraseñas **únicos**.
- Modelos: usuarios/perfiles, organizaciones, necesidades, postulaciones/equipos,
  actividades, certificados, evaluaciones.
- Routers: `health, auth, usuarios, organizaciones, necesidades, postulaciones,
  asistencias, certificados, indicadores, simulacion`.
- **Simulación de propuestas**: al registrarse el estudiante elige intereses y el
  sistema genera 4–5 propuestas acordes que "llegan" escalonadas (1ª inmediata, luego
  una cada `SIM_INTERVALO_SEGUNDOS`, por defecto 120 s).
- **Compatibilidad (%)** heurística intereses+habilidades (`services/match.py`).
- **Aceptar/Rechazar** oportunidades (`POST /postulaciones` = aceptado; `/postulaciones/rechazar`).
  Al decidir, la oportunidad desaparece del feed y de recomendadas.
- **Asistencia por QR**: `POST /asistencias/generar` (código temporal 120 s) →
  `POST /asistencias/validar` (coordinador suma 4 h y marca `validado`) → `GET /asistencias/mias`.
- **Organizaciones (Fase 3)**: al registrar un rol `organizacion` se crea/enlaza su
  `Organizacion` (`usuario_id`). `GET /organizaciones/mia`; publicar necesidades
  (`POST /necesidades` con `estado`); `GET /necesidades/{id}/candidatos` (estudiantes +
  `% match`); `POST /necesidades/{id}/invitar` (crea postulación `sugerido`).
- **Panel admin (Fase 4)**: `GET /usuarios/estudiantes` (horas, nº certificados,
  alerta de **sobrecarga** ≥ 100 h); **certificados** (`POST/GET /certificados`,
  `GET /certificados/mios`, `GET /certificados/verificar/{codigo}` público, y
  `GET /certificados/{id}/pdf` con **PDF + QR** generado por `services/certificado_pdf.py`
  con reportlab); KPIs de impacto por organización en `GET /organizaciones/{id}/indicadores`;
  **equipos** (`GET/POST /equipos`, `POST /equipos/armar` auto-multidisciplinario,
  `DELETE /equipos/{id}`); **reportes** (`GET /reportes/resumen` JSON + `GET /reportes/horas.csv`).
- Migraciones Alembic aplicadas. Seed con datos demo.

**App (Flutter)** — compartida móvil/web
- Login, registro con selección de intereses, splash con logo UCN a color.
- **Estudiante**: feed "Propuestas para ti" (en vivo, simulación escalonada) + lista de oportunidades con **% match**, detalle, postularse (aceptar/rechazar), mis postulaciones (ver QR si aceptado, ver horas validadas), perfil (editar carrera/año/habilidades, **ver "Mis certificados" + descargar PDF**).
- **Coordinador** (Drawer): Dashboard (KPIs + horas por carrera), Validar asistencia (código QR → +4 h), **Estudiantes** (lista con horas/certificados, badge *sobrecarga*, botón "Emitir certificado"), **Certificados** (lista + descargar PDF), **Equipos** (armar auto por necesidad + listar), **Reportes** (resumen + exportar CSV), **Organizaciones** (aprobar/listar), **Necesidades** (supervisar/filtros).
- **Organización**: shell con tabs "Mis necesidades" (listar/estado) y "Publicar" (crear con estado), **Candidatos** (estudiantes ordenados por % match, invitar → postulación `sugerido`).
- UI moderna: gradientes, tarjetas suaves, badges de estado, % match con color, QR con temporizador 120 s.

---

## 3. CÓMO CONECTAR LA APP MÓVIL (paso a paso)

Es **un solo backend + una sola base de datos** para móvil, web y panel. La conexión
es **API REST + JSON** con **token JWT**.

### 3.1. Dirección base (la clave)
La app lee la URL del backend desde `lib/core/api_config.dart` (`ApiConfig.baseUrl`):

| Entorno | baseUrl |
|---|---|
| Emulador Android | `http://10.0.2.2:8000` |
| **Celular físico (Wi‑Fi, tu caso)** | `http://<IP_LAN_DE_TU_PC>:8000` |
| Web en el mismo PC | `http://127.0.0.1:8000` |
| iPhone (iOS) | `http://<IP_LAN_DE_TU_PC>:8000` |

El backend debe escuchar en todas las interfaces:
`uvicorn app.main:app --host 0.0.0.0 --port 8000`.

### 3.2. Pasos concretos
1. En el PC: `ipconfig` → copiar la **IPv4 del adaptador Wi‑Fi** (ej. `192.168.1.5`).
2. En `api_config.dart` poner esa IP en `lanIp`.
3. PC y teléfono **en la misma red Wi‑Fi**.
4. Activar **depuración USB** en el teléfono; conectarlo; `flutter devices` para verlo.
5. `flutter run -d <device>`.
6. Si no conecta: permitir el **puerto 8000** en el Firewall de Windows (perfil privado).

### 3.3. Permiso de HTTP en claro (¡IMPORTANTE en Android!)
Android bloquea HTTP sin cifrar por defecto. Para `http://192.168.x.x:8000` hay que
habilitarlo en `android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">192.168.1.5</domain>
        <domain includeSubdomains="true">10.0.2.2</domain>
    </domain-config>
</network-security-config>
```

Y referenciarlo en `android/app/src/main/AndroidManifest.xml`:
`<application android:networkSecurityConfig="@xml/network_security_config" ...>`

Alternativa rápida de demo: `android:usesCleartextTraffic="true"` en el `<application>`.
En iOS (`Info.plist`) agregar `NSAppTransportSecurity → NSAllowsArbitraryLoads = true`.

### 3.4. Reglas de conexión
- Tras login, guardar el `access_token` en `shared_preferences` y mandarlo en cada
  request: `Authorization: Bearer <token>`.
- CORS ya está en `allow_origins=["*"]` (no da problema para pruebas).
- Errores del backend llegan como `{"detail": "mensaje"}` (o lista de validación 422).

---

## 4. CONTRATO DE API (referencia para la app)

Base: `http://<host>:8000`. Todos los POST/PUT son JSON salvo `/auth/login`.

### Autenticación
- `POST /auth/register` — body:
  `{ "nombre", "correo", "contrasena", "rol": "estudiante|organizacion|coordinador", "intereses": ["ambiental", ...] }`
  → `201 UsuarioOut`. Errores: correo no gmail (422), correo/contraseña repetidos (400).
- `POST /auth/login` — **form-urlencoded**: `username=<correo>&password=<clave>`
  → `{ "access_token", "token_type" }`.
- `GET /auth/me` → `UsuarioOut`.

### Simulación (estudiante)
- `GET /simulacion/intereses` → `[{ "clave", "label", "emoji", "naturaleza" }]`.
- `GET /simulacion/mis-propuestas` → `FeedSimulacion` (ver shapes).
- `POST /simulacion/reiniciar` → vuelve a generar según intereses actuales.

### Organizaciones
- `GET /organizaciones?estado=` (autenticado) → `[Organizacion]`.
- `GET /organizaciones/mia` (org) → tu `Organizacion` (o 404).
- `POST /organizaciones` (org/coord); `PATCH /organizaciones/{id}/estado` (coord).

### Necesidades
- `GET /necesidades/recomendadas` (estudiante) → `[NecesidadRecomendada]` orden desc. por `compatibilidad`.
- `GET /necesidades?estado=publicada&organizacion_id=` → `[Necesidad]` (solo reales; excluye simuladas).
- `GET /necesidades/{id}` → `Necesidad`.
- `POST /necesidades` (org/coord) — body con `organizacion_id, titulo, ..., estado?` (`publicada` o `borrador`).
- `PUT /necesidades/{id}` (org/coord).
- `GET /necesidades/{id}/candidatos` (org dueña/coord) → `[Candidato]` orden desc. por `compatibilidad`.
- `POST /necesidades/{id}/invitar` (org dueña/coord) — body `{ "estudiante_id" }` → `Postulacion` (`sugerido`).

### Postulaciones
- `POST /postulaciones` — body `{ "necesidad_id" }` → `PostulacionDetalle` (estado `aceptado`).
- `POST /postulaciones/rechazar` — body `{ "necesidad_id" }` → `PostulacionDetalle` (estado `rechazado`).
- `GET /postulaciones/mias` (estudiante) → `[PostulacionDetalle]` (con título, horas).
- `PATCH /postulaciones/{id}` (org/coord) — body `{ "estado": "aceptado|rechazado|validado" }`.

### Asistencias / QR (estudiante + coordinador)
- `POST /asistencias/generar` (estudiante) — body `{ "necesidad_id" }` → `QrGenerado`.
  Devuelve `codigo`, `expira_en` y `segundos` (vida 120 s; si hay uno vigente lo reutiliza).
- `POST /asistencias/validar` (coord/org) — body `{ "codigo" }` → `ValidarResultado`.
  Si es válido: marca la asistencia, suma **4 h** a `horas_acumuladas` y pasa la
  postulación a `validado`.
- `GET /asistencias/mias` (estudiante) → `[Asistencia]`.

### Perfil y panel
- `PUT /usuarios/me/perfil` — body `{ "carrera", "anio", "habilidades": [], "intereses": [] }` → `UsuarioOut`.
- `GET /indicadores` (coord) → KPIs + horas por carrera.
- `GET /organizaciones/{id}/indicadores` (org dueña/coord) → KPIs de impacto
  (`necesidades.total/publicadas/finalizadas`, `postulaciones`, `voluntarios`, `horas`).

### Certificados y panel admin (Fase 4)
- `GET /usuarios/estudiantes` (coord) → `[EstudianteResumen]` orden desc. por horas.
- `POST /certificados` (coord) — body `{ "estudiante_id", "horas"? }` (si omiten `horas`
  toma las `horas_acumuladas`) → `Certificado` (código `CERT-XXXXXXXX`).
- `GET /certificados` (coord) → `[Certificado]`.
- `GET /certificados/mios` (estudiante) → `[Certificado]`.
- `GET /certificados/verificar/{codigo}` (público) → `{ valido, estudiante, horas, fecha }`.
- `GET /certificados/{id}/pdf` (dueño/coord) → PDF descargable (certificado + QR).

### Equipos y Reportes (Fase 4)
- `GET /equipos` (coord) → `[EquipoOut]`.
- `POST /equipos` (coord) — body `{ necesidad_id, estudiante_ids[] }` → `EquipoOut`.
- `POST /equipos/armar` (coord) — body `{ necesidad_id, max_integrantes? }` → `EquipoOut`
  (auto-armado: prioriza cubrir habilidades requeridas + diversidad de carreras, ordenado por match).
- `DELETE /equipos/{id}` (coord).
- `GET /reportes/resumen` (coord) → `ResumenReportes` (totales, por carrera, top orgs).
- `GET /reportes/horas.csv` (coord) → CSV descargable (nombre, correo, carrera, año, horas, certificados, sobrecarga).

### SHAPES
```
UsuarioOut          { id, nombre, correo, rol, activo, perfil: { carrera, anio,
                      habilidades[], intereses[], disponibilidad, horas_acumuladas } }
Necesidad           { id, organizacion_id, titulo, descripcion, naturaleza, prioridad,
                      habilidades_requeridas[], cupos, ubicacion, fecha, estado, visible_desde }
NecesidadRecomendada  = Necesidad + compatibilidad (int 0-100)
FeedSimulacion      { activa, total, recibidas, siguiente_en (seg|null), intervalo,
                      propuestas: [NecesidadRecomendada] }
Postulacion         { id, estudiante_id, necesidad_id, estado }
PostulacionDetalle  = Postulacion + necesidad_titulo, necesidad_naturaleza,
                      necesidad_ubicacion, horas
Asistencia          { id, estudiante_id, necesidad_id, horas, validado, codigo_qr, fecha }
QrGenerado          { codigo, expira_en (ISO), segundos, necesidad_id, necesidad_titulo }
ValidarResultado    { ok, mensaje, estudiante, necesidad, horas }
Interes             { clave, label, emoji, naturaleza }
Organizacion        { id, usuario_id, nombre, tipo, contacto, sitio, estado }
Candidato           { estudiante_id, nombre, correo, carrera, anio,
                      habilidades[], horas_acumuladas, compatibilidad, invitado }
EstudianteResumen   { id, nombre, correo, carrera, anio, habilidades[],
                      horas_acumuladas, certificados, sobrecarga }
Certificado         { id, estudiante_id, estudiante_nombre, horas,
                      codigo_verificacion, fecha }
VerificacionOut     { valido, estudiante, horas, fecha }
IntegranteOut       { estudiante_id, nombre, correo, carrera, rol, compatibilidad }
EquipoOut           { id, necesidad_id, necesidad_titulo, integrantes: [IntegranteOut] }
ResumenReportes     { totales: { estudiantes, organizaciones, necesidades,
                      necesidades_publicadas, postulaciones, validaciones,
                      horas_totales, certificados, sobrecarga },
                      por_carrera: [{ carrera, cantidad, horas }],
                      top_organizaciones: [{ id, nombre, necesidades }] }
```

Estados de postulación: `sugerido` (invitación de la organización) → `aceptado`
(el estudiante acepta) → `validado` (asistió y se validó el QR). `rechazado` = descartada.

---

## 5. APP MÓVIL — blueprint detallado (pantalla por pantalla)

**Design system** (ya definido en `lib/core/theme.dart` y `lib/widgets/`):
- Color semilla verde UCN `#0E7C66`; `heroGradient` (verde), `softGradient` (fondo).
- Componentes: `SoftCard` (tarjeta con sombra suave), `NecesidadCard` (con % match y
  badge NUEVA), `EstadoBadge`, `TagChip`, `LogoUcn`, `FeedPropuestas` (feed en vivo).
- **Logo UCN**: `assets/images/ucn_logo.svg` (declarado en `pubspec.yaml`, usado en
  `lib/widgets/logo_ucn.dart` → `SvgPicture.asset('assets/images/ucn_logo.svg')`).

### 5.1. Splash
Logo UCN a color + carga de token guardado. Si hay token → `/auth/me`; decide a dónde ir.

### 5.2. Login
- Campos correo/contraseña. Botón ingresar. Enlace "Registrarse".
- `POST /auth/login` (form) → guardar token → `GET /auth/me`.
- Hint demo: `rafael.mairena@gmail.com / rafael123`.

### 5.3. Registro
- Nombre, correo (**validar `@gmail.com`**), contraseña (mín. 6), tipo de cuenta.
- **Si es estudiante:** mostrar chips de **intereses** (desde `GET /simulacion/intereses`),
  obligar al menos 1. Garantizar categorías visualmente bonitas (emoji + label).
- `POST /auth/register` con `intereses` → hace login automático.

### 5.4. Home estudiante (3 pestañas)
Barra inferior: **Oportunidades · Mis horas · Perfil**.

**Pestaña Oportunidades**
1. Encabezado con degradado + logo + saludo "Hola, <Nombre>".
2. **Feed "Propuestas para ti"** (widget `FeedPropuestas`):
   - `GET /simulacion/mis-propuestas` al entrar y cada ~12 s (polling).
   - Muestra tarjetas con **% match**; badge **NUEVA** para las recién llegadas.
   - Contador "Próxima propuesta en m:ss" (usa `siguiente_en`).
   - Aviso (SnackBar) cuando llega una nueva. Botón refresh = `POST /simulacion/reiniciar`.
   - Al terminar (`activa=false`) → mensaje "No hay más propuestas por ahora".
3. Lista "Todas las oportunidades" con `GET /necesidades/recomendadas`, filtros por
   categoría y búsqueda.

**Pestaña Mis horas / Postulaciones**
- `GET /postulaciones/mias` → mejor mostrar el **título real** de la actividad
  (hoy el backend devuelve solo `necesidad_id`; ver "Mejoras backend" abajo), estado
  y horas. Resumen de impacto (beneficiarios, satisfacción).

**Pestaña Perfil**
- Ver/editar carrera, año, **habilidades** e **intereses** (`PUT /usuarios/me/perfil`).
- Horas acumuladas, cerrar sesión.

### 5.5. Detalle de oportunidad
- Título, % match, categoría, ubicación, cupos, fecha/duración, descripción,
  habilidades requeridas, prioridad.
- Botones **Aceptar** (verde) y **Rechazar** (blanco):
  - Aceptar → `POST /postulaciones { necesidad_id }`.
  - Rechazar → marcar localmente / `PATCH` si aplica según diseño.

### 5.6. Asistencia por QR  ⟵ (Fase 2, ✅ hecho)
- `AsistenciaScreen` (`lib/screens/asistencia_screen.dart`): llama
  `POST /asistencias/generar`, muestra el **QR** (`qr_flutter`), el código en texto y
  un **temporizador** m:ss. Al expirar, botón "Generar nuevo código".
- El coordinador usa la pestaña **Validar** del panel (`validar_asistencia_screen.dart`):
  ingresa el código → `POST /asistencias/validar` → muestra voluntario, actividad y
  horas sumadas.
- En "Mis horas / Postulaciones", una postulación `aceptado` muestra
  **"Mostrar QR de asistencia"**; una `validado` muestra el check "Asistencia validada".

---

## 6. App Organizaciones — blueprint (✅ Fase 3 hecha)

Pantallas en `lib/screens/organizacion/`, ruta por rol en `main.dart` (`OrganizacionShell`):
- **Mis necesidades** (`mis_necesidades_screen.dart`): `GET /organizaciones/mia` +
  `GET /necesidades?organizacion_id=`, tarjetas con estado y botón **Ver candidatos**.
- **Publicar** (`publicar_necesidad_screen.dart`): formulario (título, descripción,
  categoría, prioridad, cupos, ubicación, habilidades) + switch "Publicar ahora".
  Envía `POST /necesidades` con `estado`.
- **Candidatos** (`candidatos_screen.dart`): `GET /necesidades/{id}/candidatos`
  ordenados por **% match**; botón **Invitar** (`POST /necesidades/{id}/invitar`).
- La invitación crea una postulación `sugerido` que el estudiante ve en "Mis horas"
  y puede **Aceptar / Rechazar**.
- Pendiente: KPIs de impacto (beneficiarios, satisfacción) y "Solicitar seguimiento".

## 7. Panel Admin Web — blueprint

- Dashboard: 4 tarjetas (organizaciones, proyectos, estudiantes, horas) + gráfico
  "Horas por carrera" + tabla "Proyectos en supervisión".
- Aprobar organizaciones y estudiantes; supervisar; formar equipos;
  estadísticas; certificados; reportes.
- **Hecho (Fase 4):** el panel coordinador ahora es un `Drawer` con Dashboard,
  Validar asistencia, **Estudiantes** (lista con horas/certificados + badge
  *sobrecarga* ≥ 100 h + botón **Emitir certificado**) y **Certificados**
  (lista + **Descargar PDF**). El estudiante ve "Mis certificados" en su perfil.
- **Pendiente:** equipos multidisciplinarios, reportes/exportación.

## 8. Algoritmo IA — módulos (evolución)

- **v1 (hecho):** compatibilidad heurística intereses 75% + habilidades 25% (`services/match.py`).
- **v2:** match semántico con `sentence-transformers` (embeddings de descripción vs perfil).
- Prioridad automática, armado de equipos por roles, detección de sobrecarga (>100%),
  resúmenes automáticos. Premisa: la IA **sugiere**, las personas **deciden**.

---

## 9. Plan por fases

| Fase | Contenido | Estado |
|---|---|---|
| **1** | Compatibilidad % (recomendadas + feed + tarjetas) | ✅ |
| **2** | Detalle Aceptar/Rechazar + Asistencia QR (temporizador) | ✅ |
| **3** | App Organizaciones (publicar, candidatos %, invitar) | ✅ |
| **4** | Panel Admin (certificados, sobrecarga, KPIs org, PDF+QR, equipos, reportes CSV) | ✅ |
| **5** | IA real (scikit-learn + sentence-transformers) | ⬜ |

### Mejoras backend pendientes (para habilitar fases)
- ~~`PostulacionOut` con `necesidad_titulo` y `horas`~~. ✅ (`PostulacionDetalleOut`)
- ~~`POST /asistencias` + `GET /asistencias/mias` (QR + suma de horas)~~. ✅
- ~~`GET /necesidades/{id}/candidatos` + invitar~~. ✅
- ~~KPIs de impacto por organización (`GET /organizaciones/{id}/indicadores`)~~. ✅
- ~~Tabla/endpoint de **certificados** (+ PDF/QR) y **sobrecarga**~~. ✅
- ~~**Equipos** (`GET/POST /equipos`, `POST /equipos/armar`, `DELETE /equipos/{id}`)~~. ✅
- ~~**Reportes** (`GET /reportes/resumen`, `GET /reportes/horas.csv`)~~. ✅
- Pendiente: IA real (v2 semántico), piloto con usuarios reales.

---

## 10. Credenciales demo

| Rol | Correo | Contraseña |
|---|---|---|
| Estudiante (Rafael Mairena) | rafael.mairena@gmail.com | rafael123 |
| Organización | fundacion.verde@gmail.com | fundacion123 |
| Coordinador | coordinador.ucn@gmail.com | coordinador123 |

## 11. Cómo correr

**Backend**
```
cd C:\Users\user\NexoIA\backend
.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```
Swagger: `http://127.0.0.1:8000/docs`. Reset BD: borrar `nexoia.db` → `alembic upgrade head` → `python -m app.seed`.

**App web**
```
cd C:\Users\user\NexoIA\nexoia_voluntarios
flutter run -d edge
# o servir el build: build\web en un http.server:8080
```

**App móvil**
```
flutter devices
flutter run -d <device>   # con la IP LAN puesta en api_config.dart
```

**Simulación rápida para demos:** en `backend\.env` → `SIM_INTERVALO_SEGUNDOS=15`.

## 12. Bitácora breve (más reciente primero)
- **Fase 4 ✅**: Panel coordinador con Drawer (8 secciones), lista de **Estudiantes** con
  horas/certificados/badge *sobrecarga* ≥ 100 h + botón **Emitir certificado**;
  **Certificados** (lista + descargar PDF con QR); **Equipos** (armar automático
  multidisciplinario por necesidad + listar/eliminar); **Reportes** (resumen JSON +
  **CSV export**); KPIs de impacto por organización; "Mis certificados" en perfil
  estudiante. PDF+QR generado con reportlab + qrcode.
- **Fase 3**: App Organizaciones (vínculo usuario↔org, publicar, candidatos % match, invitar).
- **Fase 2**: Aceptar/Rechazar + Asistencia por QR (generar/validar, suma de horas).
- Simulación de propuestas + intereses en registro + feed en vivo.
- Fase 1: compatibilidad % (`/necesidades/recomendadas`, tarjetas y feed).
- Logo UCN a color; UI modernizada (gradientes, tarjetas suaves).
- Panel coordinador (KPIs, aprobar orgs, supervisar necesidades).
- Backend completo (auth JWT, modelos, migraciones, seed).
