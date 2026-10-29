<?php
declare(strict_types=1);

header('Content-Type: text/html; charset=UTF-8');

function h(string $value): string
{
    return htmlspecialchars($value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function field(string $name): string
{
    $value = $_POST[$name] ?? '';
    return is_string($value) ? trim($value) : '';
}

function characterLength(string $value): int
{
    $length = preg_match_all('/./us', $value);
    return $length === false ? PHP_INT_MAX : $length;
}

function pageStart(string $title): void
{
    echo '<!doctype html><html lang="es"><head><meta charset="utf-8">';
    echo '<meta name="viewport" content="width=device-width, initial-scale=1">';
    echo '<title>' . h($title) . ' | Registro de contacto</title>';
    echo '<link rel="stylesheet" href="style.css"></head><body>';
    echo '<main class="result-shell"><header class="site-header">';
    echo '<a class="wordmark" href="index.html"><span class="wordmark-mark" aria-hidden="true">RC</span>';
    echo '<span>Registro<span class="wordmark-light">Contacto</span></span></a>';
    echo '<span class="environment"><span class="status-dot"></span> Implementación PHP</span>';
    echo '</header><section class="result-main">';
}

function pageEnd(): void
{
    echo '</section><footer class="page-footer"><span>Los datos se conservan solo durante esta sesión.</span>';
    echo '<span>Laboratorio 09 <span class="footer-divider">/</span> PHP</span></footer></main></body></html>';
}

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    http_response_code(405);
    header('Allow: POST');
    pageStart('Método no permitido');
    echo '<p class="eyebrow">SOLICITUD NO VÁLIDA</p><div class="result-card">';
    echo '<h1 class="result-error">Método no permitido.</h1>';
    echo '<p class="result-copy">Este endpoint solo acepta solicitudes POST desde el formulario.</p>';
    echo '<a class="secondary-link" href="index.html">Volver al formulario →</a></div>';
    pageEnd();
    exit;
}

$https = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== '' && $_SERVER['HTTPS'] !== 'off';
session_set_cookie_params([
    'httponly' => true,
    'secure' => $https,
    'samesite' => 'Lax',
]);

if (!session_start()) {
    http_response_code(500);
    pageStart('Error interno');
    echo '<p class="eyebrow">ERROR DEL SERVIDOR</p><div class="result-card">';
    echo '<h1 class="result-error">No se pudo iniciar la sesión.</h1>';
    echo '<p class="result-copy">Intenta nuevamente más tarde.</p></div>';
    pageEnd();
    exit;
}

$nombre = field('nombre');
$correo = field('correo');
$telefono = field('telefono');
$empresa = field('empresa');
$mensaje = field('mensaje');
$errores = [];

if ($nombre === '' || characterLength($nombre) > 80) {
    $errores[] = 'El nombre es obligatorio y no debe exceder 80 caracteres.';
}
if ($correo === '' || strlen($correo) > 254 || filter_var($correo, FILTER_VALIDATE_EMAIL) === false) {
    $errores[] = 'Ingresa un correo electrónico válido (máximo 254 caracteres).';
}
if ($telefono !== '' && (strlen($telefono) > 20 || !preg_match('/^[+()0-9 .-]{7,20}$/', $telefono))) {
    $errores[] = 'El teléfono debe tener entre 7 y 20 caracteres válidos.';
}
if (characterLength($empresa) > 80) {
    $errores[] = 'La empresa no debe exceder 80 caracteres.';
}
if (characterLength($mensaje) > 500) {
    $errores[] = 'La nota no debe exceder 500 caracteres.';
}

if ($errores !== []) {
    http_response_code(422);
    pageStart('Revisa los datos');
    echo '<p class="eyebrow">VALIDACIÓN DEL FORMULARIO</p><div class="result-card">';
    echo '<h1 class="result-error">Revisa los datos.</h1><p class="result-copy">No se guardó el contacto:</p><ul class="result-list">';
    foreach ($errores as $error) {
        echo '<li>' . h($error) . '</li>';
    }
    echo '</ul><a class="secondary-link" href="index.html">Volver y corregir →</a></div>';
    pageEnd();
    exit;
}

$registro = [
    'nombre' => $nombre,
    'correo' => $correo,
    'telefono' => $telefono,
    'empresa' => $empresa,
    'mensaje' => $mensaje,
    'fecha' => date('Y-m-d H:i:s'),
];

if (!isset($_SESSION['registros']) || !is_array($_SESSION['registros'])) {
    $_SESSION['registros'] = [];
}
$_SESSION['registros'][] = $registro;
$_SESSION['registros'] = array_slice($_SESSION['registros'], -100);
$registros = $_SESSION['registros'];

pageStart('Contacto guardado');
echo '<p class="eyebrow">REGISTRO COMPLETADO <span>·</span> PHP</p>';
echo '<div class="result-card"><h1 class="result-success">Contacto guardado.</h1>';
echo '<p class="result-copy">El registro se agregó a la sesión actual. Aquí puedes revisar los contactos de esta sesión.</p>';
echo '<div class="table-wrap"><table class="records-table"><thead><tr>';
echo '<th>Nombre</th><th>Correo</th><th>Teléfono</th><th>Empresa</th><th>Nota</th><th>Fecha</th>';
echo '</tr></thead><tbody>';
foreach ($registros as $item) {
    if (!is_array($item)) {
        continue;
    }
    echo '<tr>';
    foreach (['nombre', 'correo', 'telefono', 'empresa', 'mensaje', 'fecha'] as $key) {
        $value = isset($item[$key]) && is_string($item[$key]) ? $item[$key] : '';
        echo '<td' . ($value === '' ? ' class="muted-cell"' : '') . '>' . ($value === '' ? '—' : h($value)) . '</td>';
    }
    echo '</tr>';
}
echo '</tbody></table></div>';
echo '<div class="result-actions"><a class="secondary-link" href="index.html">＋ Registrar otro contacto</a>';
echo '<span class="count-label">' . count($registros) . ' de 100 contactos en esta sesión</span></div></div>';
pageEnd();
