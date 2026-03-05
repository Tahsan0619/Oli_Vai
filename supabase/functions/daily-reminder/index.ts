// Supabase Edge Function: daily-reminder
// Sends daily reminder emails + creates in-app notifications at midnight
// for each student about their next day's schedule
//
// Deploy: supabase functions deploy daily-reminder
// Then set up a cron job in Supabase Dashboard:
//   Go to Database > Extensions > Enable pg_cron (if Pro plan)
//   OR use an external cron service (e.g., cron-job.org) to call this endpoint daily at midnight
//
// Cron URL: https://<project-ref>.supabase.co/functions/v1/daily-reminder
// Schedule: 0 0 * * * (midnight daily)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (_req: Request) => {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Determine tomorrow's day name
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    const tomorrowDay = dayNames[tomorrow.getDay()];
    const tomorrowDateStr = tomorrow.toISOString().split("T")[0];

    // Get all students who have notifications or email enabled
    const { data: students } = await supabase
      .from("students")
      .select("student_id, name, email, batch_id, notifications_enabled, email_enabled")
      .or("notifications_enabled.eq.true,email_enabled.eq.true");

    if (!students || students.length === 0) {
      return new Response(JSON.stringify({ message: "No students found" }), { status: 200 });
    }

    // Get all timetable entries for tomorrow
    const { data: entries } = await supabase
      .from("timetable_entries")
      .select(`
        day, start_time, end_time, course_code, teacher_initial,
        type, mode, is_cancelled, batch_id,
        rooms!room_id(name),
        courses!course_code(title),
        teachers!teacher_initial(name)
      `)
      .eq("day", tomorrowDay)
      .eq("is_cancelled", false)
      .order("start_time", { ascending: true });

    // Group entries by batch_id
    const entriesByBatch: Record<string, any[]> = {};
    if (entries) {
      for (const entry of entries) {
        if (!entriesByBatch[entry.batch_id]) {
          entriesByBatch[entry.batch_id] = [];
        }
        entriesByBatch[entry.batch_id].push(entry);
      }
    }

    let emailsSent = 0;
    let notificationsCreated = 0;

    for (const student of students) {
      const batchEntries = entriesByBatch[student.batch_id] || [];

      if (batchEntries.length === 0) continue;

      // Build schedule summary
      const scheduleLines = batchEntries.map((e: any) => {
        const courseName = e.courses?.title ?? e.course_code;
        const teacherName = e.teachers?.name ?? e.teacher_initial;
        const roomName = e.rooms?.name ?? "TBA";
        return `${e.start_time.slice(0, 5)}-${e.end_time.slice(0, 5)} | ${courseName} | ${teacherName} | Room: ${roomName} (${e.mode})`;
      });

      const notifBody = `You have ${batchEntries.length} class(es) tomorrow (${tomorrowDay}):\n${scheduleLines.join("\n")}`;

      // Create in-app notification only if notifications_enabled
      if (student.notifications_enabled) {
        await supabase.from("notifications").insert({
          type: "daily_reminder",
          title: `Tomorrow's Schedule — ${tomorrowDay}`,
          body: notifBody,
          recipient_type: "student",
          recipient_id: student.student_id,
          is_read: false,
        });
        notificationsCreated++;
      }

      // Send email only if email_enabled and student has email
      if (student.email_enabled && student.email) {
        const html = `
          <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto;">
            <div style="background: linear-gradient(135deg, #4F46E5, #7C3AED); padding: 24px; border-radius: 12px 12px 0 0;">
              <h2 style="color: white; margin: 0;">Tomorrow's Schedule</h2>
              <p style="color: rgba(255,255,255,0.8); margin: 4px 0 0 0;">${tomorrowDay}, ${tomorrowDateStr}</p>
            </div>
            <div style="background: #f9fafb; padding: 24px; border: 1px solid #e5e7eb; border-top: none; border-radius: 0 0 12px 12px;">
              <p style="color: #1a1a2e; margin-top: 0;">Hi ${student.name},</p>
              <p style="color: #6b7280;">You have <strong>${batchEntries.length}</strong> class(es) scheduled for tomorrow:</p>
              <table style="width: 100%; border-collapse: collapse; margin: 16px 0;">
                <thead>
                  <tr style="background: #4F46E5; color: white;">
                    <th style="padding: 8px 12px; text-align: left; border-radius: 8px 0 0 0;">Time</th>
                    <th style="padding: 8px 12px; text-align: left;">Course</th>
                    <th style="padding: 8px 12px; text-align: left;">Teacher</th>
                    <th style="padding: 8px 12px; text-align: left; border-radius: 0 8px 0 0;">Room</th>
                  </tr>
                </thead>
                <tbody>
                  ${batchEntries.map((e: any, i: number) => `
                    <tr style="background: ${i % 2 === 0 ? "white" : "#f8f9fc"};">
                      <td style="padding: 8px 12px; border-bottom: 1px solid #e5e7eb;">${e.start_time.slice(0, 5)}-${e.end_time.slice(0, 5)}</td>
                      <td style="padding: 8px 12px; border-bottom: 1px solid #e5e7eb;">${e.courses?.title ?? e.course_code}</td>
                      <td style="padding: 8px 12px; border-bottom: 1px solid #e5e7eb;">${e.teachers?.name ?? e.teacher_initial}</td>
                      <td style="padding: 8px 12px; border-bottom: 1px solid #e5e7eb;">${e.rooms?.name ?? "TBA"} (${e.mode})</td>
                    </tr>
                  `).join("")}
                </tbody>
              </table>
              <p style="color: #9ca3af; font-size: 12px; text-align: center; margin-top: 16px;">
                EDTE Routine System — Automated Daily Reminder
              </p>
            </div>
          </div>
        `;

        try {
          await fetch("https://api.resend.com/emails", {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${RESEND_API_KEY}`,
            },
            body: JSON.stringify({
              from: "EDTE Routine <notifications@edte.edu>",
              to: [student.email],
              subject: `Tomorrow's Schedule: ${batchEntries.length} class(es) on ${tomorrowDay}`,
              html,
            }),
          });
          emailsSent++;
        } catch (emailError) {
          console.error(`Failed to send email to ${student.email}:`, emailError);
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        day: tomorrowDay,
        notifications_created: notificationsCreated,
        emails_sent: emailsSent,
      }),
      { headers: { "Content-Type": "application/json" }, status: 200 }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});
