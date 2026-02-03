import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RC_V2_BASE = "https://api.revenuecat.com/v2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const rcSecretKey = Deno.env.get("REVENUECAT_SECRET_KEY");
    const rcProjectId = Deno.env.get("REVENUECAT_PROJECT_ID");

    if (!supabaseUrl || !supabaseAnonKey) {
      return new Response(
        JSON.stringify({ error: "Server config missing" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    if (!rcSecretKey || !rcProjectId) {
      return new Response(
        JSON.stringify({ error: "RevenueCat config missing" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const customerId = encodeURIComponent(user.id);
    const url = `${RC_V2_BASE}/projects/${encodeURIComponent(rcProjectId)}/customers/${customerId}/active_entitlements`;
    const rcRes = await fetch(url, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${rcSecretKey}`,
        "Content-Type": "application/json",
      },
    });

    if (rcRes.status === 404) {
      return new Response(
        JSON.stringify({ active: false }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!rcRes.ok) {
      const errText = await rcRes.text();
      return new Response(
        JSON.stringify({ error: `RevenueCat error: ${errText}` }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const data = await rcRes.json();
    const items = data?.items ?? [];
    const active = Array.isArray(items) && items.length > 0;

    return new Response(
      JSON.stringify({ active }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: e.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
