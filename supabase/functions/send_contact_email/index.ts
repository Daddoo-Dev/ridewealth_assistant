// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"

// Resend API endpoint
const RESEND_API_URL = "https://api.resend.com/emails";

console.log("Hello from Functions!")

Deno.serve(async (req) => {
  try {
    const { name, email, subject } = await req.json();
    if (!name || !email || !subject) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const apiKey = Deno.env.get("RESEND_KEY");
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: "Missing RESEND_KEY env variable" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // Change this to your destination email
    const TO_EMAIL = "daddoodev@proton.me";
    const FROM_EMAIL = "noreply@daddoodev.pro"; // <-- CHANGE THIS to your verified domain

    const body = {
      from: FROM_EMAIL,
      to: [TO_EMAIL],
      subject: `Contact Form: ${subject}`,
      html: `<p><b>Name:</b> ${name}</p><p><b>Email:</b> ${email}</p><p><b>Message:</b><br>${subject}</p>`,
      reply_to: email
    };

    const resendRes = await fetch(RESEND_API_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });

    if (!resendRes.ok) {
      const errorText = await resendRes.text();
      return new Response(
        JSON.stringify({ error: `Resend API error: ${errorText}` }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: e.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/send_contact_email' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
