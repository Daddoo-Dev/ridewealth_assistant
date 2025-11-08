# OAuth Testing Setup

## Prerequisites

1. **Install Playwright:**
   ```bash
   npm install playwright
   npx playwright install chromium
   ```

2. **Add Test Credentials to env.json:**
   ```json
   {
     "SUPABASE_URL": "https://ygreztutwejfiqyzdpnd.supabase.co",
     "SUPABASE_KEY": "your-key",
     "TEST_GOOGLE_EMAIL": "your-test@gmail.com",
     "TEST_GOOGLE_PASSWORD": "your-password",
     "TEST_APPLE_EMAIL": "your-test@icloud.com",
     "TEST_APPLE_PASSWORD": "your-password"
   }
   ```

3. **Create Test Accounts:**
   - **Google:** Create a test Google account, disable 2FA
   - **Apple:** Create a test Apple ID, disable 2FA if possible

## Running Tests

```bash
node test_oauth.js
```

## What It Tests

- ✅ OAuth URL generation
- ✅ Provider login pages load
- ✅ Credential authentication
- ✅ Consent flow (if needed)
- ✅ Callback redirect
- ✅ Access token received

## Notes

- Tests run in **non-headless mode** by default (you can see the browser)
- Change `headless: false` to `headless: true` for CI/CD
- Screenshots saved on errors: `google_signin_error.png`, `apple_signin_error.png`
- **2FA is supported** - script pauses and waits up to 2 minutes for you to manually enter code
- Watch the console - it will tell you when to enter 2FA
- Test accounts may get flagged by Google/Apple for automated access

## Limitations

- Can't test mobile deep links (tests web OAuth only)
- May be blocked by Google/Apple bot detection
- Requires test credentials in plaintext (keep env.json secure)
- 2FA/SMS verification requires manual intervention

