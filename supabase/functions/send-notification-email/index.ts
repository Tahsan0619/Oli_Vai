// Supabase Edge Function: send-notification-email
// Sends email via Brevo (Sendinblue) API when timetable changes occur
// Free tier: 300 emails/day, no domain verification needed
//
// Deploy: supabase functions deploy send-notification-email
// Set secret: supabase secrets set BREVO_API_KEY=xkeysib-...
// Set secret: supabase secrets set SENDER_EMAIL=your@email.com

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const BREVO_API_KEY = Deno.env.get("BREVO_API_KEY")!;
const SENDER_EMAIL = Deno.env.get("SENDER_EMAIL") || "ziaulislam1002@gmail.com";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

interface EmailPayload {
  change_type: string; // cancelled, rescheduled, room_changed, restored
  course_code: string;
  teacher_initial: string;
  batch_id: string;
  details: string;
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload: EmailPayload = await req.json();
    const { change_type, course_code, teacher_initial, batch_id, details } = payload;

    // Initialize Supabase client with service role key
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Get course info
    const { data: course } = await supabase
      .from("courses")
      .select("title")
      .eq("code", course_code)
      .single();

    // Get teacher info
    const { data: teacher } = await supabase
      .from("teachers")
      .select("name")
      .eq("initial", teacher_initial)
      .single();

    // Get batch info
    const { data: batch } = await supabase
      .from("batches")
      .select("name")
      .eq("id", batch_id)
      .single();

    // Get all student emails in the batch (only email_enabled students)
    const { data: students } = await supabase
      .from("students")
      .select("email, name")
      .eq("batch_id", batch_id)
      .eq("email_enabled", true)
      .not("email", "is", null);

    // Get all super admin emails
    const { data: admins } = await supabase
      .from("admins")
      .select("username")
      .eq("type", "super_admin");

    // Get the affected teacher's email (if email_enabled)
    const { data: teacherEmailData } = await supabase
      .from("teachers")
      .select("email, email_enabled")
      .eq("initial", teacher_initial)
      .single();

    const courseName = course?.title ?? course_code;
    const teacherName = teacher?.name ?? teacher_initial;
    const batchName = batch?.name ?? batch_id;

    // Build subject
    const subjectMap: Record<string, string> = {
      cancelled: `Class Cancelled: ${courseName}`,
      rescheduled: `Class Rescheduled: ${courseName}`,
      room_changed: `Room Changed: ${courseName}`,
      restored: `Class Restored: ${courseName}`,
    };
    const subject = subjectMap[change_type] ?? `Schedule Update: ${courseName}`;

    // Build HTML email body
    const html = `
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: linear-gradient(135deg, #4F46E5, #7C3AED); padding: 24px; border-radius: 12px 12px 0 0;">
          <h2 style="color: white; margin: 0;">EDTE Routine Update</h2>
        </div>
        <div style="background: #f9fafb; padding: 24px; border: 1px solid #e5e7eb; border-top: none; border-radius: 0 0 12px 12px;">
          <div style="background: white; padding: 20px; border-radius: 8px; border: 1px solid #e5e7eb;">
            <h3 style="color: #1a1a2e; margin-top: 0;">${subject}</h3>
            <p style="color: #6b7280; line-height: 1.6;">
              <strong>Course:</strong> ${courseName} (${course_code})<br/>
              <strong>Teacher:</strong> ${teacherName} (${teacher_initial})<br/>
              <strong>Batch:</strong> ${batchName}<br/>
              <strong>Details:</strong> ${details}
            </p>
          </div>
          <p style="color: #9ca3af; font-size: 12px; margin-top: 16px; text-align: center;">
            This is an automated notification from EDTE Routine System.
          </p>
        </div>
      </div>
    `;

    // Collect all recipient emails
    const recipientEmails: string[] = [];

    // Add all email-enabled students in the batch
    if (students) {
      for (const s of students) {
        if (s.email) recipientEmails.push(s.email);
      }
    }

    // Add all super admin emails
    if (admins) {
      for (const a of admins) {
        if (a.username && a.username.includes("@")) recipientEmails.push(a.username);
      }
    }

    // Add the affected teacher's email (if email_enabled and has an email)
    if (teacherEmailData?.email && teacherEmailData?.email_enabled) {
      recipientEmails.push(teacherEmailData.email);
    }

    // Deduplicate emails
    const uniqueEmails = [...new Set(recipientEmails)];

    console.log(`Sending emails to ${uniqueEmails.length} unique recipients for ${change_type} on ${course_code}`);
    console.log(`Recipients: ${uniqueEmails.join(", ")}`);

    // Send emails via Brevo (one per recipient to stay within free tier limits)
    let sentCount = 0;
    const errors: string[] = [];

    for (const toEmail of uniqueEmails) {
      try {
        const res = await fetch("https://api.brevo.com/v3/smtp/email", {
          method: "POST",
          headers: {
            "accept": "application/json",
            "content-type": "application/json",
            "api-key": BREVO_API_KEY,
          },
          body: JSON.stringify({
            sender: { name: "EDTE Routine", email: SENDER_EMAIL },
            to: [{ email: toEmail }],
            subject,
            htmlContent: html,
          }),
        });

        if (res.ok) {
          sentCount++;
          console.log(`Email sent to ${toEmail}`);
        } else {
          const errBody = await res.text();
          console.error(`Brevo error for ${toEmail} (${res.status}): ${errBody}`);
          errors.push(`${toEmail}: ${res.status}`);
        }
      } catch (e) {
        console.error(`Failed to send to ${toEmail}: ${e}`);
        errors.push(`${toEmail}: ${e}`);
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        sent: sentCount,
        total: uniqueEmails.length,
        errors: errors.length > 0 ? errors : undefined,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
