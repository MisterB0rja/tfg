<?php
session_start();

// Verificar si el usuario está autenticado y es un cliente
if (!isset($_SESSION['user_id']) || $_SESSION['user_type'] !== 'cliente') {
    header("Location: login.php");
    exit();
}

// Conexión a la base de datos
$db_host = '172.20.0.20';
$db_user = 'usuario_ciberseg';
$db_pass = 'contraseña_ciberseg';
$db_name = 'bd_ciberseg';

$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);

if ($conn->connect_error) {
    die("Error de conexión: " . $conn->connect_error);
}

// Obtener información de los servicios/paquetes
$stmt = $conn->prepare("SELECT * FROM Servicios");
$stmt->execute();
$servicios = $stmt->get_result();

$conn->close();
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Panel de Cliente - CiberProtect</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <header>
        <h1>CiberProtect</h1>
        <nav>
            <ul>
                <li><a href="cliente_dashboard.php">Panel</a></li>
                <li><a href="logout.php">Cerrar Sesión</a></li>
            </ul>
        </nav>
    </header>
    
    <main>
        <div class="dashboard">
            <div class="dashboard-header">
                <h2 class="dashboard-title">Bienvenido, <?php echo htmlspecialchars($_SESSION['user_name']); ?></h2>
            </div>
            
            <h3>Nuestros Paquetes de Servicios</h3>
            <p>Seleccione el paquete que mejor se adapte a las necesidades de su empresa:</p>
            
            <div class="package-container">
                <?php while ($servicio = $servicios->fetch_assoc()): ?>
                <div class="package-card">
                    <h3 class="package-title"><?php echo htmlspecialchars($servicio['nombre_servicio']); ?></h3>
                    <p class="package-price"><?php echo number_format($servicio['precio'], 2); ?> €</p>
                    <p class="package-description"><?php echo htmlspecialchars($servicio['descripcion']); ?></p>
                    <p><strong>Duración estimada:</strong> <?php echo $servicio['duracion_estimada_dias']; ?> días</p>
                    <a href="#" class="btn">Solicitar información</a>
                </div>
                <?php endwhile; ?>
            </div>
        </div>
    </main>
    
    <footer>
        <p>&copy; 2025 CiberProtect. Todos los derechos reservados.</p>
    </footer>
</body>
</html>