CREATE DATABASE IF NOT EXISTS bd_ciberseg;
USE bd_ciberseg;

-- Tabla Clientes con credenciales de acceso
CREATE TABLE Clientes (
    id_cliente INT PRIMARY KEY AUTO_INCREMENT,
    nombre_empresa VARCHAR(100),
    contacto_nombre VARCHAR(100),
    contacto_email VARCHAR(100) UNIQUE,
    contacto_telefono VARCHAR(20),
    direccion TEXT,
    fecha_registro DATE,
    password VARCHAR(255),
    INDEX idx_contacto_email (contacto_email)
);

-- Tabla Empleados con credenciales de acceso
CREATE TABLE Empleados (
    id_empleado INT PRIMARY KEY AUTO_INCREMENT,
    nombre_completo VARCHAR(100),
    correo VARCHAR(100) UNIQUE,
    telefono VARCHAR(20),
    puesto VARCHAR(50),
    especialidad VARCHAR(100),
    fecha_contratacion DATE,
    password VARCHAR(255),
    INDEX idx_correo (correo)
);

-- Tabla de asignación de clientes a empleados
CREATE TABLE Asignaciones (
    id_asignacion INT PRIMARY KEY AUTO_INCREMENT,
    id_empleado INT,
    id_cliente INT,
    fecha_asignacion DATE,
    FOREIGN KEY (id_empleado) REFERENCES Empleados(id_empleado),
    FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente),
    INDEX idx_id_empleado (id_empleado),
    INDEX idx_id_cliente (id_cliente)
);

-- Tabla de Servicios/Paquetes
CREATE TABLE Servicios (
    id_servicio INT PRIMARY KEY AUTO_INCREMENT,
    nombre_servicio VARCHAR(100),
    descripcion TEXT,
    precio DECIMAL(10,2),
    duracion_estimada_dias INT
);

-- Insertar datos de ejemplo - Clientes
INSERT INTO Clientes (nombre_empresa, contacto_nombre, contacto_email, contacto_telefono, direccion, fecha_registro, password) VALUES
('Supermercados López', 'Carlos López', 'carlos@superlopez.es', '912345678', 'Calle Mayor 15, Madrid', '2023-01-15', 'cliente123'),
('Talleres Martínez', 'Ana Martínez', 'ana@talleresmartinez.es', '934567890', 'Avenida Industrial 45, Barcelona', '2023-02-20', 'cliente123'),
('Clínica Salud', 'Javier Rodríguez', 'javier@clinicasalud.es', '956789012', 'Plaza de la Salud 3, Sevilla', '2023-03-10', 'cliente123'),
('Restaurante El Rincón', 'María Fernández', 'maria@elrincon.es', '981234567', 'Calle Gourmet 8, Valencia', '2023-04-05', 'cliente123'),
('Constructora Edificar', 'Pedro Sánchez', 'pedro@edificar.es', '923456789', 'Avenida Constructor 22, Zaragoza', '2023-05-12', 'cliente123');

-- Insertar datos de ejemplo - Empleados
INSERT INTO Empleados (nombre_completo, correo, telefono, puesto, especialidad, fecha_contratacion, password) VALUES
('Laura Gómez', 'laura@ciberseguridad.es', '611223344', 'Analista de Seguridad', 'Pentesting', '2022-06-01', 'empleado123'),
('Miguel Torres', 'miguel@ciberseguridad.es', '622334455', 'Consultor Senior', 'Auditoría', '2022-07-15', 'empleado123'),
('Elena Navarro', 'elena@ciberseguridad.es', '633445566', 'Ingeniera de Sistemas', 'Redes', '2022-08-10', 'empleado123'),
('David Ruiz', 'david@ciberseguridad.es', '644556677', 'Especialista Forense', 'Análisis Forense', '2022-09-20', 'empleado123'),
('Carmen Ortiz', 'carmen@ciberseguridad.es', '655667788', 'Directora de Proyectos', 'Gestión', '2022-10-05', 'empleado123');

-- Asignar clientes a empleados
INSERT INTO Asignaciones (id_empleado, id_cliente, fecha_asignacion) VALUES
(1, 1, '2023-01-20'),
(1, 3, '2023-03-15'),
(2, 2, '2023-02-25'),
(3, 4, '2023-04-10'),
(4, 5, '2023-05-15'),
(5, 1, '2023-01-25'),
(2, 3, '2023-03-20'),
(3, 5, '2023-05-20');

-- Insertar servicios/paquetes
INSERT INTO Servicios (nombre_servicio, descripcion, precio, duracion_estimada_dias) VALUES
('Escaneo de Seguridad Automatizado', 'Implementación de escaneos de seguridad periódicos mediante Ansible. Incluye detección de puertos abiertos, vulnerabilidades y configuraciones inseguras.', 499.99, 30),
('Endurecimiento de Seguridad Windows', 'Aplicación de políticas de seguridad en sistemas Windows mediante PowerShell. Incluye configuración de contraseñas, firewall, BitLocker y más.', 799.99, 45),
('Diseño de Arquitectura de Red Segura', 'Diseño e implementación de una arquitectura de red segura para oficinas utilizando Cisco Packet Tracer. Incluye segmentación, firewalls y VLANs.', 1299.99, 60);