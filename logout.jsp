<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
 logout.jsp - Cierra la sesion actual y redirige a login.jsp.
--%>
<%
  HttpSession sesion = request.getSession(false);
  if (sesion != null) {
    sesion.invalidate();
  }
  response.sendRedirect(request.getContextPath() + "/login.jsp");
%>