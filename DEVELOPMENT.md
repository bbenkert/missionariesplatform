Got it. Here’s your spec, **customized for Rails 8 + Hotwire (Turbo/Stimulus) + Postgres + Active Storage + Devise + Pundit**, using **Resend** for email. I also fold in **missionary verification** and **hostile-area Safety Mode** you’re enforcing on Lift the Mission.

---

# 0) Purpose & Vision (Rails 8)

* **Goal:** Prayer-first platform where missionaries share updates & prayer needs; supporters follow and pray.
* **Tone:** Secure, simple, beautiful, low-friction. **Mobile-first** and installable as a **PWA**.
* **Initial scale:** \~1k missionary profiles, \~2k authenticated users, \~1k visitors/day on a single VPS.

**Rails stack defaults**

* **Rails 8**, **Hotwire** (Turbo + Stimulus), **PostgreSQL**, **Active Storage**, **Active Job**, **Action Mailer**.
* **Auth:** Devise (email/password, optional magic link via Devise extensions).
* **AuthZ:** Pundit policies.
* **Admin:** Admin namespace (Hotwire) or gem (e.g., Administrate).
* **Background jobs:** Active Job + adapter (Solid Queue / Sidekiq / GoodJob).
* **Email:** Resend (SMTP or API).
* **Rate limiting:** rack-attack.
* **CSP & security headers:** Rails CSP + secure\_headers (optional).
* **Auditing:** PaperTrail or Audited.
* **Notifications:** Noticed (in-app + mail).

---

# 1) User Types & Roles

* **Anonymous Visitor** — browse public profiles/updates/requests, limited search.
* **Supporter** — follow missionaries, “I prayed” (idempotent), encourage/comment, receive digests.
* **Missionary** — manage profile, post updates & prayer requests, upload media, manage followers.
* **Church Leader / Org Admin** — manage missionaries linked to their org; dashboards; export.
* **Global Admin** — moderation, feature flags, audit logs, configuration, suspensions.

**Permissions (Pundit examples)**

* Missionary: CRUD own `Profile/Update/PrayerRequest/Media`.
* Supporter: create `PrayerAction` (enforced unique per request+user), follows, comments.
* Org Admin: manage missionaries scoped to `organization_id`, run reports, moderate.
* Global Admin: unrestricted.

---

# 2) Core Domain Model (Rails)

Use UUID PKs and Postgres niceties.

* **Organization**: `name`, `slug`, `settings (jsonb)`, `contact`.
* **User**: `name`, `email (citext unique)`, Devise fields, `role enum` (`supporter|missionary|admin`), `settings (jsonb)`.
* **Membership**: `user_id`, `organization_id`, `role enum`.
* **Missionary**: `organization_id?`, `user_id?`, `slug`, `bio`, `region`, `sensitive_flag:boolean`, `public_profile_level enum('public','limited','private')`, `pseudonym`, `public_region`, `safety_options (jsonb)`, `avatar`/`header` (Active Storage), `links (jsonb)`, `status enum('pending','approved','rejected')`.
* **Update**: `missionary_id`, `title`, `body_rich` (Tiptap/ActionText), `published_at`, `visibility enum`, `tsvector`.
* **PrayerRequest**: `missionary_id`, `title`, `body`, `tags (string[] or jsonb)`, `status enum(open|answered)`, `urgency enum(low|med|high)`, `published_at`, `tsvector`.
* **PrayerAction**: `prayer_request_id`, `user_id`, timestamps. **UNIQUE(prayer\_request\_id, user\_id)**.
* **Follow**: `user_id`, `followable (polymorphic)`, `notifications_enabled:boolean`. **UNIQUE(user,followable)**.
* **MediaAsset**: (use Active Storage + metadata: alt\_text, content\_type, size; polymorphic owner via attachments).
* **Notification**: `user_id`, `type`, `payload (jsonb)`, `read_at`.
* **DigestJob / EmailLog**: MTA ids, sent/bounce/complaint timestamps.
* **AuditLog**: `actor_id`, `action`, `subject (polymorphic)`, `ip`, `user_agent`, `meta (jsonb)`.

**Postgres**

* Enable `pgcrypto` (UUIDs), `citext`, `unaccent`, `pg_trgm`.
* Add `GIN` indexes for `tsvector` fields; `gin_trgm_ops` for slugs/names.

---

# 3) MVP Feature Set

## 3.1 Public & Discovery

* Landing page + CTA.
* Search & filter (region, tags, organization) via Postgres FTS + trigram.
* SEO-friendly missionary profiles (Open Graph, canonical tags).
* Public “Updates” and “Prayer Requests” honoring visibility & safety flags.

## 3.2 Accounts & Onboarding

* Devise email auth (password or optional magic-link flow).
* **Missionary application wizard**: bio, avatar, calling story, region, newsletter link, safety needs (pseudonym, profile level).
  New applications → `status: :pending` until **admin approval**.
* Org onboarding: claim or create org; invite missionaries/staff (optional MVP).

## 3.3 Prayer & Engagement

* CRUD **PrayerRequest** with status/urgency/tags.
* **“I prayed”**: single-tap, server-enforced idempotency; live count via Turbo Streams.
* **Follow** missionaries/orgs; per-follow notification prefs.
* Comments/Encouragement (toggleable; moderation hooks).

## 3.4 Email & Notifications (Resend)

* Weekly digest to supporters for **their follows** (recent updates + urgent requests).
* Optional instant email for **high-urgency** requests.

* Unsubscribe + granular preferences.
* Webhooks: store bounces/complaints in `email_logs`.

## 3.5 Organization Dashboards

* List missionaries by org; filters; export CSV/PDF (Stimulus controller + responders).
* Activity snapshot (new followers, prayer counts, recent updates).

## 3.6 Admin & Moderation

* `/admin` namespace (Hotwire) or **Administrate**:

  * Users, Missionaries (approve/reject), Updates, Requests, Comments.
  * Flag queue; feature flags; audit log viewer.

## 3.7 Media & Storage

* **Active Storage** on S3-compatible storage (Backblaze/Wasabi).
* Validations (type/size), server variants (thumbs/banners) via `image_processing` (**vips** preferred).
* **Alt text required** for accessibility.

## 3.8 PWA & Mobile UX

* `public/manifest.webmanifest` (icons 192/512).
* Service Worker (Workbox or custom) with:

  * Static assets: **precache**.
  * Public pages: **Stale-While-Revalidate**.
  * Authed/API: **Network-First** + offline fallback.
* Optional Background Sync to queue “I prayed”.

---

# 4) Post-MVP

* i18n (UI + content), RTL.
* Web Push (VAPID) with per-missionary topics + quiet hours.
* Rich comments with mute/report.
* Private prayer rooms (invite-only).
* CSV import/export for missionary data and activity.
* Partner **read-only API** (keys + rate limits).
* Analytics: privacy-friendly script + internal aggregates.
* Scheduling/embargo for updates.
* External donation links management.
* A11y polish: keyboard shortcuts, reduced-motion, high-contrast theme.

---

# 5) Non-Functional Requirements

## 5.1 Security

* Rails CSRF; HTTPS + HSTS.
* CSP (`config/content_security_policy.rb`) + `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`.
* **rack-attack** rate limits for auth & POSTs.
* Database constraints: NOT NULL, FKs, uniques (esp. `prayer_actions`).
* Secrets via env/credentials; least-priv S3 IAM; key rotation.
* Audit logging for admin/auth events (PaperTrail/Audited).
* Image safety: MIME sniffing, size caps, strip metadata.

## 5.2 Privacy & Safety

* **Sensitive region mode**: obfuscate precise location; restrict fields by profile level.
* Per-field visibility (public/followers/org/admin) via serializers/decorators.
* GDPR-style export/delete.
* Moderation workflow + retention policy.

## 5.3 Performance

* Targets: LCP < 2.5s (4G), TTI < 3s, CLS < 0.1.
* CDN for assets/images; HTTP caching with ETag/Last-Modified.
* Index hot queries (missionary listing, feeds, prayed checks).
* Background jobs for heavy tasks (emails, images, fan-out).

## 5.4 Accessibility

* WCAG 2.1 AA: semantic HTML, proper labels, focus states.
* Contrast ≥ 4.5:1; **alt text required**.
* `aria-live` for live prayer counts (debounced Turbo stream updates).

## 5.5 Observability & Ops

* Error tracking (e.g., Sentry/ScoutAPM) w/ release tags.
* Structured logs + request IDs.
* Health checks, uptime monitoring, job-failure alerts.
* Backups: daily Postgres snapshots + tested restore runbook.
* Envs: Dev/Staging/Prod; config per env.

---

# 6) API & Integration Expectations

* **Internal separation:** use serializers (e.g., ActiveModel::Serializer / Blueprinter) so UI ≠ DB.
* **Public Read API (later):** token/OAuth, rate limited, versioned.
* **Webhooks:** publish/update events; email provider events.
* **Storage:** presigned uploads; lifecycle rules for media retention.

---

# 7) Search & Filtering

* Primary: Postgres FTS (`to_tsvector` + `GIN`) on `updates`, `prayer_requests`; `pg_trgm` for fuzzy.
* Optional: external search (Meilisearch/Algolia/OpenSearch).
* Filters: region, tags, org, status, urgency, updated\_at.

---

# 8) Reporting & Exports

* Org admin: CSV/PDF of missionaries, latest requests, follower counts, engagement.
* Global admin: system-wide aggregates (privacy-preserving).

---

# 9) Theming & Design System

* Tailwind utility system.
* Tokens: spacing, radius, type scale, colors (light/dark).
* Reusable components (ViewComponent or partials): Card, List, Modal, Toast, Tabs, Badge, EmptyState, DataTable, Pagination, ConfirmDialog.
* Motion: subtle, honor `prefers-reduced-motion`.

---

# 10) Testing & QA (Rails)

* **Unit tests** for domain logic (idempotent PrayerAction, safety masks).
* **Integration/system tests** for auth flows, CRUD, permissions (Devise helpers + Capybara/Cuprite).
* **Accessibility checks** (axe-core via Capybara driver) in CI.
* **Smoke tests** post-deploy (health, login, create request, follow, digest job).
* **Load test** hot paths (list missionaries; concurrent “I prayed”).

**Tooling**

* RSpec (or Minitest), FactoryBot, Faker, Shoulda-Matchers.
* SimpleCov for coverage; target near 100% on policies & domain.
* RuboCop (Rails + Performance), Brakeman (SAST), Bundler-Audit.

---

# 11) Deployment & Hosting (VPS-friendly)

* Single VPS (2 vCPU / 4 GB): Rails app (Puma), Redis (cache/queues), Postgres (or small managed DB), reverse proxy (Nginx/Caddy).
* Object storage: S3-compatible + Cloudflare CDN.
* Background jobs: Active Job adapter (Solid Queue/Sidekiq/GoodJob) + scheduler (`whenever` or adapter cron).
* Blue/green or rolling deploys; aim for zero-downtime (`puma phased-restart` or Kamal).
* Backups & restore playbook (pg\_dump, test monthly).

---

# 12) Acceptance Criteria (MVP DoD)

* Visitors can discover missionaries & read updates on mobile/desktop; **Lighthouse PWA pass**.
* Supporter signup → follow missionary → tap **“I prayed” once per request**; counts update instantly (Turbo); dupe taps blocked server-side (unique index).
* Missionary can create/edit profile; post update & prayer request with images; **alt text required**.
* Org admin can view dashboard, filter, and export CSV.
* Weekly digest emails to opted-in supporters; unsubscribe works; bounces tracked (Resend webhooks).
* **Sensitive region toggle** hides precise location for public/unauth.
* Security: CSRF, rate limits, CSP, admin audit logs.
* Observability: error tracking active; health checks pass; daily DB backups verified.

---

# 13) Roadmap Snapshot

* **MVP (Weeks 1–3):** Auth (Devise) + Profiles + Prayer Requests + “I prayed” + Digest + Org Dashboard + PWA basics + Deploy.
* **V1.1 (Weeks 4–6):** Follow/notifications polish, comments/encouragement, CSV import, better Postgres search.
* **V2:** Private prayer rooms, partner read API, Web Push, translations, richer analytics.

---

# 14) Nice-to-Have

* Scheduled posts, templated updates, translation assistance.
* Media galleries; lightweight video (external embeds).
* Admin insights (low-engagement risk flags).
* Onboarding tours & “getting started” checklists.

---

## Rails-Specific Notes (quick refs)

* **Devise**: email as **citext** with uniqueness; optional password-less/magic link extension.
* **Pundit**: write policies per resource; test deny/permit combos.
* **rack-attack**: throttle login & POST endpoints; safe-list admin IP ranges if desired.
* **Active Storage**: install **vips** on server; strip EXIF; define variants (`thumb`, `banner`).
* **Safety Mode rendering**:

  * `public` → normal.
  * `limited` → pseudonym + broad region, `noindex`, blur faces (optional job), mask dates (“this month”).
  * `private` → unlisted, excluded from search/sitemap/PWA; **only approved followers** (if enabled) can see.
* **Resend (SMTP)** (example env):

  ```
  MAILER_SMTP_ADDRESS=smtp.resend.com
  MAILER_SMTP_PORT=587
  MAILER_USER_NAME=apikey
  MAILER_PASSWORD=YOUR_RESEND_API_KEY
  MAILER_FROM_ADDRESS=noreply@liftthemission.com
  MAILER_FROM_NAME="Lift the Mission"
  ```

  (Or use a Resend API transport gem if preferred.)

---

If you want, I can turn this into a **Rails app template checklist** (commands, migrations, models, policies, initializers) and drop in **ready-to-run policy specs + db indexes** tuned for the “I prayed” idempotency and Safety Mode.
