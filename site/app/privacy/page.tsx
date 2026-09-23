import type { Metadata } from "next";
import Link from "next/link";
import { AuroraBackground } from "../../components/aurora-background";
import { LogoAnimated } from "../../components/logo-animated";
import { getSiteConfig } from "../../lib/site-config";
import { CREATOR_NAME, CREATOR_URL, DBHOST_URL } from "../../lib/structured-data";
import chrome from "../security/page.module.css";
import styles from "./page.module.css";

export const metadata: Metadata = {
  alternates: { canonical: "/privacy" },
  description: "What the dotViewer app and dotviewer.app collect: the app sends nothing; the website sets no cookies and keeps a small log without identifiers.",
  title: "Privacy",
};

const UPDATED = "23 September 2026";
// When the log stopped setting cookies and storing identifiers. Fixed, unlike UPDATED.
const COOKIELESS_SINCE = "23 September 2026";

export default function PrivacyPage() {
  const config = getSiteConfig();
  const repoHref = config.repoUrl ?? "https://github.com/Stianlars1/dotViewer";

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
            <h1 className={chrome.title}>The app sends nothing. The website keeps a small log without identifiers.</h1>
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
                <li>No cookies and no local storage, so there is no consent banner.</li>
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
                  The site also keeps its own log so downloads can be counted. For each page view and download click it
                  stores the time, the page, the name of the site that linked here (not the full address), campaign tags
                  in the link, the country (worked out from the IP address, which is not stored), the browser and
                  operating system family — such as “Safari on macOS” — and whether the request looks like a bot. For
                  downloads it adds which link was used and which version. It stores no IP address, no visitor or
                  session ID, no city and no full browser string.
                </li>
                <li>
                  That log is kept in a PostgreSQL database on <a href={DBHOST_URL}>dbHost</a>, another project by the
                  same creator.
                </li>
                <li>
                  Until {COOKIELESS_SINCE} the site set two cookies for this log — <code>dv_vid</code>, a random visitor
                  ID kept for up to two years, and <code>dv_sid</code> for a single visit — and also stored the city and
                  the full browser string. It no longer does, and browsers that still have the cookies are told to
                  delete them on their next visit. The IDs, cities and browser strings already in the log were deleted
                  the same day.
                </li>
                <li>Google Analytics is not used.</li>
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
                  The log exists to learn how many people download dotViewer and how they find it — a legitimate
                  interest under GDPR Article 6(1)(f). Nothing is stored on or read from your device.
                </li>
                <li>
                  Because the log holds no identifiers, it cannot link rows to you. You can still ask what is kept, or
                  object, through <a href={`${repoHref}/issues`}>GitHub issues</a> or the{" "}
                  <a href={CREATOR_URL}>creator&apos;s site</a>.
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
