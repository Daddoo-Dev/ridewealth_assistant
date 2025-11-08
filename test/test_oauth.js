/**
 * OAuth Integration Test Script
 * Tests Google and Apple Sign In flows through Supabase
 * 
 * Setup:
 * 1. npm install playwright
 * 2. npx playwright install chromium
 * 3. Add test credentials to env.json:
 *    {
 *      "TEST_GOOGLE_EMAIL": "your-test@gmail.com",
 *      "TEST_GOOGLE_PASSWORD": "password",
 *      "TEST_APPLE_EMAIL": "your-test@icloud.com",
 *      "TEST_APPLE_PASSWORD": "password"
 *    }
 * 
 * Run:
 * node test_oauth.js
 */

const { chromium } = require('playwright');
const fs = require('fs');

// Load environment variables
const env = JSON.parse(fs.readFileSync('./env.json', 'utf8'));

const SUPABASE_URL = env.SUPABASE_URL;
const REDIRECT_URL = 'http://localhost:3000'; // Change to your web app URL if different

async function testGoogleSignIn() {
  console.log('\n=== Testing Google Sign In ===');
  const browser = await chromium.launch({ headless: false }); // Set to true for CI
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    // Navigate to Supabase Google OAuth URL
    const googleAuthUrl = `${SUPABASE_URL}/auth/v1/authorize?provider=google&redirect_to=${encodeURIComponent(REDIRECT_URL)}`;
    console.log('Navigating to Google OAuth...');
    await page.goto(googleAuthUrl);

    // Wait for Google login page
    await page.waitForSelector('input[type="email"]', { timeout: 10000 });
    console.log('Google login page loaded');

    // Enter email
    await page.fill('input[type="email"]', env.TEST_GOOGLE_EMAIL);
    await page.click('#identifierNext');
    console.log('Email entered');

    // Wait for password field
    await page.waitForSelector('input[type="password"]', { timeout: 10000 });
    await page.fill('input[type="password"]', env.TEST_GOOGLE_PASSWORD);
    await page.click('#passwordNext');
    console.log('Password entered');

    // Wait a moment for 2FA prompt or redirect
    await page.waitForTimeout(3000);
    
    // Check if we hit 2FA
    const currentUrl = page.url();
    if (currentUrl.includes('challenge') || currentUrl.includes('2fa') || currentUrl.includes('verification')) {
      console.log('⚠️  2FA DETECTED - Please manually enter your 2FA code in the browser');
      console.log('⏳ Waiting up to 2 minutes for you to complete 2FA...');
      
      // Wait for redirect after 2FA (up to 2 minutes)
      await page.waitForURL(url => url.includes(REDIRECT_URL) || url.includes('access_token'), { timeout: 120000 });
    } else {
      // No 2FA, wait for redirect normally
      await page.waitForURL(url => url.includes(REDIRECT_URL) || url.includes('access_token'), { timeout: 15000 });
    }
    
    const finalUrl = page.url();
    console.log('Redirected to:', finalUrl);

    // Check for access token in URL or successful redirect
    if (finalUrl.includes('access_token') || finalUrl.includes(REDIRECT_URL)) {
      console.log('✅ Google Sign In SUCCESS');
      return true;
    } else {
      console.log('❌ Google Sign In FAILED - No access token found');
      return false;
    }
  } catch (error) {
    console.error('❌ Google Sign In ERROR:', error.message);
    // Take screenshot on error
    await page.screenshot({ path: 'google_signin_error.png' });
    return false;
  } finally {
    await browser.close();
  }
}

async function testAppleSignIn() {
  console.log('\n=== Testing Apple Sign In ===');
  const browser = await chromium.launch({ headless: false }); // Set to true for CI
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    // Navigate to Supabase Apple OAuth URL
    const appleAuthUrl = `${SUPABASE_URL}/auth/v1/authorize?provider=apple&redirect_to=${encodeURIComponent(REDIRECT_URL)}`;
    console.log('Navigating to Apple OAuth...');
    await page.goto(appleAuthUrl);

    // Wait for Apple login page
    await page.waitForSelector('input[type="text"]', { timeout: 10000 });
    console.log('Apple login page loaded');

    // Enter Apple ID
    await page.fill('input[type="text"]', env.TEST_APPLE_EMAIL);
    await page.click('button[type="submit"]');
    console.log('Apple ID entered');

    // Wait for password field
    await page.waitForSelector('input[type="password"]', { timeout: 10000 });
    await page.fill('input[type="password"]', env.TEST_APPLE_PASSWORD);
    await page.click('button[type="submit"]');
    console.log('Password entered');

    // Wait a moment for potential 2FA/Trust prompts
    await page.waitForTimeout(3000);
    
    // Check if we hit 2FA or Trust Browser prompt
    const currentUrl = page.url();
    const pageContent = await page.content();
    
    if (currentUrl.includes('auth') || pageContent.includes('verification') || pageContent.includes('Trust') || pageContent.includes('two-factor')) {
      console.log('⚠️  2FA or Trust Browser prompt detected');
      console.log('⏳ Please manually complete 2FA or click Trust in the browser');
      console.log('⏳ Waiting up to 2 minutes...');
      
      // Wait for redirect after 2FA (up to 2 minutes)
      await page.waitForURL(url => url.includes(REDIRECT_URL) || url.includes('access_token'), { timeout: 120000 });
    } else {
      // Check if there's a "Trust" or "Continue" button
      const continueButton = await page.$('button:has-text("Continue")');
      if (continueButton) {
        await continueButton.click();
        console.log('Clicked Continue button');
      }

      // Wait for redirect back to app (callback with tokens)
      await page.waitForURL(url => url.includes(REDIRECT_URL) || url.includes('access_token'), { timeout: 15000 });
    }
    
    const finalUrl = page.url();
    console.log('Redirected to:', finalUrl);

    // Check for access token in URL or successful redirect
    if (finalUrl.includes('access_token') || finalUrl.includes(REDIRECT_URL)) {
      console.log('✅ Apple Sign In SUCCESS');
      return true;
    } else {
      console.log('❌ Apple Sign In FAILED - No access token found');
      return false;
    }
  } catch (error) {
    console.error('❌ Apple Sign In ERROR:', error.message);
    // Take screenshot on error
    await page.screenshot({ path: 'apple_signin_error.png' });
    return false;
  } finally {
    await browser.close();
  }
}

async function runTests() {
  console.log('Starting OAuth Integration Tests...');
  console.log('Supabase URL:', SUPABASE_URL);

  // Check for test credentials
  if (!env.TEST_GOOGLE_EMAIL || !env.TEST_GOOGLE_PASSWORD) {
    console.warn('⚠️  Google test credentials not found in env.json - skipping Google test');
  }
  if (!env.TEST_APPLE_EMAIL || !env.TEST_APPLE_PASSWORD) {
    console.warn('⚠️  Apple test credentials not found in env.json - skipping Apple test');
  }

  const results = {
    google: null,
    apple: null
  };

  // Test Google
  if (env.TEST_GOOGLE_EMAIL && env.TEST_GOOGLE_PASSWORD) {
    results.google = await testGoogleSignIn();
  }

  // Test Apple
  if (env.TEST_APPLE_EMAIL && env.TEST_APPLE_PASSWORD) {
    results.apple = await testAppleSignIn();
  }

  // Summary
  console.log('\n=== Test Summary ===');
  if (results.google !== null) {
    console.log(`Google Sign In: ${results.google ? '✅ PASS' : '❌ FAIL'}`);
  }
  if (results.apple !== null) {
    console.log(`Apple Sign In: ${results.apple ? '✅ PASS' : '❌ FAIL'}`);
  }

  const allPassed = Object.values(results).filter(r => r !== null).every(r => r === true);
  process.exit(allPassed ? 0 : 1);
}

// Run tests
runTests().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});

