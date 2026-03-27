import Image from "next/image";
import Link from "next/link";
import styles from "./page.module.css";
import { getProductStats } from "../lib/product-stats";
import { getSiteConfig } from "../lib/site-config";

const proofPoints = [
  {
    tag: "Finder flow",
    title: "Inspect files without breaking your train of thought.",
    body: "Open markdown, config, logs, and code straight from Quick Look instead of jumping into an editor for every small check.",
  },
  {
    tag: "Preview quality",
    title: "Readable syntax highlighting, rendered markdown, and useful structure.",
    body: "Move from a generic icon or plain text dump to a preview you can actually scan in seconds.",
  },
  {
    tag: "macOS fit",
    title: "A better Quick Look experience, not a separate workflow.",
    body: "dotViewer stays inside Finder so file inspection feels native, fast, and lightweight.",
  },
];

const features = [
  {
    title: "Syntax-highlighted previews",
    body: "Preview source code, configs, and structured text with theme-aware highlighting that stays readable in Finder.",
    bullets: [
      "Code and config files are easier to scan at a glance",
      "Theme-aware presentation keeps contrast controlled",
      "Designed for Quick Look, not a browser screenshot pasted into Finder",
    ],
  },
  {
    title: "Markdown that can be read raw or rendered",
    body: "Switch between markdown source and rendered output when you need to inspect the file format and the final result.",
    bullets: [
      "Useful for READMEs, notes, release docs, and project files",
      "Rendered mode gives structure without leaving Finder",
      "Raw mode keeps formatting characters visible when they matter",
    ],
  },
  {
    title: "Coverage for the files Finder often leaves awkward",
    body: "dotViewer is built for the technical files people actually touch across repositories, environments, and workflows.",
    bullets: [
      "Broad extension and filename coverage",
      "Quick Look previews plus Finder thumbnails",
      "A stronger default for technical file inspection on macOS",
    ],
  },
  {
    title: "Settings that respect the way you work",
    body: "Tweak layout width, typography, alignment, line numbers, copy behavior, and preview options without turning the app into a preferences maze.",
    bullets: [
      "Control presentation instead of accepting one rigid preview",
      "Useful for wide code, markdown reading, and denser text files",
      "Designed to stay lightweight while still being adaptable",
    ],
  },
];

const comparisonRows = [
  {
    label: "Markdown and project docs",
    finder: "Often plain, limited, or treated like generic text.",
    dotViewer: "Readable raw source plus rendered markdown when structure matters.",
  },
  {
    label: "Config files and dotfiles",
    finder: "Usually reduced to a basic text dump or no meaningful preview.",
    dotViewer: "Theme-aware syntax highlighting built for fast scanning.",
  },
  {
    label: "Small inspection tasks",
    finder: "Often turns into opening an editor just to verify one detail.",
    dotViewer: "Keeps the check inside Finder so you can keep moving.",
  },
  {
    label: "Technical file coverage",
    finder: "Inconsistent across code, logs, filenames, and uncommon extensions.",
    dotViewer: "A focused registry for the kinds of files technical users touch daily.",
  },
];

const limitations = [
  "Some file types are still claimed by macOS system preview handlers. For example, `.html` stays with the native HTML Quick Look renderer.",
  "TypeScript `.ts` can still be routed by macOS as MPEG-2 transport stream video in some situations, which is a platform routing limitation rather than a dotViewer bug.",
  "dotViewer improves Quick Look where third-party extensions are allowed. It does not override every system-owned preview path in macOS.",
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
        <div className={styles.orbThree} />
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
                width={30}
                height={30}
                sizes="30px"
              />
              <span>dotViewer</span>
            </Link>

            <div className={styles.navLinks}>
              <a href="#overview">Overview</a>
              <a href="#coverage">Coverage</a>
              <a href="#install">Install</a>
              <a href="#faq">FAQ</a>
            </div>

            <Link className={styles.navCta} href="/download">
              Download for macOS
            </Link>
          </nav>
        </div>
      </header>

      <main className={styles.main} id="main-content">
        <div className={styles.shell}>
          <section className={styles.hero} id="overview">
            <div className={styles.heroCopy}>
              <div className={styles.eyebrow}>
                <span className={styles.eyebrowDot} />
                Better Quick Look for technical files
              </div>

              <h1 className={styles.heroTitle}>
                Preview markdown, config, and code files Finder doesn&apos;t handle well.
              </h1>

              <p className={styles.heroBody}>
                Inspect technical files instantly in Quick Look instead of opening an editor for
                every small check. dotViewer keeps file inspection inside Finder, with cleaner
                previews, better structure, and a more capable macOS-native flow.
              </p>

              <div className={styles.heroActions}>
                <Link className={styles.primaryAction} href="/download">
                  Download for macOS
                </Link>
                <a className={styles.secondaryAction} href={releasesHref}>
                  View releases
                </a>
              </div>

              <div className={styles.heroMeta}>
                <span className={styles.metaPill}>Free download</span>
                <span className={styles.metaPill}>Notarized DMG workflow</span>
                <span className={styles.metaPill}>macOS 15+</span>
              </div>
            </div>

            <div className={styles.heroVisual} aria-hidden="true">
              <div className={styles.floatingCard}>
                <div className={styles.cardTopbar}>
                  <div className={styles.cardDots}>
                    <span />
                    <span />
                    <span />
                  </div>
                  <div className={styles.cardLabel}>Quick Look Preview</div>
                </div>

                <div className={styles.cardBody}>
                  <div className={styles.codeWindow}>
                    <div className={styles.codeHeader}>
                      <span>config.production.json</span>
                      <span>JSON</span>
                    </div>
                    <div className={styles.codeBody}>
                      <div className={styles.lineNumbers}>1{"\n"}2{"\n"}3{"\n"}4{"\n"}5{"\n"}6</div>
                      <div className={styles.codeLines}>
                        {"{"}
                        {"\n"}  <span className={styles.tokenString}>"theme"</span>:{" "}
                        <span className={styles.tokenString}>"blackout"</span>,
                        {"\n"}  <span className={styles.tokenString}>"markdown"</span>: {"{"}
                        {"\n"}    <span className={styles.tokenString}>"rendered"</span>:{" "}
                        <span className={styles.tokenKeyword}>true</span>
                        {"\n"}  {"},"}
                        {"\n"}  <span className={styles.tokenComment}>// Finder preview stays readable</span>
                        {"\n"}
                        {"}"}
                      </div>
                    </div>
                  </div>

                  <div className={styles.codeWindow}>
                    <div className={styles.codeHeader}>
                      <span>README.md</span>
                      <span>Rendered Markdown</span>
                    </div>
                    <div className={styles.markdownSheet}>
                      <h3>Shipping dotViewer</h3>
                      <p>
                        Review notes, install steps, and project context without leaving Finder.
                      </p>
                      <ul>
                        <li>Quick preview for docs and technical notes</li>
                        <li>Readable structure for tables and headings</li>
                        <li>Useful when all you need is a fast check</li>
                      </ul>
                    </div>
                  </div>
                </div>
              </div>

              <div className={styles.floatingPane}>
                <div className={styles.paneEyebrow}>Inside Finder</div>
                <div className={styles.paneTitle}>
                  A smoother way to inspect the files you actually work with.
                </div>
                <div className={styles.paneBody}>
                  Built for markdown, configs, logs, dotfiles, and code that deserve more than a
                  generic icon or a raw dump of text.
                </div>
              </div>

              <div className={styles.floatingBadge}>
                <div className={styles.badgeValue}>{stats.fileTypes}</div>
                <div className={styles.badgeLabel}>
                  built-in file type definitions ready for Quick Look routing
                </div>
              </div>
            </div>
          </section>

          <section className={styles.section}>
            <div className={styles.proofGrid}>
              {proofPoints.map((item) => (
                <article className={styles.card} key={item.title}>
                  <div className={styles.cardTag}>{item.tag}</div>
                  <h2 className={styles.proofTitle}>{item.title}</h2>
                  <p className={styles.proofCopy}>{item.body}</p>
                </article>
              ))}
            </div>
          </section>

          <section className={styles.section}>
            <div className={styles.sectionHeading}>
              <div className={styles.kicker}>Feature Proof</div>
              <h2 className={styles.sectionTitle}>
                The product value stays obvious from the first scroll.
              </h2>
              <p className={styles.sectionBody}>
                Better previews matter because they remove friction from everyday file inspection.
                dotViewer gives technical files more structure, more readability, and a better fit
                inside Finder without asking you to change the way you browse your files.
              </p>
            </div>

            <div className={styles.featureGrid}>
              {features.map((feature, index) => (
                <article className={styles.card} key={feature.title}>
                  <div className={styles.cardTag}>0{index + 1}</div>
                  <h3 className={styles.featureTitle}>{feature.title}</h3>
                  <p>{feature.body}</p>
                  <ul className={styles.featureList}>
                    {feature.bullets.map((bullet) => (
                      <li key={bullet}>{bullet}</li>
                    ))}
                  </ul>
                </article>
              ))}
            </div>
          </section>

          <section className={styles.section}>
            <div className={styles.comparePanel}>
              <div className={styles.sectionHeading}>
                <div className={styles.kicker}>Why It Feels Better</div>
                <h2 className={styles.sectionTitle}>
                  Made for quick inspection, not generic previewing.
                </h2>
                <p className={styles.sectionBody}>
                  Finder&apos;s built-in Quick Look is fine for everyday documents. dotViewer is
                  built for the technical files where default previews are sparse, awkward, or
                  simply not useful enough.
                </p>
              </div>

              <div className={styles.compareTable} role="table" aria-label="Quick Look comparison">
                <div className={styles.compareHead} role="rowgroup">
                  <div className={styles.compareRow} role="row">
                    <div className={styles.compareHeaderCell} role="columnheader">
                      Workflow area
                    </div>
                    <div className={styles.compareHeaderCell} role="columnheader">
                      Default Quick Look
                    </div>
                    <div className={styles.compareHeaderCell} role="columnheader">
                      dotViewer
                    </div>
                  </div>
                </div>

                <div className={styles.compareBody} role="rowgroup">
                  {comparisonRows.map((row) => (
                    <div className={styles.compareRow} role="row" key={row.label}>
                      <div className={styles.compareLabel} role="rowheader">
                        {row.label}
                      </div>
                      <div className={styles.compareCell} role="cell">
                        {row.finder}
                      </div>
                      <div className={styles.compareCellStrong} role="cell">
                        {row.dotViewer}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </section>

          <section className={styles.section} id="coverage">
            <div className={styles.sectionHeading}>
              <div className={styles.kicker}>Coverage And Limits</div>
              <h2 className={styles.sectionTitle}>
                Broad enough to be useful, honest enough to be trusted.
              </h2>
              <p className={styles.sectionBody}>
                dotViewer ships with broad built-in file coverage, but it does not pretend macOS
                gives third-party Quick Look extensions unlimited control. The limits are part of
                the product story, so they are stated plainly.
              </p>
            </div>

            <div className={styles.statsLayout}>
              <div className={styles.statsGrid}>
                <article className={styles.card}>
                  <div className={styles.statValue}>{stats.fileTypes}</div>
                  <div className={styles.statLabel}>built-in file type definitions</div>
                </article>
                <article className={styles.card}>
                  <div className={styles.statValue}>{stats.extensions}</div>
                  <div className={styles.statLabel}>registered file extensions</div>
                </article>
                <article className={styles.card}>
                  <div className={styles.statValue}>{stats.filenameMappings}</div>
                  <div className={styles.statLabel}>filename-specific mappings</div>
                </article>
                <article className={styles.card}>
                  <div className={styles.statValue}>{stats.grammars}</div>
                  <div className={styles.statLabel}>
                    syntax query files in the highlighting pipeline
                  </div>
                </article>
              </div>

              <aside className={styles.limitations}>
                <article className={styles.card}>
                  <h3 className={styles.limitationsTitle}>What macOS still keeps for itself</h3>
                  <ul className={styles.limitationsList}>
                    {limitations.map((item) => (
                      <li key={item}>{item}</li>
                    ))}
                  </ul>
                </article>

                <div className={styles.limitationsNote}>
                  dotViewer is strongest where Finder gives third-party Quick Look extensions room
                  to improve the experience. When macOS owns the preview path, the limitation is
                  called out directly instead of hidden behind vague marketing language.
                </div>
              </aside>
            </div>
          </section>

          <section className={styles.section} id="install">
            <div className={styles.sectionHeading}>
              <div className={styles.kicker}>Install</div>
              <h2 className={styles.sectionTitle}>
                Download it, drop it in Applications, launch once.
              </h2>
              <p className={styles.sectionBody}>
                The install path is meant to feel like a normal Mac app: direct download, familiar
                drag-and-drop install, one launch to register the extension, then Quick Look in
                Finder as usual.
              </p>
            </div>

            <div className={styles.installGrid}>
              <article className={styles.card}>
                <div className={styles.installStepNumber}>1</div>
                <h3 className={styles.installTitle}>Download the latest DMG</h3>
                <p>
                  Use the public release channel through the site&apos;s stable `/download` link,
                  which is designed to resolve to the latest macOS installer.
                </p>
              </article>

              <article className={styles.card}>
                <div className={styles.installStepNumber}>2</div>
                <h3 className={styles.installTitle}>Drag dotViewer into Applications</h3>
                <p>
                  Install it like a normal Mac app. No account, package manager, or custom
                  launcher flow is required.
                </p>
              </article>

              <article className={styles.card}>
                <div className={styles.installStepNumber}>3</div>
                <h3 className={styles.installTitle}>Launch once, then use Quick Look in Finder</h3>
                <p>
                  The first launch registers the extension. After that, browse files in Finder and
                  press Space on any supported file type.
                </p>
              </article>
            </div>

            <div className={styles.installCallout}>
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
            <div className={styles.sectionHeading}>
              <div className={styles.kicker}>FAQ</div>
              <h2 className={styles.sectionTitle}>
                Short answers to the questions people will ask before installing.
              </h2>
            </div>

            <div className={styles.faqList}>
              {faqs.map((item) => (
                <details className={styles.faqItem} key={item.question}>
                  <summary>{item.question}</summary>
                  <div className={styles.faqContent}>{item.answer}</div>
                </details>
              ))}
            </div>

            <div className={styles.ctaPanel}>
              <h2 className={styles.ctaTitle}>
                A better Quick Look flow for the files Finder leaves awkward.
              </h2>
              <p className={styles.ctaBody}>
                dotViewer is for the moments when you just need to inspect the file, understand what
                it is, and keep moving. No editor launch, no heavy context switch, no generic blank
                preview where useful information should be.
              </p>
              <div className={styles.ctaActions}>
                <Link className={styles.primaryAction} href="/download">
                  Download for macOS
                </Link>
                <a className={styles.ghostAction} href={releasesHref}>
                  View releases
                </a>
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
              <a href="#overview">Overview</a>
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
