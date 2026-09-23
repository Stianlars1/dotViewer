import type { Metadata } from "next";
import Link from "next/link";
import { AuroraBackground } from "../../components/aurora-background";
import { CookieSettingsButton } from "../../components/cookie-settings-button";
import { LogoAnimated } from "../../components/logo-animated";
import { getSiteConfig } from "../../lib/site-config";
import { CREATOR_NAME, CREATOR_URL, DBHOST_URL } from "../../lib/structured-data";
import chrome from "../security/page.module.css";
import styles from "./page.module.css";

export const metadata: Metadata = {
  alternates: { canonical: "/privacy" },
  description:
    "What the dotViewer app and dotviewer.app collect: the app sends nothing; the website counts visits without cookies and uses cookies only with your consent.",
  title: "Privacy",
};

const UPDATED = "23 September 2026";
// When the log stopped setting cookies and storing identifiers. Fixed, unlike UPDATED.
const COOKIELESS_SINCE = "23 September 2026";

export default function PrivacyPage() {
  const config = getSiteConfig();
  const repoHref = config.repoUrl ?? "https://github.com/Stianlars1/dotViewer";
  // Google's session cookie is named after the measurement ID without its "G-".
  const googleCookies = config.googleAnalyticsId ? `_ga, _ga_${config.googleAnalyticsId.replace(/^G-/, "")}` : null;

  return (
    <div className={chrome.page}>
      <AuroraBackground />
      <header className={chrome.nav}>
        <div className={chrome.wrap}>
          <div className={chrome.navInner}>
            <Link aria-label="dotViewer home" className={chrome.brand} href="/">
              <span className={chrome.brandMark}>
                <LogoAnimated interactive={false} size={28} />
              </span>
              <span>dotViewer</span>
            </Link>
            <nav aria-label="Primary" className={chrome.navLinks}>
              <Link href="/download">Download</Link>
              <Link href="/security">Security</Link>
              <a href={repoHref}>GitHub</a>
            </nav>
            <Link className={chrome.navCta} href="/">
              Back to home
            </Link>
          </div>
        </div>
      </header>

      <main className={chrome.main}>
        <div className={chrome.wrap}>
          <section className={chrome.hero}>
            <div className={chrome.eyebrow}>Privacy</div>
            <h1 className={chrome.title}>
              The app sends nothing. The website counts visits without cookies, and uses cookies only if you say yes.
            </h1>
            <p className={chrome.body}>
              dotViewer is made by <a href={CREATOR_URL}>{CREATOR_NAME}</a> in Norway. This page covers the dotViewer
              app and this website. Last updated {UPDATED}.
            </p>
          </section>

          <article className={styles.article}>
            <section>
              <h2>The app</h2>
              <ul>
                <li>
                  Previews are made on your Mac. The Quick Look extensions that read your files run in Apple&apos;s
                  sandbox without network access.
                </li>
                <li>dotViewer has no analytics, no telemetry and no update checks. It sends nothing about you or your files anywhere.</li>
                <li>
                  Its only network listener is local: it accepts connections from this Mac only (127.0.0.1) and passes
                  what you type after ⌘F to an open preview.
                </li>
                <li>
                  A Markdown file you preview can point to images on the web. With <em>Show images</em> on, those
                  images load when you view the file, as they would in any Markdown viewer.
                </li>
                <li>
                  If a later version adds update checks or usage statistics, this page will describe them before that
                  version ships, and usage statistics will be off unless you turn them on.
                </li>
              </ul>
            </section>

            <section>
              <h2>This website</h2>
              <ul>
                <li>
                  Until you choose, the site sets no cookies and stores nothing on your device. A banner asks whether it
                  may use cookies for two purposes, described under <a href="#cookies">Cookies</a>; saying no changes
                  nothing else about the site.
                </li>
                <li>
                  The site is hosted by Vercel, which handles each request, including your IP address, to serve it (
                  <a href="https://vercel.com/legal/privacy-policy">Vercel&apos;s privacy policy</a>).
                </li>
                <li>
                  Vercel Web Analytics counts page views without cookies. It tells visitors apart within a single day
                  only, by a hash it then discards (
                  <a href="https://vercel.com/docs/analytics/privacy-policy">how it works</a>).
                </li>
                <li>
                  The site also keeps its own log so visits and downloads can be counted. For each page view and
                  download click it stores the time, the page (without anything after “?” in its address), the name of
                  the site that linked here (not the full address), campaign tags in the link, the country (worked out
                  from the IP address), the browser and
                  operating system family — such as “Safari on macOS” — and whether the request looks like a bot. For
                  downloads it adds which link was used and which version. It stores no IP address, no city and no full
                  browser string.
                </li>
                <li>
                  To count visitors per day, each entry also gets a code made from your IP address and browser together
                  with a random value that changes every day. The random value is deleted when the day is over; after
                  that the code can&apos;t be traced back to you or linked to another day.
                </li>
                <li>
                  That log is kept in a PostgreSQL database on <a href={DBHOST_URL}>dbHost</a>, another project by the
                  same creator.
                </li>
                <li>
                  Until {COOKIELESS_SINCE} the site set two cookies for this log without asking — <code>dv_vid</code>, a
                  random visitor ID kept for up to two years, and <code>dv_sid</code> for a single visit — and also stored
                  the city, the full browser string, the full address of the site that linked here and the whole page
                  address. It stopped that day, browsers that still have those cookies are told to delete them, and the
                  IDs, cities, browser strings, linking addresses and the parts of page addresses after “?” already in
                  the log were deleted.
                </li>
              </ul>
            </section>

            <section id="cookies">
              <h2>Cookies</h2>
              <ul>
                <li>
                  Only with your consent, apart from the one that remembers your choice. Choose in the banner, and
                  change your mind at any time: <CookieSettingsButton className={styles.inlineButton} />.
                </li>
              </ul>
              <div className={styles.tableScroll}>
                <table className={styles.table}>
                  <thead>
                    <tr>
                      <th scope="col">Cookie</th>
                      <th scope="col">What it is for</th>
                      <th scope="col">Kept</th>
                      <th scope="col">Goes to</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td>
                        <code>dv_consent</code>
                      </td>
                      <td>Remembers your choice, including a no. Needed for the banner to work, so set without asking.</td>
                      <td>12 months</td>
                      <td>dotViewer</td>
                    </tr>
                    <tr>
                      <td>
                        <code>dv_visitor</code>
                      </td>
                      <td>
                        <strong>dotViewer statistics:</strong> a random ID stored with your visits in the log above, to
                        see whether people come back and which visits lead to a download.
                      </td>
                      <td>13 months</td>
                      <td>dotViewer</td>
                    </tr>
                    {googleCookies ? (
                      <tr>
                        <td>
                          <code>{googleCookies}</code>
                        </td>
                        <td>
                          <strong>Google Analytics:</strong> tells your visits apart in Google&apos;s reports.
                        </td>
                        <td>13 months</td>
                        <td>Google</td>
                      </tr>
                    ) : null}
                  </tbody>
                </table>
              </div>
              <ul>
                {googleCookies ? (
                  <li>
                    With Google Analytics allowed, your browser loads Google&apos;s script and sends Google the pages you
                    visit here, how you arrived, and your device, browser and approximate location. Google Ireland
                    Limited is responsible for it in Europe; Google may process the data in the United States, where
                    Google LLC is certified under the EU–US Data Privacy Framework (
                    <a href="https://policies.google.com/privacy">Google&apos;s privacy policy</a>). Google&apos;s script is
                    not loaded at all without your consent.
                  </li>
                ) : null}
                <li>
                  Turning something off deletes its cookies at once. Browsers that send Global Privacy Control are
                  treated as if you said no, and the banner is not shown.
                </li>
                <li>
                  The legal basis for these cookies is your consent (GDPR Article 6(1)(a) and section 3-15 of the
                  Norwegian Electronic Communications Act). The cookieless log and the daily codes rest on a legitimate
                  interest in knowing how many people visit and download (Article 6(1)(f)).
                </li>
                <li>
                  Visitor IDs are removed from the log after 13 months. Each choice is recorded — when, what you
                  chose, and the visitor ID if you allowed dotViewer statistics — and kept for 2 years as proof of
                  consent.
                </li>
              </ul>
            </section>

            <section>
              <h2>Downloads</h2>
              <ul>
                <li>
                  The installer is served by GitHub from the project&apos;s releases. GitHub counts downloads and handles
                  the request under the{" "}
                  <a href="https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement">
                    GitHub Privacy Statement
                  </a>
                  .
                </li>
                <li>
                  Installing with Homebrew is covered by{" "}
                  <a href="https://docs.brew.sh/Analytics">Homebrew&apos;s own analytics</a>, which you can turn off with{" "}
                  <code>brew analytics off</code>. Homebrew publishes install counts per package.
                </li>
              </ul>
            </section>

            <section>
              <h2>Your rights</h2>
              <ul>
                <li>
                  The log exists to learn how many people visit and download dotViewer and how they find it. Without
                  your consent nothing is stored on or read from your device except the cookie that remembers your
                  choice.
                </li>
                <li>
                  Without dotViewer statistics the log holds nothing that links rows to you. You can withdraw consent
                  at any time under Cookie settings, and ask what is kept, or object, through{" "}
                  <a href={`${repoHref}/issues`}>GitHub issues</a> or the <a href={CREATOR_URL}>creator&apos;s site</a>.
                </li>
                <li>
                  You can complain to <a href="https://www.datatilsynet.no/">Datatilsynet</a>, the Norwegian data
                  protection authority.
                </li>
              </ul>
            </section>
          </article>
        </div>
      </main>
    </div>
  );
}
