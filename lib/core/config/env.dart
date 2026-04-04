/// Typed access to compile-time environment variables.
///
/// Values are injected via --dart-define-from-file=env/<environment>.json
/// Never hard-code tokens here — always use the env/ files.
abstract final class Env {
  static const environment = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const mapboxToken = String.fromEnvironment('MAPBOX_TOKEN');
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const appName = String.fromEnvironment('APP_NAME', defaultValue: 'PV Map');

  static bool get isDev => environment == 'dev';
  static bool get isUat => environment == 'uat';
  static bool get isProd => environment == 'prod';
}
