import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const jsonHeaders = {
  "content-type": "application/json; charset=utf-8",
};

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204 });
  }

  if (request.method !== "POST" && request.method !== "DELETE") {
    return new Response("Method not allowed.", { status: 405, headers: jsonHeaders });
  }

  const authorization = request.headers.get("authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return new Response("Sign-in is required.", { status: 401, headers: jsonHeaders });
  }

  const supabaseURL = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseURL || !anonKey || !serviceRoleKey) {
    return new Response("Supabase function environment is not configured.", { status: 500, headers: jsonHeaders });
  }

  const userClient = createClient(supabaseURL, anonKey, {
    global: {
      headers: {
        authorization,
      },
    },
  });

  const { data, error } = await userClient.auth.getUser();
  if (error || !data.user) {
    return new Response("Sign-in is required.", { status: 401, headers: jsonHeaders });
  }

  const adminClient = createClient(supabaseURL, serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });

  const { error: deleteError } = await adminClient.auth.admin.deleteUser(data.user.id);
  if (deleteError) {
    return new Response("Account could not be deleted.", { status: 500, headers: jsonHeaders });
  }

  return new Response(null, { status: 204 });
});
