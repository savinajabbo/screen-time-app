# LockIn AI Product Document

---

## 1. Overview & Purpose

LockIn AI is a mobile application built with **SwiftUI**, powered by **Supabase** on the back end, and leveraging the **OpenAI API** for advanced AI analysis, voice interaction, and personal assistance. By combining user‐entered schedules (dates, projects, exams, commitments) with device activity data (via Apple’s Device Activity API), LockIn AI discovers each user’s unique “brain patterns” (where and when energy is spent) and automatically adjusts calendar entries, sends personalized suggestions, and surfaces insights to help users optimize productivity, manage energy levels, and balance work/rest cycles.

> **Key Idea**:  
> 1. Users input all planned obligations (events, deadlines, study sessions).  
> 2. The app continuously ingests device‐activity metadata (app usage, screen time) to model real‐world “energy expenditure.”  
> 3. An AI engine analyzes both planned schedule and actual usage in tandem, then issues dynamic suggestions, calendar reorganizations, and voice coach feedback based on emerging patterns.

---

## 2. Problem Statement

- **Overcommitment & Burnout**  
  Many high‐achieving students and professionals (especially in STEM) struggle to accurately estimate how much mental energy tasks require. By the end of the week, they may discover they spent twice as many hours on distracting apps or low‐priority tasks, leading to missed deadlines or mental exhaustion.

- **Lack of Real‐Time Insight**  
  Traditional calendar apps (Apple Calendar, Google Calendar) do not factor in “where” users actually spend time on their devices. Without that context, suggested time blocks can be unrealistic or misaligned with personal productivity rhythms.

- **Generic Productivity Advice**  
  Most productivity tools offer static to‐do lists or generic scheduling tips. They do not adapt to a user’s real behavioral data and changing energy levels throughout the day.

**LockIn AI solves this by** synchronizing planned commitments with real‐world device usage, then employing a conversational AI coach to provide tailored, data‐driven suggestions, helping users allocate their energy where it matters most.

---

## 3. Product Vision & Goals

### 3.1 Vision
Empower users to make data‐driven decisions about how they plan and spend their time—transforming vague “to-do” mindsets into a truly personalized, adaptive scheduling system that aligns with each individual’s natural productivity rhythms.

### 3.2 Goals
1. Enable seamless entry of schedules, deadlines, and personal commitments.  
2. Continuously harvest device activity (e.g., app usage events, screen‐on/off timestamps) to build an accurate model of “brain patterns.”  
3. Leverage OpenAI’s GPT-based models to analyze both planned schedule and device activity logs, generating contextually relevant feedback—e.g., “You spent 3 hours on social media yesterday afternoon; consider shifting your study block to late morning when you’re historically more focused.”  
4. Offer an optional voice assistant interface (powered by OpenAI’s speech synthesis) that can (a) read back schedule analytics, (b) coach users through routines, and (c) answer ad‐hoc time management questions in natural language.  
5. Dynamically adjust calendar blocks (“auto-blocking”) based on discovered energy slumps, focus peaks, and real‐time device usage, ensuring that “time spent planning” matches “time spent doing.”  
6. Maintain secure, private storage of all personal data (activity logs, schedules, AI‐driven notes) using Supabase’s PostgreSQL database and built‐in Row Level Security (RLS) policies.

---

## 4. Key Features

### 4.1 Schedule Input & Management
- **Manual Entry**  
  - Users can create events (title, start/end time, type: class/project/exam/personal) via a SwiftUI‐based form.  
  - Each entry may include metadata tags (e.g., “Study: Physics,” “Work: HVAC Intern,” “Hackathon: Austin”).

- **Import from Calendar** (optional MVP stage)  
  - Read‐only import of existing Apple Calendar entries (requiring user permission).  
  - Map imported events to LockIn AI’s internal schema for analysis and blocking.

---

### 4.2 AI Analysis & Suggestion Engine
- **Batch Analysis**  
  - On schedule creation or modification, the app submits a JSON payload to a Cloud Function (hosted on Supabase Functions) containing:  
    1. List of upcoming events (next 7 days)  
    2. Aggregated device activity logs (last 7 days, hourly buckets)  
  - The Cloud Function invokes OpenAI’s GPT endpoint (e.g., gpt-4-turbo) with a tightly crafted prompt that instructs the model to:  
    - Identify productivity peaks/lows (e.g., “Between 9–11 AM, user had 80% focus on study apps.”)  
    - Recommend schedule shifts (e.g., “Move research meeting from 3 PM to 10 AM when user’s focus level is higher.”)  
    - Suggest breaks (e.g., “After 50 minutes of consecutive coding, schedule a 10-minute walk.”)  
    - Provide motivational micro-insights (e.g., “Your energy dips around 4 PM; consider a light snack or power nap at 3:45 PM.”)

- **Continuous Feedback**  
  - Every morning at 8 AM (local time; scheduled via Supabase cron), the Cloud Function re-runs analysis on the previous day’s activity and outputs a summary “Daily Productivity Report” that appears in the app’s “Insights” tab.  
  - If a major deviation is detected (e.g., user spent 4 hours unattended in an exam window), an optional push notification can be triggered: “We noticed you spent extra time on social media yesterday evening. Would you like to reallocate tonight’s study block?”

---

### 4.3 Device Activity Integration (“Brain Patterns”)
- **Data Collection**  
  - Using **Device Activity API** (iOS 15+), the app requests the user’s permission to monitor:  
    - Active app identifiers and durations (e.g., “Instagram: 1 hr 15 min,” “Notion: 2 hr 30 min”).  
    - Screen on/off events (timestamps).  
  - All raw data is stored locally in encrypted form and periodically (e.g., every 6 hours) synced to Supabase’s PostgreSQL database under the authenticated user’s record.

- **Visualization & Blocking**  
  - A SwiftUI “Activity Heatmap” shows, by hour and by day, where time was spent (e.g., “9–10 AM: 80% Focus Apps; 3–4 PM: 50% Social Media”).  
  - When users create or adjust calendar events, the app can automatically “gray out” time ranges already consumed by activities (e.g., if the user was on video calls from 2–3 PM, any event scheduled in that slot is flagged or visually differentiated).

---

### 4.4 Voice Interaction & Personal Assistant
- **Conversational Interface**  
  - A microphone button on every screen lets users ask questions in natural language (e.g., “When am I most productive on Fridays?”; “Rearrange my Monday to avoid two back-to-back 3-hour study blocks.”)  
  - Recorded audio is sent to OpenAI’s Speech-to-Text endpoint (if available) or Apple’s native Speech framework for transcription. The transcribed text, along with context (current schedule, recent device activity), is forwarded to GPT for a dialog response.

- **Text-to-Speech Feedback**  
  - The app can read aloud daily summaries or suggestions via Apple’s AVSpeechSynthesizer or OpenAI’s Text-to-Speech endpoint, allowing hands-free review of insights during commutes or workouts.

---

## 5. User Personas

1. **High School STEM Student (“Aisha, 17”)**  
   - Enrolled in AP Physics and AP Biology; actively studying for upcoming exams.  
   - Juggles hackathon commitments, club meetings, and volunteer work.  
   - Wants to avoid burnout, identify ideal study windows, and see where she spends time on her phone (games vs. study apps).

2. **College CS Major with Part-Time Job (“Mark, 20”)**  
   - Takes five courses, works 15 hours/week as a tech support; wants to optimize study vs. work balance.  
   - Often loses track of time scrolling social media.  
   - Needs voice prompts while commuting and clear visualizations of time usage.

3. **Early‐Career Engineer (“Sophia, 25”)**  
   - Works 9 AM–5 PM in engineering service management, commutes 1 hour each way.  
   - Seeks to integrate exercise, side‐project coding, and relaxation breaks without compromising performance at work.  
   - Will rely on AI suggestions for micro‐breaks, meal reminders, and weekly energy summaries.

---

## 6. User Journey & Use Cases

### 6.1 First-Time Onboarding
1. User downloads LockIn AI from the App Store.  
2. Upon launch, the app displays a welcome screen summarizing benefits: “Optimize your day by syncing your schedule with your real activity.”  
3. User creates an account via email/password (Supabase Auth).  
4. “Grant Permissions” screens appear in sequence:  
   - Calendar access (read-only) to import existing events (optional).  
   - Device Activity Monitoring (Device Activity API) to collect app usage data.  
   - Push Notifications (optional) for urgent alerts.  
5. Onboarding flow ends with a guided example: “Enter your first event (e.g., ‘Math Exam – Nov 3, 2 PM–5 PM’).”  
6. User lands on the “Dashboard,” showing today’s events (none yet) and a button: “Run AI Analysis.”

---

### 6.2 Daily Workflow
1. **Morning (8 AM)**  
   - App fetches previous day’s device activity (via background fetch).  
   - Supabase Function triggers AI analysis:  
     - Compares yesterday’s “planned vs. actual.”  
     - Generates a “Daily Productivity Report” (text + optional voice read-out).  
   - User receives a notification: “Your summary is ready: Yesterday, you spent 2 hrs on productivity apps; consider focusing blocks earlier today.”  
   - User opens LockIn AI, taps “Listen” to hear the AI’s voice summary.

2. **Throughout the Day**  
   - App passively collects device usage (e.g., “You are spending 30 min on social media this morning”).  
   - If user requests (“Hey LockIn, how much time did I spend reading code yesterday?”), the voice assistant retrieves info in real time.

3. **Schedule Adjustment**  
   - User notices AI suggestion: “Your focus dips around 4 PM. Move your ‘Team Meeting’ to 10 AM instead.”  
   - Taps “Apply Suggestion,” which:  
     - Updates event in Supabase.  
     - Syncs to Apple Calendar (if integrated).  
   - Updated event now appears in Calendar view with a colored border: “AI-recommended adjustment.”

---

### 6.3 Weekly Reflection
- Every Sunday evening, LockIn AI sends a push notification: “Weekly Check-In: Review your brain pattern summary.”  
- The user opens LockIn AI, navigates to the “Insights” tab, and sees:  
  - A bar chart (by day) of “Focused Time vs. Distraction Time.”  
  - A timeline view highlighting “High Productivity Windows” identified by AI.  
  - A “Goal Recommendations” card:  
    - “You maintained a consistent 2-hour writing block each day. Increase to 2.5 hours next week.”  
    - “You spent 5 hours on video streaming—consider limiting streaming to weekends.”  
- The user can ask the voice assistant: “Suggest three ways to reduce streaming on weekdays,” and receive an AI-generated answer.

---

## 7. Functional Requirements

| **ID** | **Requirement**                                                                                           | **Priority** |
|--------|-----------------------------------------------------------------------------------------------------------|--------------|
| FR1    | User registration & authentication via Supabase Auth (email/password).                                    | High         |
| FR2    | Secure storage of user profile and preferences in Supabase (PostgreSQL).                                  | High         |
| FR3    | Manual creation, editing, and deletion of calendar events.                                                | High         |
| FR4    | Optional import (read-only) of existing Apple Calendar events.                                            | Medium       |
| FR5    | Collection of device activity data via Apple’s Device Activity API; local encryption & periodic upload. | High         |
| FR6    | Cloud Function to interface with OpenAI API for AI analysis.                                              | High         |
| FR7    | “Daily Productivity Report” triggered each morning, accessible in “Insights” tab.                         | High         |
| FR8    | Voice recording & transcription (Apple Speech Framework or OpenAI Speech-to-Text).                        | Medium       |
| FR9    | Text-to-Speech for AI summaries (AVSpeechSynthesizer or OpenAI TTS).                                      | Medium       |
| FR10   | Dynamic suggestions button: “Apply AI Recommendation” that adjusts calendar events.                       | High         |
| FR11   | Push notification engine (Supabase Realtime + FCM/APNs) for urgent “focus alerts.”                        | Medium       |
| FR12   | Secure RLS policies in Supabase to restrict user data access.                                             | High         |
| FR13   | SwiftUI interface for event list, calendar view, heatmap visualization, and AI chat interface.           | High         |
| FR14   | Offline support: cache last 24 hours of device activity & schedule data; queue uploads when online.       | Medium       |
| FR15   | Privacy settings screen to toggle activity monitoring, AI notifications, and voice assistant.             | High         |

---

## 8. Non-Functional Requirements

- **Security & Privacy**  
  - All communications between the app and Supabase must use TLS/HTTPS.  
  - Device activity data remains encrypted on the device (e.g., using Apple’s CryptoKit) until securely uploaded to Supabase.  
  - Supabase RLS enforces that each row (e.g., activity record, schedule entry) is accessible only by its owner.  
  - No personal data is shared with OpenAI beyond anonymized context and hashed user IDs.

- **Performance**  
  - App launch time < 2 seconds (cold).  
  - AI analysis response within 3–5 seconds (once the cloud function is invoked).  
  - Device activity sync (< 200 KB per 6 hours) to conserve bandwidth.

- **Scalability**  
  - Supabase instance configured to auto-scale (read replicas + horizontal scaling) to support thousands of concurrent users.  
  - Cloud Functions should be stateless, supporting concurrent invocations for AI requests.

- **Reliability & Availability**  
  - 99.9% uptime for critical services (authentication, schedule CRUD).  
  - Offline mode must allow read access to last cached schedule and activity heatmap.

- **UX Responsiveness**  
  - SwiftUI animations and transitions should target 60 fps on supported devices.  
  - Support Dark Mode and Dynamic Type for accessibility.

---

## 9. Technical Architecture

### 9.1 High-Level Diagram

+----------------------+ +-----------------------+ +------------------+
| | | | | |
| iOS App (SwiftUI) | <---- | Supabase Backend | <---- | OpenAI API |
| | | (Auth / Database / | ↔ | (GPT, Speech, |
| - Schedule UI | | Functions / Storage)| | TTS, STT) |
| - Device Activity | +-----------------------+ +------------------+
| - Voice Interface |
| - Local Cache (Core)|
| Data + Encryption)|
+----------------------+


1. **iOS App (SwiftUI)**  
   - **UI Layers**:  
     - Dashboard (today’s events, quick insights)  
     - Calendar View (scrollable weekly/monthly)  
     - Activity Heatmap (color‐coded by focus/distraction)  
     - AI Chat Interface (text & voice)  
     - Settings & Privacy  
   - **Local Data Layer**:  
     - Core Data / SQLite to store:  
       1. Temporarily cached schedule entries (in case offline).  
       2. Raw device activity logs (encrypted).  
     - Background Tasks (BGProcessing) for periodic upload.  
   - **Device Activity Integration**:  
     - Uses Device Activity API (requires to define `FamilyActivityScheduler` + `FamilyActivityCenter` usage) to collect categories: “Productivity,” “Social,” “Entertainment,” etc.  
   - **Networking**:  
     - RESTful calls to Supabase Auth endpoints for login/signup.  
     - Supabase Realtime for push notifications on AI suggestion results.  
     - Supabase Functions (HTTP endpoints) to trigger GPT analysis (POST payload).

2. **Supabase Backend**  
   - **Auth**  
     - Email/password + optional OAuth (e.g., Apple ID).  
   - **Database (PostgreSQL)**  
     - **Tables**:  
       1. `users` (id, email, display_name, preferences… )  
       2. `schedules` (id, user_id, title, description, start_ts, end_ts, tags, ai_modified_flag)  
       3. `device_activity` (id, user_id, app_identifier, category, duration_seconds, timestamp)  
       4. `ai_reports` (id, user_id, date, summary_text, suggestions_json)  
       5. `voice_transcripts` (id, user_id, transcript_text, timestamp)  
       6. `settings` (user_id, notifications_enabled, activity_monitoring_enabled, voice_assistant_enabled)  
   - **Row Level Security**  
     - Every table is tagged with `FOR SELECT / INSERT / UPDATE / DELETE WHERE user_id = auth.uid()`.  
     - API Keys restricted; only Supabase Functions can bypass with service key for AI calls.  
   - **Storage**  
     - Stores user‐uploaded media (if future feature: screenshots, voice recordings).  
     - All media buckets have private access policies.

3. **Supabase Functions**  
   - **AI Analysis Endpoint** (`/functions/aiAnalyze`)  
     - Accepts JSON payload:  
       ```json
       {
         "user_id": "uuid-from-jwt",
         "schedules": [ { "title": "Math Exam", "start_ts": 1719993600, "end_ts": 1719997200, "tags": ["Exam", "Math"] }, … ],
         "device_summary": [ { "hour": "2025-05-30T09:00:00Z", "category_breakdown": { "Productivity": 1800, "Social": 1200, "Entertainment": 600 } }, … ]
       }
       ```
     - Server-side logic:  
       1. Compose a structured prompt to OpenAI:  
          > “Given the following upcoming events and user’s past 7 days of device usage (hourly), identify productivity peaks/lows, and recommend schedule adjustments. Provide output in JSON with keys: `peak_hours`, `recommended_shifts`, `break_suggestions`, `motivational_notes`.”  
       2. Call `openai.chat.completions.create({ model: "gpt-4-turbo", messages: [ … ] })`.  
       3. Parse and validate the JSON response.  
       4. Insert a new row into `ai_reports` for that user with `summary_text` and raw `suggestions_json`.  
       5. Return HTTP 200 + `suggestions_json` to the iOS app.

   - **Voice Processing Endpoint** (`/functions/aiVoiceQuery`)  
     - Accepts:  
       1. Base64‐encoded audio (or URL to S3 upload).  
       2. Context payload (recent schedule + activity summary).  
     - Workflow:  
       1. Forward audio to OpenAI’s Speech-to-Text endpoint to obtain transcript.  
       2. Forward (transcript + context) to GPT for conversational response.  
       3. If user requested voice response, forward GPT’s text to OpenAI TTS or return text for local AVSpeechSynthesizer to read.

---

## 10. Data Model & Schemas

### 10.1 `users` Table

| Column          | Type        | Constraints                       | Description                            |
|-----------------|-------------|-----------------------------------|----------------------------------------|
| `id`            | UUID        | PRIMARY KEY, DEFAULT `gen_random_uuid()` | Unique user identifier (auth.uid())   |
| `email`         | TEXT        | UNIQUE, NOT NULL                  | User’s email address                   |
| `display_name`  | TEXT        |                                   | Optional display name                  |
| `created_at`    | TIMESTAMP   | DEFAULT `now()`                   | Account creation timestamp             |
| `updated_at`    | TIMESTAMP   | DEFAULT `now()` ON UPDATE `now()` | Last profile update                    |

---

### 10.2 `schedules` Table

| Column           | Type        | Constraints                                              | Description                                       |
|------------------|-------------|----------------------------------------------------------|---------------------------------------------------|
| `id`             | UUID        | PRIMARY KEY, DEFAULT `gen_random_uuid()`                  | Unique schedule entry ID                          |
| `user_id`        | UUID        | REFERENCES `users(id)` ON DELETE CASCADE                  | Owner of this schedule entry                       |
| `title`          | TEXT        | NOT NULL                                                  | Event title (e.g., “Study: Physics”)               |
| `description`    | TEXT        |                                                            | Optional description or notes                     |
| `start_ts`       | TIMESTAMP   | NOT NULL                                                  | Start time                                         |
| `end_ts`         | TIMESTAMP   | NOT NULL                                                  | End time                                           |
| `tags`           | TEXT[]      | DEFAULT `{}`                                              | Array of tags (e.g., `{“Exam”,”Hackathon”}`)       |
| `ai_modified`    | BOOLEAN     | DEFAULT `FALSE`                                            | Flag if last change was AI suggested                |
| `created_at`     | TIMESTAMP   | DEFAULT `now()`                                           | Entry creation time                                |
| `updated_at`     | TIMESTAMP   | DEFAULT `now()` ON UPDATE `now()`                        | Last modification time                             |

---

### 10.3 `device_activity` Table

| Column            | Type        | Constraints                                                  | Description                                                  |
|-------------------|-------------|--------------------------------------------------------------|--------------------------------------------------------------|
| `id`              | UUID        | PRIMARY KEY, DEFAULT `gen_random_uuid()`                      | Unique ID                                                     |
| `user_id`         | UUID        | REFERENCES `users(id)` ON DELETE CASCADE                      | Owner of this activity log                                    |
| `app_identifier`  | TEXT        | NOT NULL                                                     | Bundle ID (e.g., `com.apple.Pages`)                           |
| `category`        | TEXT        | NOT NULL                                                     | Category (e.g., `Productivity`, `Social`, `Entertainment`)    |
| `duration_s`      | INTEGER     | NOT NULL                                                     | Total seconds used in this timestamp window                   |
| `timestamp`       | TIMESTAMP   | NOT NULL                                                     | Start of the time bucket (e.g., `2025-05-30 09:00:00`)         |
| `created_at`      | TIMESTAMP   | DEFAULT `now()`                                              | Ingestion time                                                 |

---

### 10.4 `ai_reports` Table

| Column             | Type        | Constraints                                                  | Description                                                  |
|--------------------|-------------|--------------------------------------------------------------|--------------------------------------------------------------|
| `id`               | UUID        | PRIMARY KEY, DEFAULT `gen_random_uuid()`                      | Unique report ID                                              |
| `user_id`          | UUID        | REFERENCES `users(id)` ON DELETE CASCADE                      | Owner of this report                                          |
| `report_date`      | DATE        | NOT NULL                                                     | Date covered by this report (e.g., yesterday’s date)         |
| `summary_text`     | TEXT        | NOT NULL                                                     | Human-readable summary                                        |
| `suggestions_json` | JSONB       | NOT NULL                                                     | Structured AI suggestions (e.g., recommended_shifts, peaks)  |
| `created_at`       | TIMESTAMP   | DEFAULT `now()`                                              | Timestamp of AI completion                                    |

---

## 11. Privacy & Security

1. **Device Activity Data**  
   - Users must explicitly grant “Screen Time & Activity” permission.  
   - All activity data is encrypted on the device (AES-256 via CryptoKit).  
   - Only aggregated metrics (hourly buckets) are uploaded; no granular timestamps of each app launch.  
   - Users can toggle “Activity Monitoring” off at any time; historical data remains until they manually purge it.

2. **Supabase Security**  
   - Enforce Row Level Security so that each user can only `SELECT`/`INSERT`/`UPDATE`/`DELETE` their own rows.  
   - Supabase JWT tokens expire after 1 hour; auto-refresh via secure refresh tokens.  
   - Database backups are encrypted at rest; Supabase’s managed service handles encryption key rotation.

3. **OpenAI Data Handling**  
   - Supabase Functions forward only anonymized context (user_id is hashed, schedules/events are described generically).  
   - No user PII (email, real name) is sent to OpenAI.  
   - All prompts and responses are retained in Supabase (in `ai_reports`) for auditing, but raw Machine Learning logs (OpenAI) are not stored locally.

4. **Compliance & Permissions**  
   - The app’s App Store listing explicitly notes “Requires Screen Time & Activity authorization.”  
   - In-app Privacy Policy and Terms of Service detail how data is stored, processed, and shared.  
   - Users can export or delete all their data via “Account Settings > Delete My Data.”

---

## 12. UI/UX Guidelines

### 12.1 Color & Branding
- **Primary Color**: Deep Blue (#1A1F71) – conveys focus, intelligence.  
- **Accent Color**: Vibrant Teal (#00CFC1) – highlights actionable items (e.g., “Apply Suggestion” button).  
- **Secondary Color**: Soft Gray (#F2F2F7) for backgrounds and subtle dividers.  
- **Typography**:  
  - Headings: SF Pro Display, Bold, 24 px / 20 px.  
  - Body: SF Pro Text, Regular, 17 px.  
  - Monospaced (Heatmap): SF Mono, Regular, 14 px.

---

### 12.2 Layout & Navigation
- **Tab Bar (Bottom)**  
  1. Dashboard (Today’s Overview)  
  2. Calendar (Scrollable Weekly / Monthly View)  
  3. Insights (Heatmap + Reports)  
  4. AI Coach (Chat & Voice)  
  5. Settings (Privacy, Account, Integrations)

- **Dashboard Screen**  
  - Top: “Good Morning, [User]” + date.  
  - Middle: Today’s Events (List of cards showing event title, time, AI/­adjusted indicator).  
  - Bottom: “Quick Actions” (Run AI Analysis, Record Query, Import Calendar).

- **Calendar Screen**  
  - SwiftUI `LazyVGrid` of days horizontally scrollable, with colored blocks for events.  
  - “Overlay Mode” toggle: shows activity heatmap overlay (semi-transparent blocks behind events indicating time consumption).

- **Insights Screen**  
  - Activity Heatmap (7×24 grid: x=day, y=hour).  
  - “Daily Report” card: Expandable text excerpt from AI summary.  
  - “Weekly Trends” chart: Matplotlib–powered bar chart showing daily focus vs distraction (optional in later MVP stages).

- **AI Coach Screen**  
  - Chat interface: SwiftUI `ScrollView` of message bubbles (user on right, AI on left).  
  - Microphone button floating bottom-right; tapping launches a modal recording view.  
  - When AI responds, text appears with optional “Play” icon to read aloud.

- **Settings Screen**  
  - Toggles: “Activity Monitoring,” “Push Notifications,” “Voice Assistant.”  
  - Account: “Change Email,” “Logout,” “Delete Account.”  
  - Privacy Policy & Terms of Service links.

---

## 13. Technical Roadmap & Milestones

| **Milestone**                  | **Timeline**         | **Description**                                                                                                                                                        |
|--------------------------------|----------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **M1: Core Setup & Auth**      | Weeks 1–2            | - Initialize SwiftUI project structure. <br> - Configure Supabase project (Auth + Postgres). <br> - Implement email/password registration & login.                    |
| **M2: Schedule CRUD & UI**     | Weeks 3–5            | - Build SwiftUI screens for creating/editing/deleting events. <br> - Define `schedules` table schema. <br> - Integrate Supabase REST calls to persist events.         |
| **M3: Device Activity Logging**| Weeks 6–8            | - Integrate Device Activity API (request permissions). <br> - Store hourly summaries locally (Core Data). <br> - Upload activity logs to Supabase periodically.       |
| **M4: AI Analysis MVP**        | Weeks 9–11           | - Implement Supabase Functions scaffolding. <br> - Compose basic GPT prompt for “peak hours” & “shift recommendations.” <br> - SwiftUI “Insights” tab to display result.|
| **M5: Calendar Visualization**  | Weeks 12–14          | - Build SwiftUI Calendar View with colored blocks. <br> - Overlay activity heatmap behind events. <br> - Handle conflict warnings (if events overlap activity).      |
| **M6: Voice Interface MVP**    | Weeks 15–17          | - Add “Record Audio” modal & integrate Apple Speech-to-Text. <br> - Create Supabase Function to handle voice queries. <br> - Return text response in chat UI.           |
| **M7: Text-to-Speech Integration**| Weeks 18–19        | - Use AVSpeechSynthesizer to read AI summaries. <br> - Add “Play” button next to each AI message.                                                                       |
| **M8: Push Notification Engine**| Weeks 20–21         | - Hook Supabase Realtime to send push notifications for urgent alerts (e.g., “You spent too much time watching videos”). <br> - Integrate with APNs.                   |
| **M9: Polish & Beta Release**   | Weeks 22–24         | - UI/UX refinements, bug fixes, performance optimizations. <br> - Create App Store listing & build TestFlight beta. <br> - Draft marketing copy and support docs.      |
| **M10: Public Launch**          | Week 26             | - Final QA, App Store submission, launch. <br> - Monitor user feedback, crash analytics, begin V1.1 feature planning.                                                 |

---
