<?php
session_start();

// Si ya hay una sesión activa, redirigir según el tipo de usuario
if (isset($_SESSION['user_id'])) {
    if ($_SESSION['user_type'] === 'cliente') {
        header("Location: cliente_dashboard.php");
        exit();
    } elseif ($_SESSION['user_type'] === 'empleado') {
        header("Location: empleado_dashboard.php");
        exit();
    }
}

$error = '';

// Procesar el formulario de login
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Conexión a la base de datos
    $db_host = '172.20.0.20';
    $db_user = 'usuario_ciberseg';
    $db_pass = 'contraseña_ciberseg';
    $db_name = 'bd_ciberseg';

    $conn = new mysqli($db_host, $db_user, $db_pass, $db_name);

    if ($conn->connect_error) {
        die("Error de conexión: " . $conn->connect_error);
    }

    $email = filter_var($_POST['email'], FILTER_SANITIZE_EMAIL);
    $password = $_POST['password'];
    
    // Verificar si es un cliente
    $stmt = $conn->prepare("SELECT id_cliente, contacto_nombre, password FROM Clientes WHERE contacto_email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 1) {
        $row = $result->fetch_assoc();
        if ($password === $row['password']) { // En producción usar password_verify()
            $_SESSION['user_id'] = $row['id_cliente'];
            $_SESSION['user_name'] = $row['contacto_nombre'];
            $_SESSION['user_type'] = 'cliente';
            header("Location: cliente_dashboard.php");
            exit();
        } else {
            $error = "Contraseña incorrecta";
        }
    } else {
        // Verificar si es un empleado
        $stmt = $conn->prepare("SELECT id_empleado, nombre_completo, password FROM Empleados WHERE correo = ?");
        $stmt->bind_param("s", $email);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 1) {
            $row = $result->fetch_assoc();
            if ($password === $row['password']) { // En producción usar password_verify()
                $_SESSION['user_id'] = $row['id_empleado'];
                $_SESSION['user_name'] = $row['nombre_completo'];
                $_SESSION['user_type'] = 'empleado';
                header("Location: empleado_dashboard.php");
                exit();
            } else {
                $error = "Contraseña incorrecta";
            }
        } else {
            $error = "Usuario no encontrado";
        }
    }
    
    $conn->close();
}
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Acceso - CiberProtect</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <header>
        <h1>CiberProtect</h1>
        <nav>
            <ul>
                <li><a href="index.html">Inicio</a></li>
                <li><a href="login.php">Acceso</a></li>
            </ul>
        </nav>
    </header>
    
    <main>
        <div class="form-container">
            <h2 class="form-title">Acceso a su cuenta</h2>
            
            <?php if (!empty($error)): ?>
                <div class="error-message" style="color: red; text-align: center; margin-bottom: 15px;">
                    <?php echo $error; ?>
                </div>
            <?php endif; ?>
            
            <form action="login.php" method="post">
                <div class="form-group">
                    <label for="email">Correo electrónico</label>
                    <input type="email" id="email" name="email" required>
                </div>
                
                <div class="form-group">
                    <label for="password">Contraseña</label>
                    <input type="password" id="password" name="password" required>
                </div>
                
                <div class="form-group">
                    <button type="submit" class="btn" style="width: 100%;">Acceder</button>
                </div>
            </form>
            
            <div class="form-footer">
                <p>¿Olvidó su contraseña? Contacte con soporte.</p>
            </div>
        </div>
    </main>
    
    <footer>
        <p>&copy; 2025 CiberProtect. Todos los derechos reservados.</p>
    </footer>
</body>
</html>