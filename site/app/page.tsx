import Image from "next/image";
import Link from "next/link";
import styles from "./page.module.css";
import { getProductStats } from "../lib/product-stats";
import { getSiteConfig } from "../lib/site-config";

const heroMeta = ["Free download", "Notarized DMG workflow", "macOS 15+"];

const limitations = [
  "Some file types are still claimed by macOS system preview handlers. For example, `.html` stays with the native HTML Quick Look renderer.",
  "TypeScript `.ts` can still be routed by macOS as MPEG-2 transport stream video in some situations, which is a platform routing limitation rather than a dotViewer bug.",
  "dotViewer improves Quick Look where third-party extensions are allowed. It does not override every system-owned preview path in macOS.",
];

const installSteps = [
  {
    step: "01",
    title: "Download the latest DMG",
    body: "Use the site’s stable `/download` link so the primary call to action can stay constant while the installer asset changes release to release.",
  },
  {
    step: "02",
    title: "Drag dotViewer into Applications",
    body: "Install it like a normal Mac app. No custom launcher flow, no account wall, and no extra setup ritual.",
  },
  {
    step: "03",
    title: "Launch once, then use Quick Look",
    body: "That first launch registers the extension. After that, select a supported file in Finder and press Space.",
  },
];

const faqs = [
  {
    question: "What files is dotViewer built for?",
    answer:
      "dotViewer is meant for markdown, config files, logs, dotfiles, and source code that are faster to inspect in Finder than to open in an editor. It is especially useful for technical files Quick Look handles poorly by default.",
  },
  {
    question: "Does it replace Finder's built-in Quick Look for every file type?",
    answer:
      "No. Some file types are owned by system handlers in macOS, and those still take priority. dotViewer is designed to improve the technical file cases where third-party Quick Look extensions can realistically help.",
  },
  {
    question: "Is the app signed and notarized?",
    answer:
      "The public download path is designed around a Developer ID signed, notarized DMG so installation feels trustworthy and Gatekeeper-friendly for normal macOS users.",
  },
  {
    question: "How do I install and activate it?",
    answer:
      "Download the DMG, drag dotViewer into Applications, launch it once, and then use Quick Look in Finder. That first launch registers the extension and makes the preview flow available.",
  },
  {
    question: "Why use this instead of opening an editor?",
    answer:
      "Because many file checks do not deserve a full context switch. dotViewer is built for the small, frequent inspections that happen while browsing files, reviewing project structure, or checking technical documents in Finder.",
  },
];

export default function HomePage() {
  const stats = getProductStats();
  const config = getSiteConfig();
  const releasesHref = config.releasesUrl ?? "#install";
  const repoHref = config.repoUrl ?? releasesHref;
  const showDevNotice = !config.hasDownloadSource && process.env.NODE_ENV !== "production";
  const appUrl = new URL("/", config.siteUrl).toString();
  const downloadUrl = new URL("/download", config.siteUrl).toString();
  const softwareSchema = {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    name: "dotViewer",
    applicationCategory: "DeveloperApplication",
    applicationSubCategory: "macOS Quick Look extension",
    operatingSystem: "macOS 15.0+",
    url: appUrl,
    downloadUrl,
    isAccessibleForFree: true,
    description:
      "Preview markdown, config, logs, and code files in Quick Look instead of opening an editor for every small check.",
  };
  const faqSchema = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: faqs.map((item) => ({
      "@type": "Question",
      name: item.question,
      acceptedAnswer: {
        "@type": "Answer",
        text: item.answer,
      },
    })),
  };
  const proofStats = [
    { value: stats.fileTypes, label: "built-in file types" },
    { value: stats.extensions, label: "registered extensions" },
    { value: stats.filenameMappings, label: "filename mappings" },
    { value: stats.grammars, label: "highlight query files" },
  ];

  return (
    <div className={styles.page}>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(softwareSchema) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqSchema) }}
      />

      <div className={styles.backdrop} aria-hidden="true">
        <div className={styles.orbOne} />
        <div className={styles.orbTwo} />
      </div>

      <a className={styles.skipLink} href="#main-content">
        Skip to content
      </a>

      <header className={styles.header}>
        <div className={styles.shell}>
          <nav className={styles.nav} aria-label="Primary">
            <Link className={styles.brand} href="/">
              <Image
                className={styles.brandMark}
                src="/brand/dotviewer-icon-light.png"
                alt=""
                width={32}
                height={32}
                sizes="32px"
              />
              <span>dotViewer</span>
            </Link>

            <div className={styles.navLinks}>
              <a href="#features">Features</a>
              <a href="#coverage">Coverage</a>
              <a href="#install">Install</a>
              <a href="#faq">FAQ</a>
            </div>

            <Link className={styles.navCta} href="/download">
              Download
            </Link>
          </nav>
        </div>
      </header>

      <main className={styles.main} id="main-content">
        <div className={styles.shell}>
          <section className={styles.hero}>
            <div className={styles.heroInner}>
              <div className={styles.eyebrow}>Better Quick Look for technical files</div>

              <h1 className={styles.heroTitle}>
                Preview markdown, config, and code files Finder doesn&apos;t handle well.
              </h1>

              <p className={styles.heroBody}>
                dotViewer keeps small file checks small. Inspect technical files instantly in Quick
                Look instead of opening an editor every time you need to verify one detail.
              </p>

              <div className={styles.heroActions}>
                <Link className={styles.primaryAction} href="/download">
                  Download for macOS
                </Link>
                <a className={styles.secondaryAction} href={releasesHref}>
                  View releases
                </a>
              </div>

              <div className={styles.heroMeta} aria-label="Product details">
                {heroMeta.map((item) => (
                  <span className={styles.heroMetaItem} key={item}>
                    {item}
                  </span>
                ))}
              </div>
            </div>
          </section>

          <section className={styles.showcaseSection} aria-label="Product preview">
            <div className={styles.showcaseFrame}>
              <div className={styles.showcaseBar}>
                <div className={styles.windowDots}>
                  <span />
                  <span />
                  <span />
                </div>
                <div className={styles.showcaseLabel}>Finder Quick Look</div>
                <div className={styles.showcaseLabel}>dotViewer</div>
              </div>

              <div className={styles.showcaseGrid}>
                <div className={styles.codePanel}>
                  <div className={styles.panelHeader}>
                    <span>settings.production.json</span>
                    <span>JSON</span>
                  </div>
                  <div className={styles.codeBody}>
                    <div className={styles.lineNumbers}>1{"\n"}2{"\n"}3{"\n"}4{"\n"}5{"\n"}6</div>
                    <div className={styles.codeLines}>
                      {"{"}
                      {"\n"}  <span className={styles.tokenString}>"theme"</span>:{" "}
                      <span className={styles.tokenString}>"finder-light"</span>,
                      {"\n"}  <span className={styles.tokenString}>"markdown"</span>: {"{"}
                      {"\n"}    <span className={styles.tokenString}>"rendered"</span>:{" "}
                      <span className={styles.tokenKeyword}>true</span>
                      {"\n"}  {"},"}
                      {"\n"}  <span className={styles.tokenComment}>// Quick check, no editor launch</span>
                      {"\n"}
                      {"}"}
                    </div>
                  </div>
                </div>

                <div className={styles.sideStack}>
                  <div className={styles.renderedPanel}>
                    <div className={styles.panelHeader}>
                      <span>README.md</span>
                      <span>Rendered Markdown</span>
                    </div>
                    <div className={styles.renderedBody}>
                      <h2>Release Notes</h2>
                      <p>Readable headings, spacing, and lists directly inside Finder.</p>
                      <ul>
                        <li>Preview docs without context switching</li>
                        <li>Read structure instead of raw clutter</li>
                        <li>Keep moving after the check</li>
                      </ul>
                    </div>
                  </div>

                  <div className={styles.showcaseNote}>
                    Built for markdown, configs, logs, dotfiles, and code that deserve more than a
                    generic icon or a plain text dump.
                  </div>
                </div>
              </div>
            </div>
          </section>

          <section className={styles.proofStrip} aria-label="Coverage summary">
            {proofStats.map((item) => (
              <article className={styles.proofItem} key={item.label}>
                <div className={styles.proofValue}>{item.value}</div>
                <div className={styles.proofLabel}>{item.label}</div>
              </article>
            ))}
          </section>

          <section className={styles.section} id="features">
            <div className={styles.sectionIntro}>
              <div className={styles.kicker}>Features</div>
              <h2 className={styles.sectionTitle}>Readable previews with more space and less friction.</h2>
              <p className={styles.sectionBody}>
                The goal is not to turn Finder into a full IDE. The goal is to make the files you
                check constantly feel legible, fast, and calm enough to trust at a glance.
              </p>
            </div>

            <div className={styles.story}>
              <div className={styles.storyCopy}>
                <div className={styles.storyKicker}>Preview source</div>
                <h3 className={styles.storyTitle}>Syntax highlighting that makes technical files readable at a glance.</h3>
                <p className={styles.storyBody}>
                  Code, configs, and structured text are presented with theme-aware highlighting so
                  the preview feels intentionally designed for Quick Look instead of dumped into a
                  browser-shaped box.
                </p>
              </div>

              <div className={styles.storyVisual}>
                <div className={styles.miniWindow}>
                  <div className={styles.panelHeader}>
                    <span>.env.production</span>
                    <span>Environment</span>
                  </div>
                  <div className={styles.miniBody}>
                    <div>APP_ENV=production</div>
                    <div>FEATURE_MARKDOWN_RENDERED=true</div>
                    <div>THEME=glass-light</div>
                    <div>PREVIEW_WIDTH=comfortable</div>
                  </div>
                </div>
              </div>
            </div>

            <div className={styles.story}>
              <div className={styles.storyVisual}>
                <div className={styles.markdownCard}>
                  <div className={styles.panelHeader}>
                    <span>Project Notes</span>
                    <span>Markdown</span>
                  </div>
                  <div className={styles.markdownCardBody}>
                    <h3>Rendered when you want it.</h3>
                    <p>
                      Review notes, install steps, tables, or project docs without leaving Finder.
                    </p>
                  </div>
                </div>
              </div>

              <div className={styles.storyCopy}>
                <div className={styles.storyKicker}>Preview markdown</div>
                <h3 className={styles.storyTitle}>Read markdown as source or rendered output.</h3>
                <p className={styles.storyBody}>
                  dotViewer is useful when you want to inspect the actual file and when you just
                  want to read the content. That switch matters for READMEs, notes, changelogs, and
                  project documentation.
                </p>
              </div>
            </div>

            <div className={styles.story}>
              <div className={styles.storyCopy}>
                <div className={styles.storyKicker}>Coverage</div>
                <h3 className={styles.storyTitle}>Broader support for the files Quick Look often leaves awkward.</h3>
                <p className={styles.storyBody}>
                  dotViewer is aimed at the files technical users actually touch every day:
                  extensions, filename-based mappings, and highlighting rules that make Finder more
                  useful without pretending macOS allows third-party previews to override everything.
                </p>
              </div>

              <div className={styles.storyVisual}>
                <div className={styles.coverageCard}>
                  <div className={styles.coverageRow}>
                    <span>Markdown and docs</span>
                    <strong>Readable</strong>
                  </div>
                  <div className={styles.coverageRow}>
                    <span>Configs and dotfiles</span>
                    <strong>Highlighted</strong>
                  </div>
                  <div className={styles.coverageRow}>
                    <span>Logs and plain text</span>
                    <strong>Scannable</strong>
                  </div>
                  <div className={styles.coverageRow}>
                    <span>System-owned types</span>
                    <strong>Called out honestly</strong>
                  </div>
                </div>
              </div>
            </div>
          </section>

          <section className={styles.section} id="coverage">
            <div className={styles.limitationsPanel}>
              <div className={styles.limitationsCopy}>
                <div className={styles.kicker}>Coverage And Limits</div>
                <h2 className={styles.sectionTitle}>Broad enough to be useful, honest enough to be trusted.</h2>
                <p className={styles.sectionBody}>
                  dotViewer is strongest where Finder gives third-party Quick Look extensions room
                  to improve the experience. When macOS owns the preview path, the limitation is
                  stated directly instead of buried behind vague claims.
                </p>
              </div>

              <ul className={styles.limitationsList}>
                {limitations.map((item) => (
                  <li key={item}>{item}</li>
                ))}
              </ul>
            </div>
          </section>

          <section className={styles.section} id="install">
            <div className={styles.sectionIntro}>
              <div className={styles.kicker}>Install</div>
              <h2 className={styles.sectionTitle}>A normal Mac install flow, kept intentionally short.</h2>
              <p className={styles.sectionBody}>
                The install path is meant to feel familiar: direct download, drag to Applications,
                launch once, then use Quick Look in Finder.
              </p>
            </div>

            <div className={styles.installGrid}>
              {installSteps.map((item) => (
                <article className={styles.installCard} key={item.step}>
                  <div className={styles.installStep}>{item.step}</div>
                  <h3 className={styles.installTitle}>{item.title}</h3>
                  <p className={styles.installBody}>{item.body}</p>
                </article>
              ))}
            </div>

            <div className={styles.installNote}>
              Free download in the current public release phase. Distributed through a Developer ID
              signed, notarized DMG workflow so installation feels familiar and trustworthy on
              macOS.
            </div>

            {showDevNotice ? (
              <p className={styles.devNotice}>
                Local preview note: no GitHub repo slug or direct download URL is configured in this
                environment yet, so the latest-release download route will fall back to the install
                section until deployment is wired up.
              </p>
            ) : null}
          </section>

          <section className={styles.section} id="faq">
            <div className={styles.sectionIntro}>
              <div className={styles.kicker}>FAQ</div>
              <h2 className={styles.sectionTitle}>Short answers before installation.</h2>
            </div>

            <div className={styles.faqShell}>
              <div className={styles.faqList}>
                {faqs.map((item) => (
                  <details className={styles.faqItem} key={item.question}>
                    <summary>{item.question}</summary>
                    <div className={styles.faqContent}>{item.answer}</div>
                  </details>
                ))}
              </div>

              <div className={styles.ctaPanel}>
                <h2 className={styles.ctaTitle}>A better Quick Look flow for the files Finder leaves awkward.</h2>
                <p className={styles.ctaBody}>
                  dotViewer is for the moments when you just need to inspect the file, understand
                  what it is, and keep moving.
                </p>
                <div className={styles.ctaActions}>
                  <Link className={styles.primaryAction} href="/download">
                    Download for macOS
                  </Link>
                  <a className={styles.secondaryAction} href={releasesHref}>
                    View releases
                  </a>
                </div>
              </div>
            </div>
          </section>
        </div>
      </main>

      <footer className={styles.footer}>
        <div className={styles.shell}>
          <div className={styles.footerBar}>
            <div className={styles.footerCopy}>
              <strong>dotViewer</strong>
              <br />
              Better Quick Look for markdown, config, logs, and code files on macOS.
            </div>

            <div className={styles.footerLinks}>
              <a href="#features">Features</a>
              <a href="#coverage">Coverage</a>
              <a href="#install">Install</a>
              <a href="#faq">FAQ</a>
              <a href={releasesHref}>Releases</a>
              <a href={repoHref}>GitHub</a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
