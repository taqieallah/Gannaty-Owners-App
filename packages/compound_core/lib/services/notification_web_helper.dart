import 'dart:html' as html;

Future<void> showBrowserNotification(String title, String body) async {
  if (!html.Notification.supported) return;
  final permission = html.Notification.permission;
  if (permission == 'denied') return;
  if (permission != 'granted') {
    final result = await html.Notification.requestPermission();
    if (result != 'granted') return;
  }
  html.Notification(title, body: body);
}
