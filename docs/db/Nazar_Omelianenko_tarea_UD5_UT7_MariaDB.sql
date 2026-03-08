-- ======================================== 
--  PROYECTO INTERMODULAR  UD5 / UT7
--  Sistema de Reservas de Recursos
--  Autor: Nazar Omelianenko
--  SGBD: MariaDB (phpMyAdmin / XAMPP)
-- =========================== 


-- ====================================
-- PASO 1: ELIMINAMOS TABLAS (orden inverso por FK)
-- para poder ejecutar el script varias veces sin errores
--  =================================== 
DROP TABLE IF EXISTS RESERVA;
DROP TABLE IF EXISTS DISPONIBLEEN;
DROP TABLE IF EXISTS HORARIO;
DROP TABLE IF EXISTS RECURSO;
DROP TABLE IF EXISTS USUARIONORMAL;
DROP TABLE IF EXISTS ADMINISTRADOR;
DROP TABLE IF EXISTS USUARIO;


-- ========================================= 
-- PASO 2: CREAMOS TABLAS
-- ========================================== 

-- Tabla USUARIO (tabla base)

CREATE TABLE USUARIO (
    id_usuario          INT             NOT NULL,
    correo_electronico  VARCHAR(100)    NOT NULL,
    contrasena          VARCHAR(100)    NOT NULL,
    nombre              VARCHAR(100)    NOT NULL,
    fecha_nacimiento    DATE,
    tipo_usuario        ENUM('Administrador', 'Normal') NOT NULL,

    CONSTRAINT PK_USUARIO        PRIMARY KEY (id_usuario),
    CONSTRAINT UQ_USUARIO_correo UNIQUE (correo_electronico),
    CONSTRAINT UQ_USUARIO_nombre UNIQUE (nombre)
);

-- Tabla ADMINISTRADOR (hereda de USUARIO)
-- ON DELETE CASCADE: si se borra el USUARIO padre, se borra su fila de ADMINISTRADOR, un administrador no tiene sentido sin su usuario base.
-- ON UPDATE CASCADE: si cambia el id_usuario, se actualiza automáticamente aquí.

CREATE TABLE ADMINISTRADOR (
    id_usuario       INT          NOT NULL,
    telefono_guardia VARCHAR(20)  NOT NULL,

    CONSTRAINT PK_ADMINISTRADOR PRIMARY KEY (id_usuario),
    CONSTRAINT FK_ADMIN_USUARIO FOREIGN KEY (id_usuario)
        REFERENCES USUARIO(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Tabla USUARIONORMAL (hereda de USUARIO)
-- ON DELETE CASCADE: si se borra el USUARIO padre, se borra su perfil normal, el perfil depende completamente del usuario base
 
CREATE TABLE USUARIONORMAL (
    id_usuario     INT          NOT NULL,
    direccion      VARCHAR(200),
    telefono_movil VARCHAR(20),
    fotografia     VARCHAR(255),

    CONSTRAINT PK_USUARIONORMAL   PRIMARY KEY (id_usuario),
    CONSTRAINT FK_USRNORM_USUARIO FOREIGN KEY (id_usuario)
        REFERENCES USUARIO(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Tabla RECURSO
CREATE TABLE RECURSO (
    id_recurso  INT          NOT NULL,
    nombre      VARCHAR(100) NOT NULL,
    descripcion VARCHAR(100),
    ubicacion   VARCHAR(200),
    capacidad   INT,

    CONSTRAINT PK_RECURSO PRIMARY KEY (id_recurso)
);

-- Tabla HORARIO
 
CREATE TABLE HORARIO (
    id_horario  INT         NOT NULL,
    dia_semana  ENUM('Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo') NOT NULL,
    hora_inicio TIME        NOT NULL,
    hora_fin    TIME        NOT NULL,

    CONSTRAINT PK_HORARIO PRIMARY KEY (id_horario)
);

-- Tabla DISPONIBLEEN (relación N:M entre RECURSO y HORARIO)
-- ON DELETE CASCADE en ambas FK: si desaparece el recurso o el horario,la disponibilidad deja de tener sentido y se elimina automáticamente

CREATE TABLE DISPONIBLEEN (
    id_recurso INT NOT NULL,
    id_horario INT NOT NULL,

    CONSTRAINT PK_DISPONIBLEEN PRIMARY KEY (id_recurso, id_horario),
    CONSTRAINT FK_DISP_RECURSO FOREIGN KEY (id_recurso)
        REFERENCES RECURSO(id_recurso)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT FK_DISP_HORARIO FOREIGN KEY (id_horario)
        REFERENCES HORARIO(id_horario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Tabla RESERVA (PK compuesta: id_recurso + id_reserva_local)
-- ON DELETE RESTRICT (por defecto): no se puede borrar un RECURSO o USUARIO
-- que tenga reservas asociadas. 
-- se obliga a gestionar las reservas antes de eliminar el recurso/usuario.
-- ON UPDATE CASCADE: si cambia el id, se propaga para mantener consistencia.

CREATE TABLE RESERVA (
    id_recurso       INT            NOT NULL,
    id_reserva_local INT            NOT NULL,
    id_usuario       INT            NOT NULL,
    fecha            DATE           NOT NULL,
    hora_inicio      TIME           NOT NULL,
    hora_fin         TIME           NOT NULL,
    coste            DECIMAL(10,2),
    numero_plazas    INT,
    motivo           VARCHAR(20),
    observaciones    VARCHAR(20),

    CONSTRAINT PK_RESERVA         PRIMARY KEY (id_recurso, id_reserva_local),
    CONSTRAINT FK_RESERVA_RECURSO FOREIGN KEY (id_recurso)
        REFERENCES RECURSO(id_recurso)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT FK_RESERVA_USUARIO FOREIGN KEY (id_usuario)
        REFERENCES USUARIONORMAL(id_usuario)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


-- =============================
-- PASO 3: INTRODUCIMOS LOS DATOS (5 filas por tabla)
-- ============================ 

-- USUARIO (8 normales + 2 admins extra para cubrir 5 en ADMINISTRADOR)

INSERT INTO USUARIO VALUES (1,  'nazar@correo.com',   'pass123', 'Nazar Omelianenko', '1985-10-24', 'Administrador');
INSERT INTO USUARIO VALUES (2,  'admin2@correo.com',  'pass456', 'Laura Martínez',    '1988-07-22', 'Administrador');
INSERT INTO USUARIO VALUES (3,  'admin3@correo.com',  'pass789', 'Carlos Ruiz',       '1990-11-05', 'Administrador');
INSERT INTO USUARIO VALUES (4,  'normal1@correo.com', 'pass111', 'Ana García',        '1998-01-10', 'Normal');
INSERT INTO USUARIO VALUES (5,  'normal2@correo.com', 'pass222', 'Pedro López',       '2000-05-20', 'Normal');
INSERT INTO USUARIO VALUES (6,  'normal3@correo.com', 'pass333', 'María Sánchez',     '1997-09-30', 'Normal');
INSERT INTO USUARIO VALUES (7,  'normal4@correo.com', 'pass444', 'Luis Torres',       '2001-12-01', 'Normal');
INSERT INTO USUARIO VALUES (8,  'normal5@correo.com', 'pass555', 'Elena Gómez',       '1999-06-15', 'Normal');
INSERT INTO USUARIO VALUES (9,  'admin4@correo.com',  'pass901', 'Sofía Navarro',     '1993-04-18', 'Administrador');
INSERT INTO USUARIO VALUES (10, 'admin5@correo.com',  'pass902', 'Marcos Jiménez',    '1985-08-25', 'Administrador');

-- ADMINISTRADOR (5 filas, 5 usuarios administradores)

INSERT INTO ADMINISTRADOR VALUES (1,  '600111222');
INSERT INTO ADMINISTRADOR VALUES (2,  '600333444');
INSERT INTO ADMINISTRADOR VALUES (3,  '600555666');
INSERT INTO ADMINISTRADOR VALUES (9,  '600777888');
INSERT INTO ADMINISTRADOR VALUES (10, '600999000');

-- USUARIONORMAL (5 filas)
INSERT INTO USUARIONORMAL VALUES (4, 'Calle Mayor 1, Madrid',     '612000001', 'foto_ana.jpg');
INSERT INTO USUARIONORMAL VALUES (5, 'Av. Libertad 23, Valencia', '612000002', 'foto_pedro.jpg');
INSERT INTO USUARIONORMAL VALUES (6, 'Plaza España 5, Sevilla',   '612000003', NULL);
INSERT INTO USUARIONORMAL VALUES (7, 'C/ Rambla 10, Barcelona',   '612000004', 'foto_luis.jpg');
INSERT INTO USUARIONORMAL VALUES (8, 'C/ Sol 7, Murcia',          '612000005', NULL);

-- RECURSO (5 filas)

INSERT INTO RECURSO VALUES (1, 'Sala de Reuniones A', 'Sala con proyector',       'Planta 1 - Edificio A', 10);
INSERT INTO RECURSO VALUES (2, 'Gimnasio',            'Equipamiento deportivo',   'Planta Baja',           30);
INSERT INTO RECURSO VALUES (3, 'Sala de Conferencias','Auditorio principal',      'Planta 2',             100);
INSERT INTO RECURSO VALUES (4, 'Pista de Pádel',      'Pista cubierta',           'Exterior Norte',         4);
INSERT INTO RECURSO VALUES (5, 'Sala de Estudio',     'Zona silenciosa con WiFi', 'Planta 1 - Edificio B', 20);

-- HORARIO (5 filas)

INSERT INTO HORARIO VALUES (1, 'Lunes',      '08:00', '10:00');
INSERT INTO HORARIO VALUES (2, 'Miércoles',  '10:00', '12:00');
INSERT INTO HORARIO VALUES (3, 'Viernes',    '16:00', '18:00');
INSERT INTO HORARIO VALUES (4, 'Sábado',     '09:00', '11:00');
INSERT INTO HORARIO VALUES (5, 'Domingo',    '11:00', '13:00');

-- DISPONIBLEEN (5 filas)

INSERT INTO DISPONIBLEEN VALUES (1, 1);
INSERT INTO DISPONIBLEEN VALUES (1, 2);
INSERT INTO DISPONIBLEEN VALUES (2, 3);
INSERT INTO DISPONIBLEEN VALUES (3, 4);
INSERT INTO DISPONIBLEEN VALUES (4, 5);

-- RESERVA (5 filas; Ana -id=4- hace 2 reservas para demostrar cardinalidad)
INSERT INTO RESERVA VALUES (1, 1, 4, '2025-03-10', '08:00', '10:00', 15.00, 5,  'Reunión',      NULL);
INSERT INTO RESERVA VALUES (1, 2, 4, '2025-03-17', '08:00', '10:00', 15.00, 5,  'Reunión',      'Repetición');
INSERT INTO RESERVA VALUES (2, 1, 5, '2025-03-11', '16:00', '18:00',  0.00, 2,  'Entreno',      NULL);
INSERT INTO RESERVA VALUES (3, 1, 6, '2025-03-12', '10:00', '12:00', 50.00, 80, 'Conferencia',  NULL);
INSERT INTO RESERVA VALUES (4, 1, 7, '2025-03-13', '09:00', '11:00', 10.00, 2,  'Pádel',        NULL);


