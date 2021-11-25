Propuestas de mejora de Ethereum (EIP)
Gitter

Las propuestas de mejora de Ethereum (EIP) describen los estándares para la plataforma Ethereum, incluidas las especificaciones del protocolo central, las API del cliente y los estándares del contrato. Explore todos los EIP actuales y en borrador en el sitio oficial del EIP .

Antes de iniciar una solicitud de extracción , lea el documento de proceso EIP-1 .

Una vez que se fusiona su primer RP, tenemos un bot que ayuda al fusionar automáticamente los RP para redactar los EIP. Para que esto funcione, debe poder decir que eres el propietario del borrador que se está editando. Asegúrese de que la línea 'autor' de su EIP contenga su nombre de usuario de GitHub o su dirección de correo electrónico dentro de <corchetes triangulares>. Si usa su dirección de correo electrónico, esa dirección debe ser la que se muestra públicamente en su perfil de GitHub .

Objetivo del proyecto
El repositorio de propuestas de mejora de Ethereum existe como un lugar para compartir propuestas concretas con los usuarios potenciales de la propuesta y la comunidad de Ethereum en general.

Formato de cita preferido
La URL canónica de un EIP que ha alcanzado el estado de borrador en cualquier momento se encuentra en https://eips.ethereum.org/ . Por ejemplo, la URL canónica de EIP-1 ​​es https://eips.ethereum.org/EIPS/eip-1 .

Considere todo lo que no esté publicado en https://eips.ethereum.org/ como documento de trabajo.

Y considere todo lo publicado en https://eips.ethereum.org/ con un estado de "borrador" como un borrador incompleto.

Validación
Los EIP deben pasar algunas pruebas de validación. El repositorio de EIP garantiza esto mediante la ejecución de pruebas utilizando html- proofer y eipv .

Es posible ejecutar el validador EIP localmente:

carga instalar eipv
eipv < ARCHIVO DE ENTRADA / DIRECTORIO >
Automerger
El repositorio de EIP contiene una función de "combinación automática" para facilitar la carga de trabajo de los editores de EIP. Si se realiza un cambio a través de un RP en un borrador de EIP, entonces los autores del EIP pueden GitHub aprobar el cambio para que se fusione automáticamente. Esto lo maneja el EIP-Bot .

Desarrollo local
Prerrequisitos
Terminal abierta.

Compruebe si tiene Ruby 2.1.0 o superior instalado:

$ ruby ​​--version
Si no tiene Ruby instalado, instale Ruby 2.1.0 o superior.

Instalar Bundler:

$ paquete de instalación de gemas
Instalar dependencias:
$ paquete de instalación
Construya su sitio Jekyll local
Agrupe los activos e inicie el servidor:
$ bundle exec jekyll serve
Obtenga una vista previa de su sitio Jekyll local en su navegador web en http://localhost:4000.
