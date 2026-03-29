import "jsr:@supabase/functions-js@2/edge-runtime.d.ts";
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
        const supabaseUrl = Deno.env.get("SUPABASE_URL") ??
            Deno.env.get("URL") ??
            "";
        const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
            Deno.env.get("SERVICE_ROLE_KEY") ?? "";

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

        const { test_process_id, email_type } = await req.json();

        if (!test_process_id || !email_type) {
            return new Response(
                JSON.stringify({
                    error: "Missing required fields: test_process_id and email_type",
                }),
                {
                    status: 400,
                    headers: {
                        ...corsHeaders,
                        "Content-Type": "application/json",
                    },
                },
            );
        }

        const { data: testProcess, error: processError } = await supabaseAdmin
            .from("test_processes")
            .select(`
                *,
                test_users (
                    id,
                    first_name,
                    last_name
                ),
                user_profiles:tester_id (
                    user_id,
                    first_name,
                    last_name,
                    email:user_id
                )
            `)
            .eq("id", test_process_id)
            .single();

        if (processError || !testProcess) {
            return new Response(
                JSON.stringify({ error: "Test process not found" }),
                {
                    status: 404,
                    headers: {
                        ...corsHeaders,
                        "Content-Type": "application/json",
                    },
                },
            );
        }

        const { data: testerUser } = await supabaseAdmin.auth.admin.getUserById(
            testProcess.tester_id
        );

        if (!testerUser?.user?.email) {
            return new Response(
                JSON.stringify({ error: "Tester email not found" }),
                {
                    status: 404,
                    headers: {
                        ...corsHeaders,
                        "Content-Type": "application/json",
                    },
                },
            );
        }

        const testUserName = testProcess.test_users
            ? `${testProcess.test_users.first_name} ${testProcess.test_users.last_name}`
            : "Test User";
        const startDate = new Date(testProcess.start_date).toLocaleDateString();
        const endDate = testProcess.end_date
            ? new Date(testProcess.end_date).toLocaleDateString()
            : null;

        let subject = "";
        let htmlContent = "";

        if (email_type === "test_started") {
            subject = `FokusUhr Test Started: ${testUserName}`;
            htmlContent = `
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="utf-8">
                    <style>
                        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                        .header { background-color: #f4f4f4; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
                        .content { padding: 20px; }
                        .button { display: inline-block; padding: 12px 24px; background-color: #007bff; color: white; text-decoration: none; border-radius: 5px; margin-top: 20px; }
                        .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 12px; color: #666; }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="header">
                            <h1>Test Started: ${testUserName}</h1>
                        </div>
                        <div class="content">
                            <p>Hello,</p>
                            <p>Your test process for <strong>${testUserName}</strong> has officially started!</p>
                            <p><strong>Test Details:</strong></p>
                            <ul>
                                <li>Start Date: ${startDate}</li>
                                ${endDate ? `<li>End Date: ${endDate}</li>` : ""}
                                <li>Duration: 2 weeks</li>
                            </ul>
                            <p>Please remember to:</p>
                            <ul>
                                <li>Complete the initial questions if you haven't already</li>
                                <li>Log daily activities and observations</li>
                                <li>Complete the mid-term check-in after 7 days</li>
                                <li>Complete the exit interview at the end of the test period</li>
                            </ul>
                            <p>You can access your test dashboard at any time to track progress and submit forms.</p>
                            <p>Good luck with the testing!</p>
                        </div>
                        <div class="footer">
                            <p>This is an automated email from FokusUhr Testing System.</p>
                        </div>
                    </div>
                </body>
                </html>
            `;
        } else if (email_type === "daily_reminder") {
            subject = `Daily Reminder: ${testUserName} Test Progress`;
            htmlContent = `
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="utf-8">
                    <style>
                        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                        .header { background-color: #f4f4f4; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
                        .content { padding: 20px; }
                        .button { display: inline-block; padding: 12px 24px; background-color: #007bff; color: white; text-decoration: none; border-radius: 5px; margin-top: 20px; }
                        .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 12px; color: #666; }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="header">
                            <h1>Daily Reminder: ${testUserName}</h1>
                        </div>
                        <div class="content">
                            <p>Hello,</p>
                            <p>This is your daily reminder for the test process with <strong>${testUserName}</strong>.</p>
                            <p><strong>Today's Tasks:</strong></p>
                            <ul>
                                <li>Log today's activities and observations</li>
                                <li>Note any changes in behavior or engagement</li>
                                <li>Record feature usage and duration</li>
                            </ul>
                            <p>Don't forget to update your daily log in the test dashboard!</p>
                            <p>Test Progress: Day ${Math.floor(
                                (new Date().getTime() - new Date(testProcess.start_date).getTime()) /
                                    (1000 * 60 * 60 * 24)
                            ) + 1} of 14</p>
                        </div>
                        <div class="footer">
                            <p>This is an automated reminder from FokusUhr Testing System.</p>
                            <p>You can disable these reminders in your test process settings.</p>
                        </div>
                    </div>
                </body>
                </html>
            `;
        } else {
            return new Response(
                JSON.stringify({ error: "Invalid email_type" }),
                {
                    status: 400,
                    headers: {
                        ...corsHeaders,
                        "Content-Type": "application/json",
                    },
                },
            );
        }

        const resendApiKey = Deno.env.get("RESEND_API_KEY");
        
        if (resendApiKey) {
            const resendResponse = await fetch("https://api.resend.com/emails", {
                method: "POST",
                headers: {
                    "Authorization": `Bearer ${resendApiKey}`,
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    from: "FokusUhr <noreply@fokusuhr.com>",
                    to: testerUser.user.email,
                    subject,
                    html: htmlContent,
                }),
            });

            if (!resendResponse.ok) {
                const errorData = await resendResponse.json();
                console.error("Resend API error:", errorData);
                return new Response(
                    JSON.stringify({ error: "Failed to send email", details: errorData }),
                    {
                        status: 500,
                        headers: {
                            ...corsHeaders,
                            "Content-Type": "application/json",
                        },
                    },
                );
            }
        } else {
            console.log("Email would be sent:", {
                to: testerUser.user.email,
                subject,
                html: htmlContent.substring(0, 100) + "...",
            });
            console.warn("RESEND_API_KEY not configured. Email not sent. Configure Resend API key to enable email sending.");
        }

        return new Response(
            JSON.stringify({
                success: true,
                message: "Email sent successfully",
            }),
            {
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            },
        );
    } catch (error) {
        console.error("Function error:", error);
        return new Response(
            JSON.stringify({
                error: "An unexpected error occurred",
                details: error instanceof Error ? error.message : String(error),
            }),
            {
                status: 500,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            },
        );
    }
});

