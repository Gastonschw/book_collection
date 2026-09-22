<!-- AI-assisted — prompts: "Implement Google OAuth with Devise + OmniAuth per CSCE 431 primer" and "Get Heroku up"; documented OAuth, single-database deployment, verification, and remaining account authorization. -->
# Book Collection — CSCE 431

Rails 8 / PostgreSQL title-only book CRUD with Google-only Devise Admin sign-in.
The OAuth lab does not require the older author/price/date or UserBook association features.

## Local development

The verified existing course container is `magical_haibt`, using
`paulinewade/csce431:sp26v1`. It mounts `C:\Users\Gasto\csce431` at `/csce431`,
runs PostgreSQL in the container, and publishes port 3000. The repository is
`/csce431/test_app` inside it. The checked-in Dockerfile is a separate **production**
image recipe, not the course development container setup.

1. Start Docker Desktop, then start the existing container if stopped:
   ```powershell
   docker start magical_haibt
   ```
2. This checkout has an ignored local `.env`. On another checkout,
   copy `.env.example` to `.env` **only if `.env` does not already exist**.
   Fill in `GOOGLE_OAUTH_CLIENT_ID` and `GOOGLE_OAUTH_CLIENT_SECRET` yourself.
   `dotenv-rails` loads this file in development/test; production uses platform ENV.
   Never put credentials into source, the example file, commits, or PR descriptions.
3. In Google Cloud, configure a Web application OAuth client with this exact callback:
   `http://localhost:3000/admins/auth/google_oauth2/callback`.
   Configure the consent screen and add yourself as a test user or publish as appropriate.
4. Install dependencies, migrate, and run the app:
   ```powershell
   docker exec -w /csce431/test_app magical_haibt bundle install
   docker exec -w /csce431/test_app magical_haibt bin/rails db:migrate
   docker exec -it -w /csce431/test_app magical_haibt bin/rails server --binding=0.0.0.0
   ```
5. Open `http://localhost:3000`. Restart Rails after changing `.env` because
   the provider credentials are read at application initialization.

The server starts without credentials so the signed-out page and mock tests can
be checked, but **real Google login requires your configured client credentials**.
Real local Google sign-in was subsequently confirmed by the developer.

## Authentication behavior

- Books routes require an authenticated Admin. `/` is the Books index.
- Google sign-in is a CSRF-protected POST with Turbo disabled on the form.
- Successful callbacks find/create an Admin by email and store profile fields
  without a password or Google access token in the database.
- Login returns to the originally requested page, or the Books home otherwise.
  The callback preserves that destination across Devise's session reset.
- Flash messages are escaped and rendered once by the existing Rails 8 layout.
- The existing dedicated book deletion confirmation route is retained.
- As specified by the lab handoff, **any successfully authenticated Google account
  can become an Admin** and access the shared collection. This is authentication,
  not an administrator allowlist or per-user book authorization.
- The handoff's GET Sign Out route is retained. For a production security policy,
  change it to DELETE with a CSRF-protected form to prevent forced logout via GET.

## Tests and security scan

Run these separately; `bin/rails test test:system` did not execute the browser
suite in this environment:

```powershell
docker exec -e RAILS_ENV=test -w /csce431/test_app magical_haibt bin/rails db:migrate
docker exec -w /csce431/test_app magical_haibt bundle exec rspec
docker exec -u postgres magical_haibt psql -c "CREATE ROLE root LOGIN SUPERUSER;"
try {
  docker exec -e RAILS_ENV=test -e "DATABASE_URL=postgresql://root@localhost/test_app_test?host=/var/run/postgresql" -w /csce431/test_app magical_haibt bin/rails test
  docker exec -e RAILS_ENV=test -e CHROME_NO_SANDBOX=1 -e "DATABASE_URL=postgresql://root@localhost/test_app_test?host=/var/run/postgresql" -w /csce431/test_app magical_haibt bin/rails test:system
} finally {
  docker exec -u postgres magical_haibt psql -c "DROP ROLE root;"
}
docker exec -w /csce431/test_app magical_haibt bundle exec rubocop
docker exec -w /csce431/test_app magical_haibt bundle exec brakeman -o output.html
docker exec -w /csce431/test_app magical_haibt bundle exec brakeman
```

The temporary `root` database role above is **only for fixture loading in this
root-run course container**, and assumes no pre-existing PostgreSQL `root` role.
Do not recreate/remove a role you did not create. Rails 8 validates all foreign
keys during Minitest fixture loading, including the new Solid Queue tables;
this updates `pg_catalog.pg_constraint` and requires PostgreSQL superuser access.
The course app role remains non-superuser. Local Unix sockets use peer
authentication; the temporary role has no password and cannot log in over TCP.
CI already uses its isolated PostgreSQL service's `postgres` administrator.
Never apply this test setup to Heroku or grant the production app superuser.

`CHROME_NO_SANDBOX=1` is an explicit opt-in for **root-run test Chrome in this
course container only**; omit it on normal non-root hosts/CI. Tests otherwise keep
Chrome's sandbox enabled. The container needed these browser libraries installed:

```powershell
docker exec magical_haibt apt-get update
docker exec magical_haibt apt-get install -y --no-install-recommends libnspr4 libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libxkbcommon0 libasound2t64 libgbm1 libxcomposite1 libxdamage1 libxfixes3 libxrandr2
```

Selenium downloaded Chrome into its cache. On this container, it also needed a
`/usr/local/bin/google-chrome` symlink to the downloaded binary. This environment
repair is already applied locally; a fresh container needs a discoverable Chrome
installation. GitHub CI installs Chrome directly and runs RSpec, request tests,
and system tests independently.

The first remote CI run exposed pre-existing non-executable `bin/` scripts.
Their Git executable bits are restored, and `.gitattributes` enforces LF script
endings so Linux CI and production do not depend on Windows mount permissions.

Verified locally:

- RSpec: **11 examples, 0 failures** (mocked OAuth account creation/reuse,
  protected routes, invalid credentials, logout, stored-location return, and book specs).
- Minitest: **7 tests / 15 assertions, 0 failures or errors**.
- Browser system suite: **4 tests / 8 assertions, 0 failures or errors**.
- RuboCop: passed after correcting a route-file whitespace offense.
- Real browser: development redirects to the sign-in page; form uses POST,
  includes a CSRF token, and disables Turbo. An isolated test-only mock server
  exercised the actual Google button, callback, green success flash, welcome,
  book content, stored-location return, and logout. A POST without a CSRF token
  returned **422**. Temporary smoke code and its records were removed.
- Actual local Google sign-in: **confirmed by the developer** after supplying credentials.

OmniAuth mock mode is enabled **only in the test environment**. The expected
invalid-credentials scenario may log an OmniAuth error even though its test passes.

The updated course reference is adapted to the existing `spec/feature` convention:
login uses the shared mock and callback, book creation follows the **New book**
link from the authenticated home page and checks the persisted title, and a
returning-account scenario verifies an existing Admin is reused. OmniAuth test
mode is set inside `Rails.application.configure` and in `spec/rails_helper.rb`;
mock state is restored even when a scenario fails.

Brakeman 8.0.6: **0 scan errors, 1 weak-confidence warning**:

| Check | File | Finding | Mitigation |
| --- | --- | --- | --- |
| EOLRails / Unmaintained Dependency | `Gemfile.lock:280` | Support for Rails 8.0.5.1 ends on 2026-11-07. | Upgrade to a supported Rails release and rerun all suites before that date. |

This is an upcoming support deadline, not evidence Rails is already unsupported.
No warning is suppressed or ignored. Brakeman exits **3** while this finding is
present, so the CI security-scan job remains non-green. A framework upgrade is
separate from the OAuth change. `output.html` is generated locally and ignored by Git.

## Heroku deployment and remaining submission work

Deployed on 2026-09-22: **[Book Collection](https://gastonschw-book-collection-6f3a4ed066c6.herokuapp.com/)**.
Heroku app: `gastonschw-book-collection`, US Cedar / Heroku-24, release **v5**
from commit **7126bb7**. One **Basic** web dyno is up; PostgreSQL
`postgresql-clear-36593` uses **Essential-0**; Papertrail
`papertrail-objective-56880` uses the free **Choklad** plan.

Paid deployment was explicitly approved instead of waiting for student credits.
The recurring web/database rate is approximately **$12/month**, prorated for usage,
before taxes or credits; release/one-off dynos also consume billable usage.
Scaling web to zero stops web usage but does **not** stop database charges.

Live verification passed: `/up` HTTP 200, signed-out Books redirect, sign-in page
and compiled stylesheet, and HTTP 422 for an OAuth POST without a CSRF token.
A Basic one-off dyno verified PostgreSQL book create/read/update/delete and Solid
Cache against the deployed database (19 tables); its transaction was rolled back.

The production callback is now registered. A fresh live browser check reached
Google's normal sign-in page; `redirect_uri_mismatch` no longer occurred.
The registered additional redirect URI is:

```text
https://gastonschw-book-collection-6f3a4ed066c6.herokuapp.com/admins/auth/google_oauth2/callback
```

Keep the localhost redirect URI for development. Completing real Google consent
and the return to the app, then authenticated browser CRUD/sign-out, still needs
the developer's own browser session. No production authentication bypass or
OmniAuth mock mode was enabled.

Papertrail provisioning and its attached HTTPS drain to
`logs.collector.na-01.cloud.solarwinds.com` were verified. **Event delivery in the
Papertrail dashboard has not been verified**: the managed browser has no Heroku
web session, and the legacy Papertrail CLI plugin requires a token the add-on did
not supply. Open the [Papertrail dashboard through Heroku SSO](https://addons-sso.heroku.com/apps/gastonschw-book-collection/addons/papertrail)
in your own logged-in browser, trigger an app request, and capture the log events.

The Heroku build succeeded with the pinned Ruby 3.4.6, but warned that Ruby 3.4.10
is available. Runtime/framework upgrades remain separate from this deployment.

### Production configuration

- `Gemfile` reads Ruby 3.4.6 from `.ruby-version`; Bundler locks the runtime version.
- `Procfile` runs `bundle exec rails db:migrate` in the release phase, then Puma
  for the web process. Puma uses Heroku's assigned `PORT`.
- Production uses one PostgreSQL database via Heroku's `DATABASE_URL`. Solid
  Cache, Queue, and Cable share it with the application. Their former standalone
  schema files are replaced by a normal migration; no additional databases or
  Redis add-ons are needed. Releases migrate rather than reload/drop schemas.
- `GOOGLE_OAUTH_CLIENT_ID` and `GOOGLE_OAUTH_CLIENT_SECRET` must be set as Heroku
  config vars. Local `.env` is ignored and is not loaded in production.
- HTTPS proxy handling, secure cookies, and tagged STDOUT logging are enabled.
  Heroku captures STDOUT; the provisioned Papertrail add-on has an attached log drain.
- No separate worker dyno is required for current book CRUD/OAuth. If background
  jobs are added, enable the existing Solid Queue Puma integration or explicitly
  provision a worker; database-backed enqueueing alone does not process jobs.
- Local Active Storage is not durable on Heroku. The current app has no uploads;
  configure external object storage before introducing them.

Verified against an isolated PostgreSQL database with `RAILS_ENV=production`:
book persistence; Solid Cache read/write; Solid Queue enqueueing and execution of
the stored job payload; Solid Cable message persistence; asset precompilation;
and a real Puma process serving `/up`, protected Books redirects, the sign-in
form and stylesheet, a Google authorization redirect with the HTTPS callback,
and HTTP 422 for an OAuth POST without its CSRF token. This did **not** exercise
a running queue worker or complete Google's real token exchange on Heroku.

### Account setup and deployment

1. Authorize the container CLI using `docker exec -it magical_haibt heroku login`.
   Complete the printed URL in your own browser; never share passwords/API tokens.
2. Check existing apps, usage, and available student credits before provisioning.
   The [GitHub Student offer](https://www.heroku.com/github-students/) provides
   $13/month for 24 months. Basic web ($7/month rate) plus Essential-0 Postgres
   ($5/month rate) fits that allowance only if credits are active and not consumed
   elsewhere. Release/one-off dynos also consume usage. Resources remain billable
   after credits expire. Student credits do not cover third-party add-ons.
3. Create or select a personal Cedar app and one Essential-0 PostgreSQL database.
   Set the Google config vars through Heroku's Settings dashboard without putting
   their values in shell history or commits. Do not change the local callback.
4. Deploy the reviewed feature-branch commit through Heroku's Ruby buildpack.
   Check the release migration and scale exactly one Basic web dyno. Deploying
   does not require merging the GitHub PR or enabling automatic deployments.
5. Obtain the actual app URL from Heroku, including any randomized hostname
   suffix. Add `https://<actual-app-host>/admins/auth/google_oauth2/callback` as an
   additional authorized redirect URI on the existing Google Web OAuth client.
6. Verify live `/up`, sign-in, real Google login, book CRUD, and sign-out. Install
   Papertrail only after confirming its available plan is free; trigger a request
   and verify its app log events before taking the required screenshots.

Human-only submission work remains: Google Cloud callback registration and real
deployed login, authenticated browser CRUD/sign-out, Papertrail event inspection,
required screenshots (including Brakeman and Heroku/Papertrail evidence), written
answers, AI citation, and final PDF submission.

## AI-assisted change record

Prompt: **Implement Google OAuth with Devise + OmniAuth per CSCE 431 primer**.
Changed source/config/test files carry AI-assistance comments. `Gemfile.lock` is
Bundler-generated from the annotated Gemfile and has no added comment because its
machine-readable lockfile format must be preserved. The schema was generated by
Rails from the annotated Admin and shared Solid-table migrations.

Changes cover OAuth dependencies and ENV handling; Admin model/migration;
Devise initializer/translations; routes and authentication controllers; login,
welcome, flash views/styles; shared mock helpers; RSpec/Minitest adaptations;
CI suite execution; Heroku startup/release configuration and single-database
Solid migration; and this setup/verification report.
