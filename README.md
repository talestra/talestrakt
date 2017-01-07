### Para programadores

El entorno de desarrollo es intelliJ Community Edition.
Para la construcción y gestión de dependencias se usa gradle.
El lenguaje de programación elegido es Kotlin.
La versión 1.1-M04. Para activarla en intelliJ: `Tools` - `Kotlin` - `Configure Kotlin Plugin Updates...`

Las únicas dependencias externas a éstas son (ya están referenciadas en gradle):
[korio](https://github.com/soywiz/korio),
[korim](https://github.com/soywiz/korim) y
[korui](https://github.com/soywiz/korui).

Para abrir el proyecto basta con abrir el `build.gradle` del raíz
en intelliJ.

### Para traductores

Cada juego está en una carpeta `game-`, dentro suele haber una carpeta
resources. Y generalmente los textos están en texto plano.
Con lo que se puede hacer un fork (botón de arriba a la derecha de esta página),
editarlos/traducirlos y hacer una PR (Pull Request).

Iré migrando todos los textos a formato .po para poderlos editar
con programas específicos.

Mi recomendación es [BetterPoEditor](https://github.com/mlocati/betterpoeditor/releases).
