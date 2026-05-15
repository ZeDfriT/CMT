# ================================================
# CleanNTB.ps1
# Corporate Maintenance Tool
# Version: 1.1
# ================================================

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

$LogFile   = 'C:\Maintenance.log'
$StartTime = Get-Date
$Before    = [math]::Round((Get-PSDrive C).Free / 1GB, 2)

function Log($Message) {

    $TimeStamp = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"

    Write-Host $TimeStamp

    try {
        Add-Content -Path $LogFile -Value $TimeStamp
    }
    catch {}
}

Log "================================================"
Log "CORPORATE MAINTENANCE TOOL"
Log "================================================"

# =================================================
# CERRAR NAVEGADORES
# =================================================

Log "[1/9] Cerrando Google Chrome y Microsoft Edge..."

Stop-Process -Name chrome -Force
Stop-Process -Name msedge -Force

Log "[1/9] REALIZADO"

# =================================================
# LIMPIEZA TEMP WINDOWS
# =================================================

Log "[2/9] Limpiando archivos temporales de Windows..."

Remove-Item "$env:TEMP\*" -Recurse -Force
Remove-Item "C:\Windows\Temp\*" -Recurse -Force

Log "[2/9] REALIZADO"

# =================================================
# DETECTAR USUARIO LOGUEADO
# =================================================

$UserProfile = (Get-CimInstance Win32_ComputerSystem).UserName.Split('\')[1]
$UserPath = "C:\Users\$UserProfile"

# =================================================
# LIMPIEZA CACHE CHROME
# =================================================

Log "[3/9] Limpiando caché de Google Chrome..."

Remove-Item "$UserPath\AppData\Local\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force
Remove-Item "$UserPath\AppData\Local\Google\Chrome\User Data\Default\Code Cache\*" -Recurse -Force
Remove-Item "$UserPath\AppData\Local\Google\Chrome\User Data\Default\GPUCache\*" -Recurse -Force

Log "[3/9] REALIZADO"

# =================================================
# LIMPIEZA CACHE EDGE
# =================================================

Log "[4/9] Limpiando caché de Microsoft Edge..."

Remove-Item "$UserPath\AppData\Local\Microsoft\Edge\User Data\Default\Cache\*" -Recurse -Force
Remove-Item "$UserPath\AppData\Local\Microsoft\Edge\User Data\Default\Code Cache\*" -Recurse -Force
Remove-Item "$UserPath\AppData\Local\Microsoft\Edge\User Data\Default\GPUCache\*" -Recurse -Force

Log "[4/9] REALIZADO"

# =================================================
# LIMPIEZA THUMBNAIL CACHE
# =================================================

Log "[5/9] Limpiando Thumbnail Cache..."

Remove-Item "$UserPath\AppData\Local\Microsoft\Windows\Explorer\thumbcache_*.db" -Force

Log "[5/9] REALIZADO"

# =================================================
# LIMPIEZA PAPELERA
# =================================================

Log "[6/9] Limpiando Papelera de reciclaje..."

Clear-RecycleBin -Force

Log "[6/9] REALIZADO"

# =================================================
# LIMPIEZA WINDOWS UPDATE CACHE
# =================================================

Log "[7/9] Limpiando cache de Windows Update..."

Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force

Log "[7/9] REALIZADO"

# =================================================
# UPDATE GOOGLE CHROME
# =================================================

Log "[8/9] Verificando actualización de Google Chrome..."

if (Test-Path "${env:ProgramFiles(x86)}\Google\Update\GoogleUpdate.exe") {

    Start-Process `
        "${env:ProgramFiles(x86)}\Google\Update\GoogleUpdate.exe" `
        -ArgumentList '/ua /installsource scheduler' `
        -Wait
}

Log "[8/9] REALIZADO"

# =================================================
# MICROSOFT UPDATE ONLINE SCAN
# =================================================

Log "[9/9] Buscando actualizaciones online de Microsoft..."

$ServiceManager = New-Object -ComObject Microsoft.Update.ServiceManager

$null = $ServiceManager.AddService2(
    '7971f918-a847-4430-9279-4a52d1efe18d',
    7,
    ''
)

UsoClient StartScan

Log "[9/9] REALIZADO"

# =================================================
# RESULTADOS
# =================================================

$After = [math]::Round((Get-PSDrive C).Free / 1GB, 2)

$Recovered = [math]::Round($After - $Before, 2)

$Duration = (
    (Get-Date) - $StartTime
).ToString("mm' min 'ss' seg'")

Log " "
Log "Espacio recuperado: $Recovered GB"
Log "Tiempo total: $Duration"
Log "MANTENIMIENTO FINALIZADO"

# =================================================
# POPUP CORPORATIVO
# =================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$LogoUrl  = "https://i.imgur.com/jyK331E.jpeg"
$LogoPath = "$env:TEMP\primary_logo.jpg"

try {
    Invoke-WebRequest -Uri $LogoUrl -OutFile $LogoPath
}
catch {}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Primary Service Desk"
$form.Size = New-Object System.Drawing.Size(420,320)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::White

# =================================================
# LOGO
# =================================================

if (Test-Path $LogoPath) {

    $pictureBox = New-Object System.Windows.Forms.PictureBox
    $pictureBox.Image = [System.Drawing.Image]::FromFile($LogoPath)
    $pictureBox.SizeMode = "Zoom"
    $pictureBox.Location = New-Object System.Drawing.Point(110,10)
    $pictureBox.Size = New-Object System.Drawing.Size(180,80)

    $form.Controls.Add($pictureBox)
}

# =================================================
# TITULO
# =================================================

$title = New-Object System.Windows.Forms.Label
$title.Text = "Primary Service Desk"
$title.Font = New-Object System.Drawing.Font("Segoe UI",14,[System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(95,95)

$form.Controls.Add($title)

# =================================================
# MENSAJE
# =================================================

$message = New-Object System.Windows.Forms.Label
$message.Text = @"
Mantenimiento finalizado correctamente.

Puede volver a utilizar la notebook.

Espacio recuperado: $Recovered GB

Se recomienda reiniciar el equipo.
"@

$message.Font = New-Object System.Drawing.Font("Segoe UI",10)
$message.AutoSize = $true
$message.Location = New-Object System.Drawing.Point(55,140)

$form.Controls.Add($message)

# =================================================
# BOTON OK
# =================================================

$button = New-Object System.Windows.Forms.Button
$button.Text = "OK"
$button.Width = 100
$button.Height = 35
$button.Location = New-Object System.Drawing.Point(150,230)

$button.Add_Click({
    $form.Close()
})

$form.Controls.Add($button)

# =================================================
# MOSTRAR VENTANA
# =================================================

$form.Add_Shown({
    $form.Activate()
})

[void]$form.ShowDialog()

# =================================================
# LIMPIEZA
# =================================================

Remove-Item $LogoPath -Force
