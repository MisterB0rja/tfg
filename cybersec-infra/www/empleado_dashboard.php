<?php
session_start();

// Verificar si el usuario está autenticado y es un empleado
if (!isset($_SESSION['user_id']) || $_SESSION['user_type'] !== 'empleado') {
    header("Location: login.php");
    exit();
}

// Conexión a la base de datos
$db_host = '172.20.0.20';
$db_user = 'usuario_ciberseg';
$db_pass = 'hola12345';
$db_name = 'bd_ciberseg';

$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);

if ($conn->connect_error) {
    die("Error de conexión: " . $conn->connect_error);
}

// Obtener los clientes asignados al empleado
$empleado_id = $_SESSION['user_id'];
$stmt = $conn->prepare("
    SELECT c.id_cliente, c.nombre_empresa, c.contacto_nombre, c.contacto_email, c.contacto_telefono, a.fecha_asignacion
    FROM Clientes c
    JOIN Asignaciones a ON c.id_cliente = a.id_cliente
    WHERE a.id_empleado = ?
    ORDER BY a.fecha_asignacion DESC
");
$stmt->bind_param("i", $empleado_id);
$stmt->execute();
$clientes = $stmt->get_result();

$conn->close();
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Panel de Empleado - GuardianPYME</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <header>
        <h1>GuardianPYME</h1>
        <nav>
            <ul>
                <li><a href="empleado_dashboard.php">Panel</a></li>
                <li><a href="logout.php">Cerrar Sesión</a></li>
            </ul>
        </nav>
    </header>
    
    <main>
        <div class="dashboard">
            <div class="dashboard-header">
                <h2 class="dashboard-title">Bienvenido, <?php echo htmlspecialchars($_SESSION['user_name']); ?></h2>
            </div>
            
            <h3>Clientes Asignados</h3>
            
            <?php if ($clientes->num_rows > 0): ?>
                <table class="client-list">
                    <thead>
                        <tr>
                            <th>Empresa</th>
                            <th>Contacto</th>
                            <th>Email</th>
                            <th>Teléfono</th>
                            <th>Fecha Asignación</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php while ($cliente = $clientes->fetch_assoc()): ?>
                            <tr>
                                <td><?php echo htmlspecialchars($cliente['nombre_empresa']); ?></td>
                                <td><?php echo htmlspecialchars($cliente['contacto_nombre']); ?></td>
                                <td><?php echo htmlspecialchars($cliente['contacto_email']); ?></td>
                                <td><?php echo htmlspecialchars($cliente['contacto_telefono']); ?></td>
                                <td><?php echo $cliente['fecha_asignacion']; ?></td>
                            </tr>
                        <?php endwhile; ?>
                    </tbody>
                </table>
            <?php else: ?>
                <p>No tiene clientes asignados actualmente.</p>
            <?php endif; ?>
        </div>
    </main>
    
    <footer>
        <p>&copy; 2025 GuardianPYME. Todos los derechos reservados.</p>
    </footer>
</body>
</html>