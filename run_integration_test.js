const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const envPath = path.join(__dirname, 'env.json');
if (!fs.existsSync(envPath)) {
  console.error('env.json not found. Create it with: SUPABASE_URL, SUPABASE_ANON_PUBLIC, TEST_SUBSCRIBED_EMAIL, TEST_SUBSCRIBED_PASSWORD, TEST_FREE_EMAIL, TEST_FREE_PASSWORD');
  process.exit(1);
}
const env = JSON.parse(fs.readFileSync(envPath, 'utf8'));
const keys = ['SUPABASE_URL', 'SUPABASE_ANON_PUBLIC', 'TEST_SUBSCRIBED_EMAIL', 'TEST_SUBSCRIBED_PASSWORD', 'TEST_FREE_EMAIL', 'TEST_FREE_PASSWORD'];
const defines = keys.filter(k => env[k]).map(k => `--dart-define=${k}=${env[k]}`).join(' ');
const device = process.argv[2] || 'windows';
execSync(`flutter test integration_test/app_flow_test.dart -d ${device} ${defines}`, { stdio: 'inherit', cwd: __dirname });