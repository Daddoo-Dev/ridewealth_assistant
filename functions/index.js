const functions = require("firebase-functions");

exports.handleAppleSignIn = functions.https.onRequest((request, response) => {
  console.log("Function triggered with query params:", request.query);
  console.log("Request headers:", request.headers);

  const {code, idToken, state} = request.query;

  // Set CORS headers for preflight requests
  response.set("Access-Control-Allow-Origin", "https://uberdriver-2941d.firebaseapp.com");
  response.set("Access-Control-Allow-Methods", "GET");
  response.set("Access-Control-Allow-Headers", "Content-Type");

  // Log the incoming parameters
  console.log("Code:", code);
  console.log("State:", state);
  console.log("ID Token:", idToken ? "present" : "not present");

  // Validate state parameter
  if (!state) {
    console.error("No state parameter received");
    response.redirect("https://uberdriver-2941d.firebaseapp.com/__/auth/handler?error=invalid_state");
    return;
  }

  // Construct Firebase auth handler URL with parameters
  const redirectUrl = new URL("https://uberdriver-2941d.firebaseapp.com/__/auth/handler");
  redirectUrl.searchParams.append("code", code);
  if (idToken) redirectUrl.searchParams.append("id_token", idToken);
  redirectUrl.searchParams.append("state", state);
  redirectUrl.searchParams.append("provider", "apple.com");

  console.log("Redirecting to:", redirectUrl.toString());

  // Redirect to Firebase auth handler
  response.redirect(redirectUrl.toString());
});
