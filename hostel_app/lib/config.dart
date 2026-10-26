class ApiConfig {
  // EDIT THIS ONE LINE to match how your phone/emulator reaches your PC.
  //
  //  - Android emulator                       -> http://10.0.2.2:8000
  //  - iOS simulator / Chrome, same machine    -> http://127.0.0.1:8000
  //  - Real phone on the same Wi-Fi as your PC -> http://<your PC's LAN IP>:8000
  //      find it with `ipconfig` (Windows) or `ifconfig` / `ip a` (Mac/Linux),
  //      and start Django with: python manage.py runserver 0.0.0.0:8000
  static const String baseUrl = 'http://127.0.0.1:8000';
}
