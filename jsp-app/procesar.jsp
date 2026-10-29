<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.util.*" %>
<%!
private String escapeHtml(Object value) {
    if (value == null) return "";
    return value.toString()
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace("\"", "&quot;")
        .replace("'", "&#39;");
}
%>
<%
request.setCharacterEncoding("UTF-8");
boolean postRequest = "POST".equalsIgnoreCase(request.getMethod());
String nombre = request.getParameter("nombre");
String correo = request.getParameter("correo");
String telefono = request.getParameter("telefono");
String empresa = request.getParameter("empresa");
String mensaje = request.getParameter("mensaje");

nombre = nombre == null ? "" : nombre.trim();
correo = correo == null ? "" : correo.trim();
telefono = telefono == null ? "" : telefono.trim();
empresa = empresa == null ? "" : empresa.trim();
mensaje = mensaje == null ? "" : mensaje.trim();

List<String> errores = new ArrayList<String>();
if (!postRequest) {
    response.setStatus(405);
    response.setHeader("Allow", "POST");
} else {
    if (nombre.isEmpty() || nombre.length() > 80) {
        errores.add("El nombre es obligatorio y no debe exceder 80 caracteres.");
    }
    if (correo.isEmpty() || correo.length() > 254 || !correo.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) {
        errores.add("Ingresa un correo electrónico válido (máximo 254 caracteres).");
    }
    if (!telefono.isEmpty() && (telefono.length() > 20 || !telefono.matches("^[+()0-9 .-]{7,20}$"))) {
        errores.add("El teléfono debe tener entre 7 y 20 caracteres válidos.");
    }
    if (empresa.length() > 80) {
        errores.add("La empresa no debe exceder 80 caracteres.");
    }
    if (mensaje.length() > 500) {
        errores.add("La nota no debe exceder 500 caracteres.");
    }
    if (!errores.isEmpty()) {
        response.setStatus(422);
    } else {
        Object almacenados = session.getAttribute("registros");
        List<Object> registros = new ArrayList<Object>();
        if (almacenados instanceof List<?>) {
            registros.addAll((List<?>) almacenados);
        }

        Map<String, String> registro = new LinkedHashMap<String, String>();
        registro.put("nombre", nombre);
        registro.put("correo", correo);
        registro.put("telefono", telefono);
        registro.put("empresa", empresa);
        registro.put("mensaje", mensaje);
        registro.put("fecha", new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new java.util.Date()));
        registros.add(registro);
        if (registros.size() > 100) {
            registros = new ArrayList<Object>(registros.subList(registros.size() - 100, registros.size()));
        }
        session.setAttribute("registros", registros);
    }
}
%>
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><%= postRequest && errores.isEmpty() ? "Contacto guardado" : "Revisar solicitud" %> | Registro de contacto</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <main class="result-shell">
    <header class="site-header">
      <a class="wordmark" href="index.html">
        <span class="wordmark-mark" aria-hidden="true">RC</span>
        <span>Registro<span class="wordmark-light">Contacto</span></span>
      </a>
      <span class="environment"><span class="status-dot"></span> Implementación JSP</span>
    </header>

    <section class="result-main">
<% if (!postRequest) { %>
      <p class="eyebrow">SOLICITUD NO VÁLIDA</p>
      <div class="result-card">
        <h1 class="result-error">Método no permitido.</h1>
        <p class="result-copy">Este endpoint solo acepta solicitudes POST desde el formulario.</p>
        <a class="secondary-link" href="index.html">Volver al formulario →</a>
      </div>
<% } else if (!errores.isEmpty()) { %>
      <p class="eyebrow">VALIDACIÓN DEL FORMULARIO</p>
      <div class="result-card">
        <h1 class="result-error">Revisa los datos.</h1>
        <p class="result-copy">No se guardó el contacto:</p>
        <ul class="result-list">
<% for (String error : errores) { %>
          <li><%= escapeHtml(error) %></li>
<% } %>
        </ul>
        <a class="secondary-link" href="index.html">Volver y corregir →</a>
      </div>
<% } else {
    Object almacenados = session.getAttribute("registros");
    List<?> registros = almacenados instanceof List<?> ? (List<?>) almacenados : Collections.emptyList();
%>
      <p class="eyebrow">REGISTRO COMPLETADO <span>·</span> JSP</p>
      <div class="result-card">
        <h1 class="result-success">Contacto guardado.</h1>
        <p class="result-copy">El registro se agregó a la sesión actual. Aquí puedes revisar los contactos de esta sesión.</p>
        <div class="table-wrap">
          <table class="records-table">
            <thead><tr><th>Nombre</th><th>Correo</th><th>Teléfono</th><th>Empresa</th><th>Nota</th><th>Fecha</th></tr></thead>
            <tbody>
<% for (Object item : registros) {
    if (!(item instanceof Map<?, ?>)) continue;
    Map<?, ?> fila = (Map<?, ?>) item;
    String[] claves = {"nombre", "correo", "telefono", "empresa", "mensaje", "fecha"};
%>
              <tr>
<% for (String clave : claves) {
    Object valor = fila.get(clave);
    String texto = valor == null ? "" : valor.toString();
%>
                <td<%= texto.isEmpty() ? " class=\"muted-cell\"" : "" %>><%= texto.isEmpty() ? "—" : escapeHtml(texto) %></td>
<% } %>
              </tr>
<% } %>
            </tbody>
          </table>
        </div>
        <div class="result-actions">
          <a class="secondary-link" href="index.html">＋ Registrar otro contacto</a>
          <span class="count-label"><%= registros.size() %> de 100 contactos en esta sesión</span>
        </div>
      </div>
<% } %>
    </section>

    <footer class="page-footer">
      <span>Los datos se conservan solo durante esta sesión.</span>
      <span>Laboratorio 09 <span class="footer-divider">/</span> JSP</span>
    </footer>
  </main>
</body>
</html>
