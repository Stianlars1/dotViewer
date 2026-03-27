import Image from "next/image";
import Link from "next/link";
import styles from "./page.module.css";
import { getProductStats } from "../lib/product-stats";
import { getSiteConfig } from "../lib/site-config";

const heroMeta = ["Actual app screenshots", "Free download", "Notarized DMG", "macOS 15+"];

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
    question: "Can I tune the preview and app UI?",
    answer:
      "Yes. dotViewer includes built-in themes, font sizing, content width controls, line-number and word-wrap options, markdown defaults, copy behavior, file type controls, and more inside the companion app.",
  },
];

const proofMessages = [
  {
    title: "Real code previews",
    body: "Syntax highlighting, file badges, line counts, and copy actions from the actual Quick Look UI.",
  },
  {
    title: "Markdown your way",
    body: "Raw and rendered modes, optional table of contents, and layouts that match the app instead of a website mockup.",
  },
  {
    title: "Configurable behavior",
    body: "Themes, width, font size, copy behavior, file types, markdown defaults, and status live in the app you install.",
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
              <a href="#previews">Previews</a>
              <a href="#controls">Controls</a>
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
              <div className={styles.eyebrow}>The screenshots below are from the actual app</div>

              <h1 className={styles.heroTitle}>
                Preview markdown, config, and code files Finder doesn&apos;t handle well.
              </h1>

              <p className={styles.heroBody}>
                dotViewer keeps small file checks small. Raw and rendered markdown. Optional table
                of contents. Auto-copy on text selection. Built-in themes and UI controls. What you
                see here is the product as it actually ships on macOS.
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

          <section className={styles.showcaseSection} id="previews" aria-label="Actual product screenshots">
            <div className={styles.heroGallery}>
              <figure className={styles.galleryLead}>
                <Image
                  src="/product/markdown-rendered-toc.jpeg"
                  alt="dotViewer rendered markdown preview with the table of contents open"
                  width={3680}
                  height={2224}
                  priority
                  sizes="(max-width: 1100px) 100vw, 70vw"
                />
              </figure>

              <div className={styles.galleryStack}>
                <figure className={styles.galleryCard}>
                  <Image
                    src="/product/markdown-raw.jpeg"
                    alt="dotViewer markdown raw preview with syntax highlighting"
                    width={1644}
                    height={1676}
                    sizes="(max-width: 1100px) 100vw, 28vw"
                  />
                </figure>

                <figure className={styles.galleryCard}>
                  <Image
                    src="/product/code-c.jpeg"
                    alt="dotViewer C source file preview in Quick Look"
                    width={1644}
                    height={770}
                    sizes="(max-width: 1100px) 100vw, 28vw"
                  />
                </figure>
              </div>
            </div>
          </section>

          <section className={styles.proofStrip} aria-label="Product summary">
            {proofMessages.map((item) => (
              <article className={styles.proofMessage} key={item.title}>
                <h2 className={styles.proofMessageTitle}>{item.title}</h2>
                <p className={styles.proofMessageBody}>{item.body}</p>
              </article>
            ))}
          </section>

          <section className={styles.statsStrip} aria-label="Coverage summary">
            {proofStats.map((item) => (
              <article className={styles.statItem} key={item.label}>
                <div className={styles.statValue}>{item.value}</div>
                <div className={styles.statLabel}>{item.label}</div>
              </article>
            ))}
          </section>

          <section className={styles.section}>
            <div className={styles.sectionIntro}>
              <div className={styles.kicker}>Preview Modes</div>
              <h2 className={styles.sectionTitle}>
                Code, markdown, and technical files shown the way dotViewer actually renders them.
              </h2>
              <p className={styles.sectionBody}>
                The website now uses the real preview UI language: dark Quick Look surfaces, file
                badges, top-bar actions, raw versus rendered markdown, and the larger markdown
                layout with TOC support when that mode is enabled.
              </p>
            </div>

            <div className={styles.featureRow}>
              <div className={styles.featureCopy}>
                <div className={styles.storyKicker}>Code and config</div>
                <h3 className={styles.storyTitle}>
                  Syntax-highlighted previews for the files you inspect constantly.
                </h3>
                <p className={styles.storyBody}>
                  Source code, shell scripts, XML, dotfiles, configs, and other technical files are
                  presented with the actual Quick Look chrome from dotViewer rather than invented
                  browser-like mockups.
                </p>
              </div>

              <div className={styles.imagePair}>
                <figure className={styles.shotWide}>
                  <Image
                    src="/product/code-c.jpeg"
                    alt="C file preview in dotViewer"
                    width={1644}
                    height={770}
                    sizes="(max-width: 1100px) 100vw, 42vw"
                  />
                </figure>

                <figure className={styles.shotWide}>
                  <Image
                    src="/product/code-swift.jpeg"
                    alt="Swift file preview in dotViewer"
                    width={2134}
                    height={1768}
                    sizes="(max-width: 1100px) 100vw, 42vw"
                  />
                </figure>
              </div>
            </div>

            <div className={styles.featureRow}>
              <div className={styles.imageStack}>
                <figure className={styles.shotLarge}>
                  <Image
                    src="/product/markdown-rendered-toc.jpeg"
                    alt="Rendered markdown preview with table of contents open in dotViewer"
                    width={3680}
                    height={2224}
                    sizes="(max-width: 1100px) 100vw, 46vw"
                  />
                </figure>

                <figure className={styles.shotLarge}>
                  <Image
                    src="/product/markdown-raw.jpeg"
                    alt="Raw markdown preview in dotViewer"
                    width={1644}
                    height={1676}
                    sizes="(max-width: 1100px) 100vw, 46vw"
                  />
                </figure>
              </div>

              <div className={styles.featureCopy}>
                <div className={styles.storyKicker}>Markdown</div>
                <h3 className={styles.storyTitle}>
                  Raw or rendered, with optional table of contents.
                </h3>
                <p className={styles.storyBody}>
                  dotViewer supports the two markdown states people actually care about: inspecting
                  the source and reading the document. When rendered mode is active, the table of
                  contents can stay hidden or open by default depending on the user’s setting.
                </p>
              </div>
            </div>

            <div className={styles.featureRow}>
              <div className={styles.featureCopy}>
                <div className={styles.storyKicker}>Copy behavior</div>
                <h3 className={styles.storyTitle}>
                  Selection can copy automatically, because Quick Look needs pragmatic controls.
                </h3>
                <p className={styles.storyBody}>
                  The app includes configurable copy behavior for preview selection. The site should
                  reflect that real capability, including the small “Copied selection” feedback
                  rather than pretending the preview is passive.
                </p>
              </div>

              <figure className={styles.shotHero}>
                <Image
                  src="/product/markdown-copy-toast.jpeg"
                  alt="dotViewer rendered markdown preview showing copied selection feedback"
                  width={3680}
                  height={2224}
                  sizes="(max-width: 1100px) 100vw, 48vw"
                />
              </figure>
            </div>
          </section>

          <section className={styles.section} id="controls">
            <div className={styles.sectionIntro}>
              <div className={styles.kicker}>App Controls</div>
              <h2 className={styles.sectionTitle}>
                Themes, typography, width, copy behavior, markdown defaults, and file type
                management live in the app.
              </h2>
              <p className={styles.sectionBody}>
                dotViewer is not only a Quick Look extension. The companion app lets people change
                themes, tune code and markdown widths, control copy behavior, manage file types, and
                inspect extension status with a UI that matches the product screenshots below.
              </p>
            </div>

            <div className={styles.controlGrid}>
              <figure className={styles.controlCard}>
                <Image
                  src="/product/settings-theme.jpeg"
                  alt="dotViewer theme selection settings"
                  width={2024}
                  height={1528}
                  sizes="(max-width: 1100px) 100vw, 31vw"
                />
                <figcaption>Built-in themes including GitHub, Xcode, Solarized, Tokyo Night, and Blackout.</figcaption>
              </figure>

              <figure className={styles.controlCard}>
                <Image
                  src="/product/settings-appearance.jpeg"
                  alt="dotViewer appearance and preview layout settings"
                  width={2024}
                  height={1528}
                  sizes="(max-width: 1100px) 100vw, 31vw"
                />
                <figcaption>Appearance controls for font size, app UI text size, line numbers, word wrap, and content width.</figcaption>
              </figure>

              <figure className={styles.controlCard}>
                <Image
                  src="/product/settings-copy.jpeg"
                  alt="dotViewer copy behavior and preview UI settings"
                  width={2024}
                  height={1528}
                  sizes="(max-width: 1100px) 100vw, 31vw"
                />
                <figcaption>Preview UI controls including auto-copy, line numbers in copy, and preview behavior for unknown files.</figcaption>
              </figure>
            </div>

            <div className={styles.appGrid}>
              <figure className={styles.appCard}>
                <Image
                  src="/product/file-types.jpeg"
                  alt="dotViewer file type registry screen"
                  width={2024}
                  height={1528}
                  sizes="(max-width: 1100px) 100vw, 46vw"
                />
                <figcaption>Manage built-in and custom file type mappings from the app.</figcaption>
              </figure>

              <figure className={styles.appCard}>
                <Image
                  src="/product/status.jpeg"
                  alt="dotViewer status screen showing extension enabled and quick stats"
                  width={2024}
                  height={1528}
                  sizes="(max-width: 1100px) 100vw, 46vw"
                />
                <figcaption>Status, quick stats, and extension health are visible in the companion app.</figcaption>
              </figure>
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
              <a href="#previews">Previews</a>
              <a href="#controls">Controls</a>
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
