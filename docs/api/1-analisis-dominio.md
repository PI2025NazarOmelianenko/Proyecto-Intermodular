# Análisis del Dominio — Sistema de Reservas de Recursos Deportivos

**Autor:** Nazar Omelianenko  
**Proyecto:** UD5 / UT7 — Diseño de API REST  
**SGBD:** MariaDB

---

## 1. Tablas de la base de datos que participan en el CRUD de reservas

El objetivo de la API es gestionar reservas de recursos (salas, pistas, equipamiento). Para ello se necesitan tres tablas:

**RESERVA** (tabla principal)  
Contiene todos los datos de cada reserva: qué recurso se reserva, qué usuario la hace, en qué fecha y franja horaria, cuántas plazas ocupa y por qué motivo.

**RECURSO** (tabla relacionada por FK)  
Necesaria para validar que el recurso existe, conocer su capacidad máxima y obtener su nombre.

**USUARIONORMAL** (tabla relacionada por FK)  
El campo "id_usuario" de RESERVA apunta a esta tabla. Cuando el usuario inicia sesión ek backend le da un token JWT. A partir de ahí cada vez que hace una petición el backend lee ese token y ya sabe quién es. Así que el cliente no necesita enviar el "id_usuario" a mano.

Las tablas ADMINISTRADOR, HORARIO y DISPONIBLEEN no participan directamente en el CRUD de reservas: HORARIO y DISPONIBLEEN describen la disponibilidad general de cada recurso, pero la reserva concreta registra su propia franja horaria con " hora_inicio" y "hora_fin".

---

## 2. Campos de la entidad RESERVA y su exposición en la API

La tabla RESERVA tiene 10 campos. No todos tienen sentido exponerlos en la API, así que los separo por casos.

Los campos que el cliente sí envía al crear una reserva son: id_recurso (para saber qué recurso quiere reservar), fecha, hora_inicio, hora_fin, numero_plazas, motivo y observaciones. Estos últimos dos son VARCHAR(20), así que tienen un límite corto de caracteres.

Hay dos campos que el backend genera solo y el cliente no necesita enviar. El coste lo calcula el backend según la duración de la reserva y la tarifa del recurso. El id_usuario lo saca del token JWT, como expliqué antes.

El id_reserva_local es la clave local que asigna la BBDD al crear la reserva. El cliente no lo envía, pero sí lo recibe en la respuesta y lo usa después para consultar, modificar o borrar esa reserva concreta.
En resumen, en el request solo van los datos que el usuario realmente conoce y decide. El resto lo pone el backend.

**Campos auto-generados por el backend:**

- "id_reserva_local":   gestionado por la BBDD dentro de cada recurso.
- "id_usuario": extraído del JWT; el cliente nunca lo envía.
- "coste": calculado por la lógica de negocio a partir de la duración y las tarifas del recurso.


**Campo adicional enriquecido en las respuestas (JOIN):**

En las respuestas GET y POST incluiré "recurso_nombre", obtenido con un JOIN sobre la tabla RECURSO. Así el cliente recibe "Sala de Reuniones A" en lugar de solo "id_recurso: 1".

----

## 3. Validaciones y reglas de negocio

**Campos obligatorios en el request (POST / PATCH):**

- "id_recurso", "fecha", "hora_inicio", "hora_fin", "numero_plazas"

**Restricciones de valores:**

- "hora_inicio" debe ser anterior a "hora_fin"
- "fecha" debe ser igual o posterior a la fecha actual (no se puede reservar en el pasado)
- "numero_plazas" debe ser mayor o igual a 1
- "numero_plazas" no puede superar la "capacidad" del recurso
- "motivo" tiene longitud máxima de 20 caracteres
- "observaciones" también tiene longitud máxima de 20 caracteres

**Reglas de negocio específicas del dominio:**

- No puede existir solapamiento de horarios para el mismo recurso en la misma fecha: si el recurso 1 ya tiene una reserva de 08:00 a 10:00 el día 2025-03-10, no se puede crear otra reserva que se solape en ese mismo recurso y día.
- Un RECURSO o USUARIONORMAL con reservas asociadas no puede eliminarse directamente (ON DELETE RESTRICT en la BBDD); la API devolverá un error 409 Conflict.

---

## 4. Ruta principal de la API

 
GET    /reservas              → Lista de reservas del usuario autenticado
POST   /reservas              → Crear una nueva reserva
GET    /reservas/{id}         → Detalle de una reserva por id_reserva_local
PATCH  /reservas/{id}         → Modificar una reserva existente
DELETE /reservas/{id}         → Eliminar una reserva
 

El parámetro  {id}  corresponde a  "id_reserva_local" . Aunque en la BBDD la PK es compuesta ( "id_recurso"  +  "id_reserva_local" ), a nivel de API se usa  "id_reserva_local" como identificador de ruta, ya que resulta más sencillo para el cliente y evita rutas añadidas innmecesarias.  El "id_recurso" se incluye en el body cuando es necesario.

## 5. Validación Swagger UI

![Validación Swagger Editor](/img/swagger-validacion.png)