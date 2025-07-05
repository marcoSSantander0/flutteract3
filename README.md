# act3

## Descripción

Este proyecto es una aplicación Flutter desarrollada como parte de la actividad 3 del curso de Programación Móvil. La aplicación demuestra el uso de widgets, navegación, manejo de estado y buenas prácticas en Flutter.

## Características

- Interfaz de usuario intuitiva y responsiva.
- Navegación entre pantallas.
- Manejo de estado eficiente.
- Autenticación con correo/contraseña y Google.
- Creación y gestión de apuntes personales.
- Subida de imágenes a apuntes.
- Reconocimiento de texto (OCR) en imágenes usando Google ML Kit.
- Procesamiento de texto con IA (OpenAI GPT-4o-mini) para organizar apuntes en formato académico Markdown.
- Persistencia de datos en Firebase Firestore y almacenamiento de imágenes en Firebase Storage.
- Compatible con Android y web.

## Requisitos

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (versión recomendada: 3.x o superior)
- [Dart SDK](https://dart.dev/get-dart) (incluido con Flutter)
- Un editor de código como [Visual Studio Code](https://code.visualstudio.com/) o [Android Studio](https://developer.android.com/studio)
- Emulador o dispositivo físico para pruebas
- Cuenta de Firebase y configuración del proyecto (Firestore, Auth, Storage)
- API Key de OpenAI para procesamiento de IA

## Instalación

1. Clona este repositorio:
   ```sh
   git clone <URL_DEL_REPOSITORIO>
   cd act3
   ```

2. Instala las dependencias:
   ```sh
   flutter pub get
   ```

3. Ejecuta la aplicación:
   ```sh
   flutter run
   ```

## Estructura de Carpetas

```
act3/
├── android/           # Archivos específicos para Android
├── ios/               # Archivos específicos para iOS
├── lib/               # Código fuente principal en Dart
│   ├── app.dart       # Configuración principal de rutas y AuthGate
│   ├── features/
│   │   ├── auth/
│   │   │   ├── presentation/
│   │   │   │   └── login_screen.dart   # Pantalla de login/registro
│   │   │   └── services/
│   │   │       └── auth_service.dart   # Lógica de autenticación
│   │   ├── home/
│   │   │   └── presentation/
│   │   │       └── home_screen.dart    # Pantalla principal de apuntes
│   │   ├── note_detail/
│   │   │   └── presentation/
│   │   │       └── note_detail_screen.dart # Detalle de apunte, OCR, IA
│   │   └── notes/
│   │       └── services/
│   │           └── notes_service.dart  # Lógica de apuntes, imágenes, IA
│   └── env.dart        # Variables de entorno (API keys, etc)
├── test/              # Pruebas unitarias y de widgets
├── pubspec.yaml       # Archivo de configuración y dependencias
└── README.md          # Documentación del proyecto
```

## Arquitectura y Flujo de la Aplicación

### 1. Autenticación

- **login_screen.dart**: Permite al usuario iniciar sesión o registrarse con correo/contraseña o Google. Muestra errores y alterna entre login y registro.
- **auth_service.dart**: Implementa la lógica de autenticación usando Firebase Auth. Soporta login, registro y Google Sign-In (web y móvil). Al registrar un usuario, crea su documento en Firestore.

### 2. Home (Listado de Apuntes)

- **home_screen.dart**: Muestra la lista de apuntes del usuario autenticado, obtenidos en tiempo real desde Firestore. Permite cerrar sesión y crear nuevos apuntes.

### 3. Detalle de Apunte

- **note_detail_screen.dart**: Permite ver y editar un apunte. Funcionalidades:
  - Subir imágenes (usando ImagePicker y Firebase Storage).
  - Ejecutar OCR sobre las imágenes (Google ML Kit) y almacenar el texto crudo.
  - Editar manualmente el texto crudo.
  - Procesar el texto crudo con IA (OpenAI GPT-4o-mini) para organizarlo en formato académico Markdown.
  - Editar manualmente el texto organizado.

### 4. Servicios

- **notes_service.dart**: Gestiona la lógica de Firestore y Storage:
  - Crear usuarios y apuntes.
  - Subir imágenes y asociarlas a apuntes.
  - Ejecutar OCR y almacenar resultados.
  - Llamar a la API de OpenAI para organizar el texto.
  - Actualizar y obtener datos de apuntes.

### 5. app.dart

- Define las rutas principales de la app (`/` para AuthGate, `/noteDetail` para detalle de apunte).
- **AuthGate**: Muestra la pantalla de login o la pantalla principal según el estado de autenticación.

## Tecnologías y Paquetes Usados

- **Flutter**: Framework principal.
- **Firebase Auth**: Autenticación de usuarios.
- **Cloud Firestore**: Base de datos en tiempo real.
- **Firebase Storage**: Almacenamiento de imágenes.
- **Google ML Kit**: OCR para extraer texto de imágenes.
- **OpenAI GPT-4o-mini**: Procesamiento de texto y organización de apuntes.
- **image_picker**: Selección de imágenes desde galería.
- **openai_dart**: Cliente para consumir la API de OpenAI.

## Uso

1. Asegúrate de tener un emulador o dispositivo conectado.
2. Ejecuta `flutter run` para iniciar la aplicación.
3. Navega por las diferentes pantallas y funcionalidades implementadas:
   - Inicia sesión o regístrate.
   - Crea un apunte nuevo.
   - Agrega imágenes al apunte.
   - Ejecuta OCR para extraer texto de las imágenes.
   - Procesa el texto con IA para organizarlo.
   - Edita y consulta tus apuntes.

## Personalización

- Puedes modificar los archivos dentro de la carpeta `lib/` para agregar nuevas funcionalidades o cambiar la interfaz.
- Para agregar dependencias adicionales, edita el archivo `pubspec.yaml` y ejecuta `flutter pub get`.
- Configura tus claves de API y credenciales en `env.dart`.

## Créditos

- Autor: Marcos Jared Santander Ramirez
- Curso: Programación Móvil
- Universidad: Universidad Politécnica de Tulancingo
- Año: 2024

## Licencia

Este proyecto se distribuye bajo la licencia MIT. Consulta el archivo LICENSE para más detalles.

