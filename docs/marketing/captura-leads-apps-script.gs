/**
 * CAPTURA DE LEADS Y MÉTRICAS — Google Apps Script
 * =================================================
 * Recibe los eventos de la landing (WhatsApp clicks, formularios) y los
 * escribe como filas en un Google Sheet. Gratuito, sin servidor propio.
 *
 * ACTIVACIÓN (10 minutos, una sola vez):
 *  1. Crear un Google Sheet nuevo (ej. "GV Academy — Leads y métricas").
 *  2. Menú Extensiones → Apps Script: borrar el contenido y pegar ESTE archivo.
 *  3. Deploy → New deployment → tipo "Web app":
 *       - Execute as: Me
 *       - Who has access: Anyone
 *     → Approve permisos → copiar la URL del deployment (.../exec).
 *  4. Pasar esa URL para configurarla como TRACK_URL en
 *     apps/academy-web/scripts/build-landing.mjs y regenerar la landing.
 *
 * Desde ese momento, cada click en "Me interesa", cada envío de formulario y
 * cada cambio de pestaña queda registrado como una fila en la hoja "Leads".
 */

function doPost(e) {
  const lock = LockService.getScriptLock();
  lock.waitLock(10000);
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let sheet = ss.getSheetByName('Leads') || ss.insertSheet('Leads');
    if (sheet.getLastRow() === 0) {
      sheet.appendRow([
        'fecha',
        'evento',
        'nombre',
        'email',
        'audiencia',
        'interes',
        'producto',
        'categoria',
        'user_agent',
      ]);
    }
    const d = JSON.parse((e.postData && e.postData.contents) || '{}');
    sheet.appendRow([
      d.ts || new Date().toISOString(),
      d.event || '',
      d.name || '',
      d.email || '',
      d.audience || '',
      d.interest || '',
      d.product || '',
      d.category || '',
      (e.postData && navigatorUA()) || '',
    ]);
    return ContentService.createTextOutput(JSON.stringify({ ok: true })).setMimeType(
      ContentService.MimeType.JSON,
    );
  } catch (err) {
    return ContentService.createTextOutput(
      JSON.stringify({ ok: false, error: String(err) }),
    ).setMimeType(ContentService.MimeType.JSON);
  } finally {
    lock.releaseLock();
  }
}

function navigatorUA() {
  return '';
}

// Test manual desde el editor: Run → testPost (ver Log)
function testPost() {
  doPost({
    postData: {
      contents: JSON.stringify({
        event: 'form_lead',
        name: 'Prueba',
        email: 'prueba@mail.com',
        audience: 'empresas',
        interest: 'Curso de prueba',
        ts: new Date().toISOString(),
      }),
    },
  });
  SpreadsheetApp.getActiveSpreadsheet()
    .getSheetByName('Leads')
    .getDataRange()
    .getValues()
    .slice(-3)
    .forEach((r) => Logger.log(JSON.stringify(r)));
}
