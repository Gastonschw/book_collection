<!-- AI-assisted — prompt: "Implement Google OAuth with Devise + OmniAuth per CSCE 431 primer"; documented implementation, verified startup, test results, and remaining lab work. -->
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
2. An ignored, empty `.env` has been prepared locally. On another checkout,
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
No actual Google client credentials were supplied or verified during implementation.

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
docker exec -w /csce431/test_app magical_haibt bin/rails test
docker exec -e CHROME_NO_SANDBOX=1 -w /csce431/test_app magical_haibt bin/rails test:system
docker exec -w /csce431/test_app magical_haibt bundle exec rubocop
docker exec -w /csce431/test_app magical_haibt bundle exec brakeman -o output.html
docker exec -w /csce431/test_app magical_haibt bundle exec brakeman
```

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

- RSpec: **10 examples, 0 failures** (mocked OAuth success, protected routes,
  invalid credentials, logout, stored-location return, and existing book specs).
- Minitest: **7 tests / 15 assertions, 0 failures or errors**.
- Browser system suite: **4 tests / 8 assertions, 0 failures or errors**.
- RuboCop: passed after correcting a route-file whitespace offense.
- Real browser: development redirects to the sign-in page; form uses POST,
  includes a CSRF token, and disables Turbo. An isolated test-only mock server
  exercised the actual Google button, callback, green success flash, welcome,
  book content, stored-location return, and logout. A POST without a CSRF token
  returned **422**. Temporary smoke code and its records were removed.
- Actual Google consent/account chooser/token exchange: **not verified**.

OmniAuth mock mode is enabled **only in the test environment**. The expected
invalid-credentials scenario may log an OmniAuth error even though its test passes.

Brakeman 8.0.6: **0 scan errors, 1 weak-confidence warning**:

| Check | File | Finding | Mitigation |
| --- | --- | --- | --- |
| EOLRails / Unmaintained Dependency | `Gemfile.lock:280` | Support for Rails 8.0.5.1 ends on 2026-11-07. | Upgrade to a supported Rails release and rerun all suites before that date. |

This is an upcoming support deadline, not evidence Rails is already unsupported.
No warning is suppressed or ignored. Brakeman exits **3** while this finding is
present, so the CI security-scan job remains non-green. A framework upgrade is
separate from the OAuth change. `output.html` is generated locally and ignored by Git.

## Heroku and remaining submission work

No existing Heroku deployment was established from repository configuration or
GitHub deployment records. No apps, add-ons, or dashboards were created/modified.
The Admin migration is included and OAuth credentials are ENV-only. Production
requires both Google config vars and its own exact callback URL added in Google
Cloud. Existing production multi-database/Solid configuration and live deployment
have not been verified; local test success is not a Heroku readiness certification.

Human-only work remains: Google Cloud configuration and real login, required
screenshots (including the Brakeman report), Heroku/Papertrail setup and evidence,
written answers, AI citation, and final PDF submission.

## AI-assisted change record

Prompt: **Implement Google OAuth with Devise + OmniAuth per CSCE 431 primer**.
Changed source/config/test files carry AI-assistance comments. `Gemfile.lock` is
Bundler-generated from the annotated Gemfile and has no added comment because its
machine-readable lockfile format must be preserved. The schema was generated by
Rails from the annotated Admin migration.

Changes cover OAuth dependencies and ENV handling; Admin model/migration;
Devise initializer/translations; routes and authentication controllers; login,
welcome, flash views/styles; shared mock helpers; RSpec/Minitest adaptations;
CI suite execution; and this setup/verification report.
