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
    // --- Log environment / secrets availability ---
    console.log("[EMAIL-FN] ===== INVOKED =====");
    console.log(`[EMAIL-FN] BREVO_API_KEY set: ${!!BREVO_API_KEY} (length: ${BREVO_API_KEY?.length ?? 0})`);
    console.log(`[EMAIL-FN] SENDER_EMAIL: ${SENDER_EMAIL}`);
    console.log(`[EMAIL-FN] SUPABASE_URL set: ${!!SUPABASE_URL}`);
    console.log(`[EMAIL-FN] SERVICE_ROLE_KEY set: ${!!SUPABASE_SERVICE_ROLE_KEY}`);

    const payload: EmailPayload = await req.json();
    const { change_type, course_code, teacher_initial, batch_id, details } = payload;
    console.log(`[EMAIL-FN] Payload: type=${change_type}, course=${course_code}, teacher=${teacher_initial}, batch=${batch_id}`);
    console.log(`[EMAIL-FN] Details: ${details}`);

    // Initialize Supabase client with service role key
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Get course info
    const { data: course, error: courseErr } = await supabase
      .from("courses")
      .select("title")
      .eq("code", course_code)
      .single();
    console.log(`[EMAIL-FN] Course lookup: ${course ? course.title : "NOT FOUND"} ${courseErr ? `(err: ${courseErr.message})` : ""}`);

    // Get teacher info
    const { data: teacher, error: teacherErr } = await supabase
      .from("teachers")
      .select("name")
      .eq("initial", teacher_initial)
      .single();
    console.log(`[EMAIL-FN] Teacher lookup: ${teacher ? teacher.name : "NOT FOUND"} ${teacherErr ? `(err: ${teacherErr.message})` : ""}`);

    // Get batch info
    const { data: batch, error: batchErr } = await supabase
      .from("batches")
      .select("name")
      .eq("id", batch_id)
      .single();
    console.log(`[EMAIL-FN] Batch lookup: ${batch ? batch.name : "NOT FOUND"} ${batchErr ? `(err: ${batchErr.message})` : ""}`);

    // Get all student emails in the batch (only email_enabled students)
    const { data: students, error: studentsErr } = await supabase
      .from("students")
      .select("email, name")
      .eq("batch_id", batch_id)
      .eq("email_enabled", true)
      .not("email", "is", null);
    console.log(`[EMAIL-FN] Students with email_enabled in batch: ${students?.length ?? 0} ${studentsErr ? `(err: ${studentsErr.message})` : ""}`);
    if (students) {
      for (const s of students) {
        console.log(`[EMAIL-FN]   student: ${s.name} -> ${s.email}`);
      }
    }

    // Get all super admin emails
    const { data: admins, error: adminsErr } = await supabase
      .from("admins")
      .select("username")
      .eq("type", "super_admin");
    console.log(`[EMAIL-FN] Super admins found: ${admins?.length ?? 0} ${adminsErr ? `(err: ${adminsErr.message})` : ""}`);
    if (admins) {
      for (const a of admins) {
        console.log(`[EMAIL-FN]   admin: ${a.username} (has @: ${a.username?.includes("@")})`);
      }
    }

    // Get the affected teacher's email (if email_enabled)
    const { data: teacherEmailData, error: teacherEmailErr } = await supabase
      .from("teachers")
      .select("email, email_enabled")
      .eq("initial", teacher_initial)
      .single();
    console.log(`[EMAIL-FN] Teacher email data: email=${teacherEmailData?.email ?? "NULL"}, enabled=${teacherEmailData?.email_enabled} ${teacherEmailErr ? `(err: ${teacherEmailErr.message})` : ""}`);

    const courseName = course?.title ?? course_code;
    const teacherName = teacher?.name ?? teacher_initial;
    const batchName = batch?.name ?? batch_id;

    // Build subject
    const subjectMap: Record<string, string> = {
      cancelled: `Class Cancelled: ${courseName}`,
      rescheduled: `Class Rescheduled: ${courseName}`,
      room_changed: `Room Changed: ${courseName}`,
      restored: `Class Restored: ${courseName}`,
      class_assigned: `New Class Assigned: ${courseName}`,
      class_updated: `Class Updated: ${courseName}`,
      routine_generated: `New Routine Generated — ${batchName}`,
    };
    const subject = subjectMap[change_type] ?? `Schedule Update: ${courseName}`;

    // Build HTML email body
    const html = `
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: linear-gradient(135deg, #4F46E5, #7C3AED); padding: 24px; border-radius: 12px 12px 0 0;">
          <h2 style="color: white; margin: 0;">SomoySutro Update</h2>
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
            This is an automated notification from SomoySutro.
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

    console.log(`[EMAIL-FN] ---- RECIPIENT SUMMARY ----`);
    console.log(`[EMAIL-FN] Total unique recipients: ${uniqueEmails.length}`);
    console.log(`[EMAIL-FN] Recipients: ${uniqueEmails.length > 0 ? uniqueEmails.join(", ") : "(NONE — no one will receive email)"}`);

    if (uniqueEmails.length === 0) {
      console.log(`[EMAIL-FN] WARNING: Zero recipients. Check that email_enabled=true and email is set for students/teachers.`);
      return new Response(
        JSON.stringify({
          success: true,
          sent: 0,
          total: 0,
          warning: "No recipients found. Ensure email_enabled=true and email addresses are set for students/teachers in this batch.",
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

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
            sender: { name: "SomoySutro", email: SENDER_EMAIL },
            to: [{ email: toEmail }],
            subject,
            htmlContent: html,
          }),
        });

        if (res.ok) {
          sentCount++;
          const okBody = await res.text();
          console.log(`[EMAIL-FN] ✅ Sent to ${toEmail} — Brevo response: ${okBody}`);
        } else {
          const errBody = await res.text();
          console.error(`[EMAIL-FN] ❌ Brevo error for ${toEmail} (HTTP ${res.status}): ${errBody}`);
          errors.push(`${toEmail}: HTTP ${res.status} — ${errBody}`);
        }
      } catch (e) {
        console.error(`[EMAIL-FN] ❌ Network/fetch error for ${toEmail}: ${e}`);
        errors.push(`${toEmail}: ${e}`);
      }
    }

    console.log(`[EMAIL-FN] ---- FINAL RESULT ----`);
    console.log(`[EMAIL-FN] Sent: ${sentCount}/${uniqueEmails.length}, Errors: ${errors.length}`);
    if (errors.length > 0) {
      console.error(`[EMAIL-FN] Error details: ${JSON.stringify(errors)}`);
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
    console.error(`[EMAIL-FN] ❌ UNHANDLED ERROR: ${error.message}`);
    console.error(`[EMAIL-FN] Stack: ${error.stack}`);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
