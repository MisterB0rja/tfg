<#
.SYNOPSIS
    Script de Endurecimiento de Seguridad para Windows
.DESCRIPTION
    Este script implementa las mejores prácticas de seguridad para sistemas Windows.
    Configura políticas de contraseñas, políticas de bloqueo de cuentas, deshabilita servicios
    vulnerables, habilita características de seguridad e implementa registro de auditoría.
.NOTES
    Nombre del Archivo : endurecimiento_seguridad_windows.ps1
    Autor             : Equipo de Ciberseguridad
    Requisito Previo  : PowerShell 5.1 o posterior
    Copyright         : Ciberseguridad Borja García
.EXAMPLE
    .\endurecimiento_seguridad_windows.ps1
#>

# Crear un archivo de registro
$ArchivoLog = "C:\Logs\EndurecimientoSeguridad_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$DirLog = Split-Path $ArchivoLog -Parent

# Crear directorio de registro si no existe
if (-not (Test-Path $DirLog)) {
    New-Item -Path $DirLog -ItemType Directory -Force | Out-Null
}

# Función para escribir en el archivo de registro
function Escribir-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Mensaje,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "ADVERTENCIA", "ERROR")]
        [string]$Nivel = "INFO"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $MensajeLog = "[$Timestamp] [$Nivel] $Mensaje"
    
    # Escribir en archivo de registro
    Add-Content -Path $ArchivoLog -Value $MensajeLog
    
    # También escribir en consola con código de color
    switch ($Nivel) {
        "INFO" { Write-Host $MensajeLog -ForegroundColor Green }
        "ADVERTENCIA" { Write-Host $MensajeLog -ForegroundColor Yellow }
        "ERROR" { Write-Host $MensajeLog -ForegroundColor Red }
    }
}

# Función para verificar si se ejecuta como administrador
function Test-Administrador {
    $usuarioActual = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $usuarioActual.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Verificar si se ejecuta como administrador
if (-not (Test-Administrador)) {
    Escribir-Log "Este script debe ejecutarse como Administrador. Por favor, reinicie PowerShell como Administrador." -Nivel "ERROR"
    exit 1
}

Escribir-Log "Iniciando Script de Endurecimiento de Seguridad para Windows" -Nivel "INFO"

# Crear una copia de seguridad de la configuración de seguridad actual
Escribir-Log "Creando copia de seguridad de la configuración de seguridad actual..." -Nivel "INFO"
$DirCopiaSeguridad = "C:\Backups\ConfiguracionSeguridad_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
if (-not (Test-Path $DirCopiaSeguridad)) {
    New-Item -Path $DirCopiaSeguridad -ItemType Directory -Force | Out-Null
}

# Copia de seguridad de las políticas de cuenta actuales
secedit /export /cfg "$DirCopiaSeguridad\secpol.cfg" | Out-Null
Escribir-Log "Copia de seguridad de política de seguridad creada en $DirCopiaSeguridad\secpol.cfg" -Nivel "INFO"

# Copia de seguridad de la configuración actual del firewall
netsh advfirewall export "$DirCopiaSeguridad\firewall.wfw" | Out-Null
Escribir-Log "Copia de seguridad de configuración del firewall creada en $DirCopiaSeguridad\firewall.wfw" -Nivel "INFO"

try {
    # 1. Política de Contraseñas: Longitud Mínima de Contraseña
    Escribir-Log "Estableciendo longitud mínima de contraseña a 12 caracteres..." -Nivel "INFO"
    net accounts /minpwlen:12
    
    # 2. Política de Contraseñas: Caducidad de Contraseña
    Escribir-Log "Estableciendo caducidad de contraseña a 90 días..." -Nivel "INFO"
    net accounts /maxpwage:90
    
    # 3. Política de Bloqueo de Cuenta
    Escribir-Log "Configurando política de bloqueo de cuenta..." -Nivel "INFO"
    net accounts /lockoutthreshold:5
    net accounts /lockoutduration:30
    net accounts /lockoutwindow:30
    
    # 4. Deshabilitar SMBv1
    Escribir-Log "Deshabilitando protocolo SMBv1..." -Nivel "INFO"
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
    
    # 5. Habilitar Firewall de Windows en Todos los Perfiles
    Escribir-Log "Habilitando Firewall de Windows para todos los perfiles..." -Nivel "INFO"
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
    
    # 6. Deshabilitar Cuenta de Administrador Local
    # Verificar si hay otra cuenta de administrador antes de deshabilitar
    $conteoAdmin = (Get-LocalGroupMember -Group "Administradores" | Measure-Object).Count
    if ($conteoAdmin -gt 1) {
        Escribir-Log "Deshabilitando cuenta de Administrador integrada..." -Nivel "INFO"
        Disable-LocalUser -Name "Administrador"
    } else {
        Escribir-Log "No se puede deshabilitar la cuenta de Administrador - es la única cuenta de administrador" -Nivel "ADVERTENCIA"
    }
    
    # 7. Habilitar UAC (Control de Cuentas de Usuario)
    Escribir-Log "Habilitando Control de Cuentas de Usuario (UAC)..." -Nivel "INFO"
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1
    
    # 8. Habilitar Registro de Auditoría de Inicio de Sesión
    Escribir-Log "Habilitando registro de auditoría de inicio de sesión..." -Nivel "INFO"
    auditpol /set /subcategory:"Logon" /success:enable /failure:enable
    auditpol /set /subcategory:"Logoff" /success:enable /failure:enable
    
    # 9. Deshabilitar AutoRun
    Escribir-Log "Deshabilitando AutoRun para todas las unidades..." -Nivel "INFO"
    if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Value 255
    
    # 10. Habilitar BitLocker en la Unidad del Sistema
    Escribir-Log "Verificando requisitos previos de BitLocker..." -Nivel "INFO"
    $tpm = Get-WmiObject -Namespace "root\cimv2\security\microsofttpm" -Class "Win32_Tpm"
    if ($tpm -and $tpm.IsEnabled().IsEnabled) {
        Escribir-Log "TPM está habilitado, intentando habilitar BitLocker..." -Nivel "INFO"
        try {
            $EstadoBL = Get-BitLockerVolume -MountPoint "C:"
            if ($EstadoBL.ProtectionStatus -eq "Off") {
                Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnlyEncryption -SkipHardwareTest
                Escribir-Log "BitLocker ha sido habilitado en la unidad del sistema" -Nivel "INFO"
            } else {
                Escribir-Log "BitLocker ya está habilitado en la unidad del sistema" -Nivel "INFO"
            }
        } catch {
            Escribir-Log "Error al habilitar BitLocker: $_" -Nivel "ERROR"
        }
    } else {
        Escribir-Log "TPM no está disponible o no está habilitado. BitLocker requiere TPM." -Nivel "ADVERTENCIA"
    }
    
    # Medidas de Seguridad Adicionales
    
    # 11. Deshabilitar Cuenta de Invitado
    Escribir-Log "Deshabilitando cuenta de Invitado..." -Nivel "INFO"
    Disable-LocalUser -Name "Invitado" -ErrorAction SilentlyContinue
    
    # 12. Deshabilitar Escritorio Remoto si no es necesario
    # Descomentar las siguientes líneas si desea deshabilitar RDP
    # Escribir-Log "Deshabilitando Escritorio Remoto..." -Nivel "INFO"
    # Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 1
    
    # 13. Habilitar Protección en Tiempo Real de Windows Defender
    Escribir-Log "Habilitando protección en tiempo real de Windows Defender..." -Nivel "INFO"
    Set-MpPreference -DisableRealtimeMonitoring $false
    
    # 14. Habilitar Protección Basada en la Nube de Windows Defender
    Escribir-Log "Habilitando protección basada en la nube de Windows Defender..." -Nivel "INFO"
    Set-MpPreference -MAPSReporting Advanced
    Set-MpPreference -SubmitSamplesConsent SendAllSamples
    
    # 15. Habilitar Acceso Controlado a Carpetas (Protección contra Ransomware)
    Escribir-Log "Habilitando Acceso Controlado a Carpetas..." -Nivel "INFO"
    Set-MpPreference -EnableControlledFolderAccess Enabled
    
    # 16. Deshabilitar PowerShell v2
    Escribir-Log "Deshabilitando PowerShell v2..." -Nivel "INFO"
    Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2 -NoRestart
    
    # 17. Habilitar Registro de Bloques de Script de PowerShell
    Escribir-Log "Habilitando Registro de Bloques de Script de PowerShell..." -Nivel "INFO"
    if (-not (Test-Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging")) {
        New-Item -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -Value 1
    
    # 18. Deshabilitar Autenticación WDigest (evita el almacenamiento en caché de credenciales)
    Escribir-Log "Deshabilitando Autenticación WDigest..." -Nivel "INFO"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" -Name "UseLogonCredential" -Value 0
    
    # 19. Habilitar LAPS (Solución de Contraseña de Administrador Local) si está instalado
    $lapsInstalado = Get-WmiObject -Query "select * from Win32_Product where Name like '%Local Administrator Password Solution%'"
    if ($lapsInstalado) {
        Escribir-Log "Configurando LAPS..." -Nivel "INFO"
        Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft Services\AdmPwd" -Name "AdmPwdEnabled" -Value 1 -ErrorAction SilentlyContinue
    } else {
        Escribir-Log "LAPS no está instalado. Considere instalarlo para una mejor gestión de contraseñas de administrador local." -Nivel "ADVERTENCIA"
    }
    
    # 20. Deshabilitar NetBIOS sobre TCP/IP
    Escribir-Log "Deshabilitando NetBIOS sobre TCP/IP..." -Nivel "INFO"
    $adaptadores = Get-WmiObject Win32_NetworkAdapterConfiguration
    foreach ($adaptador in $adaptadores) {
        if ($adaptador.IPEnabled) {
            $adaptador.SetTcpipNetbios(2) | Out-Null
        }
    }
    
    Escribir-Log "¡Endurecimiento de seguridad completado con éxito!" -Nivel "INFO"
    
} catch {
    Escribir-Log "Ocurrió un error durante el endurecimiento de seguridad: $_" -Nivel "ERROR"
}

# Mostrar resumen de cambios
Escribir-Log "Resumen de Endurecimiento de Seguridad:" -Nivel "INFO"
Escribir-Log "- Longitud mínima de contraseña: 12 caracteres" -Nivel "INFO"
Escribir-Log "- Caducidad de contraseña: 90 días" -Nivel "INFO"
Escribir-Log "- Umbral de bloqueo de cuenta: 5 intentos" -Nivel "INFO"
Escribir-Log "- Duración de bloqueo de cuenta: 30 minutos" -Nivel "INFO"
Escribir-Log "- Protocolo SMBv1: Deshabilitado" -Nivel "INFO"
Escribir-Log "- Firewall de Windows: Habilitado en todos los perfiles" -Nivel "INFO"
Escribir-Log "- Control de Cuentas de Usuario (UAC): Habilitado" -Nivel "INFO"
Escribir-Log "- Registro de auditoría de inicio de sesión: Habilitado" -Nivel "INFO"
Escribir-Log "- AutoRun: Deshabilitado" -Nivel "INFO"
Escribir-Log "- BitLocker: Intento de habilitación" -Nivel "INFO"

Escribir-Log "Se recomienda reiniciar el sistema para aplicar todos los cambios." -Nivel "INFO"
Escribir-Log "El archivo de registro se ha guardado en: $ArchivoLog" -Nivel "INFO"