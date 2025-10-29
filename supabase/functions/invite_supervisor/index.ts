import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? Deno.env.get("URL") ??
      "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
      Deno.env.get("SERVICE_ROLE_KEY") ?? "";

    console.log("Environment check:", {
      url: supabaseUrl ? "✓" : "✗",
      serviceKey: serviceRoleKey ? "✓" : "✗",
    });

    const supabaseAdmin = createClient(
      supabaseUrl,
      serviceRoleKey,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      },
    );

    const { email, first_name, last_name } = await req.json();

    if (!email || !first_name || !last_name) {
      return new Response(
        JSON.stringify({
          error:
            "Missing required fields: email, first_name, last_name are required",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return new Response(
        JSON.stringify({
          error: "Please provide a valid email address",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const { data: existingUser, error: checkError } = await supabaseAdmin.auth
      .admin.listUsers();

    if (checkError) {
      console.error("Error checking existing users:", checkError);
    } else {
      const userExists = existingUser.users.find((user) =>
        user.email === email
      );
      if (userExists) {
        return new Response(
          JSON.stringify({
            error:
              "A user with this email address already exists or has been invited",
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }
    }

    const { data: inviteData, error: inviteError } = await supabaseAdmin.auth
      .admin.inviteUserByEmail(email, {
        data: {
          first_name,
          last_name,
          role: "supervisor",
          email,
        },
        redirectTo: `${req.headers.get("origin")}/set-password?type=invite`,
      });

    if (inviteError) {
      console.error("Invite error:", inviteError);
      let errorMessage = "Failed to send invitation";

      if (inviteError.message?.includes("rate_limit")) {
        errorMessage = "Too many invitations sent. Please try again later.";
      } else if (inviteError.message?.includes("invalid_email")) {
        errorMessage = "Invalid email address format";
      } else if (inviteError.message?.includes("email_already_confirmed")) {
        errorMessage = "This email is already associated with an account";
      } else if (inviteError.message) {
        errorMessage = inviteError.message;
      }

      return new Response(
        JSON.stringify({ error: errorMessage }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Supervisor invitation sent successfully",
        user: inviteData.user,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error("Function error:", error);

    let errorMessage = "An unexpected error occurred";
    let statusCode = 500;

    if (error instanceof Error) {
      if (error.message?.includes("JSON")) {
        errorMessage = "Invalid request format";
        statusCode = 400;
      } else {
        errorMessage = error.message;
      }
    }

    return new Response(
      JSON.stringify({ error: errorMessage }),
      {
        status: statusCode,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
