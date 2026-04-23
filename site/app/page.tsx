import type { ReactNode } from "react";
import Link from "next/link";
import { AnimatedStat } from "../components/animated-stat";
import { AuroraBackground } from "../components/aurora-background";
import { HeroSection, type HeroTitlePiece } from "../components/hero-section";
import { ImageLightbox } from "../components/image-lightbox";
import { InstallTabs } from "../components/install-tabs";
import { LogoAnimated } from "../components/logo-animated";
import { Reveal } from "../components/reveal";
import { SupportChecker } from "../components/support-checker";
import { TrackedDownloadLink } from "../components/tracked-download-link";
import styles from "./page.module.css";
import { getProductStats, getSupportedFileTypes } from "../lib/product-stats";
import {
  buildHomeSchema,
  CREATOR_NAME,
  CREATOR_URL,
  DBHOST_URL,
} from "../lib/structured-data";
import { getSiteConfig } from "../lib/site-config";

function Code({ children }: { children: ReactNode }) {
  return <code>{children}</code>;
}

const heroTitle: HeroTitlePiece[] = [
  { kind: "text", value: "Preview any technical file" },
  { kind: "break" },
  { kind: "text", value: "with a tap of" },
  { kind: "mono", value: "Space" },
  { kind: "text", value: "." },
];

const heroMeta = [
  "Signed & notarized",
  "Universal (Apple Silicon + Intel)",
  "macOS 13+",
];

const fileChips = [
  { label: ".gitignore", accent: true },
  { label: ".env", accent: true },
  { label: "README.md" },
  { label: "package.json" },
  { label: "Dockerfile" },
  { label: ".editorconfig" },
  { label: "YAML" },
  { label: "XML" },
  { label: "plist" },
  { label: "CSV / TSV" },
  { label: "shell scripts" },
  { label: "man pages" },
  { label: "log files" },
  { label: "Swift, C, Go, TS…" },
];

const installSteps = [
  {
    step: "01",
    title: "Install with one command",
    body: "Homebrew downloads the notarized DMG, drops dotViewer into Applications, and registers the Quick Look extensions.",
  },
  {
    step: "02",
    title: "Or drag the DMG into Applications",
    body: "Prefer the classic path? The signed DMG is the same binary, shipped straight from GitHub Releases.",
  },
  {
    step: "03",
    title: "Press Space on any file",
    body: "First launch registers the extension. After that, Quick Look does the rest — from Swift to .env to man pages.",
  },
];

const faqs = [
  {
    id: "built-for",
    question: "What files is dotViewer built for?",
    answer: (
      <>
        dotViewer is built for the technical text files developers keep hitting
        Space on in Finder: dotfiles, config files, markdown documents,{" "}
        <Code>CSV</Code> / <Code>TSV</Code> data, man pages, logs, extensionless
        executable scripts, plain text documents, and <Code>source code</Code>.
      </>
    ),
    schemaQuestion: "What files is dotViewer built for?",
    schemaAnswer:
      "dotViewer is built for the technical text files developers keep hitting Space on in Finder: dotfiles, config files, markdown documents, logs, plain text documents, and source code.",
  },
  {
    id: "dotfiles",
    question: (
      <>
        Can dotViewer preview dotfiles like <Code>.gitignore</Code> and config
        files like <Code>JSON</Code>, <Code>YAML</Code>, <Code>XML</Code>, and{" "}
        <Code>INI</Code>?
      </>
    ),
    answer: (
      <>
        Yes. The app is designed around exactly that workflow, including{" "}
        <Code>.gitignore</Code>, <Code>.env</Code>, <Code>.editorconfig</Code>,{" "}
        <Code>package.json</Code>, <Code>YAML</Code>, <Code>XML</Code>,{" "}
        <Code>plist</Code>, <Code>TSV</Code>, man pages, <Code>log files</Code>,
        extensionless executable scripts, and many other text-based formats.
      </>
    ),
    schemaQuestion:
      "Can dotViewer preview dotfiles like .gitignore and config files like JSON, YAML, XML, and INI?",
    schemaAnswer:
      "Yes. The app is designed around exactly that workflow, including .gitignore, .env, .editorconfig, package.json, YAML, XML, plist, log files, and many other text-based formats.",
  },
  {
    id: "why-one-app",
    question:
      "Why use dotViewer instead of separate markdown or code preview extensions?",
    answer:
      "One signed app replaces the stack — markdown plugin, plain-text plugin, syntax highlighter. One settings surface, one install flow, one thing to update.",
    schemaQuestion:
      "Why use dotViewer instead of separate markdown or code preview extensions?",
    schemaAnswer:
      "One signed app replaces the stack — markdown plugin, plain-text plugin, syntax highlighter. One settings surface, one install flow, one thing to update.",
  },
  {
    id: "override-everything",
    question: "Does it override every file type?",
    answer:
      "No. Some types are owned by macOS system handlers. dotViewer improves Quick Look wherever third-party extensions are allowed, and is honest about the cases it can't reach.",
    schemaQuestion: "Does it override every file type?",
    schemaAnswer:
      "No. Some types are owned by macOS system handlers. dotViewer improves Quick Look wherever third-party extensions are allowed, and is honest about the cases it can't reach.",
  },
  {
    id: "signed",
    question: "Is the app signed and notarized?",
    answer:
      "Yes. The DMG is Developer ID signed and Apple-notarized, so Gatekeeper is happy on a normal Mac. The same binary ships via the Homebrew cask and the App Store.",
    schemaQuestion: "Is the app signed and notarized?",
    schemaAnswer:
      "Yes. The DMG is Developer ID signed and Apple-notarized, so Gatekeeper is happy on a normal Mac. The same binary ships via the Homebrew cask and the App Store.",
  },
  {
    id: "homebrew",
    question: "Can I install dotViewer with Homebrew?",
    answer: (
      <>
        Yes. Run <Code>brew install --cask stianlars1/tap/dotviewer</Code> and
        Homebrew installs the notarized DMG and registers the Quick Look
        extensions automatically. <Code>brew upgrade --cask</Code> picks up new
        releases.
      </>
    ),
    schemaQuestion: "Can I install dotViewer with Homebrew?",
    schemaAnswer:
      "Yes. Run `brew install --cask stianlars1/tap/dotviewer` and Homebrew installs the notarized DMG and registers the Quick Look extensions automatically.",
  },
  {
    id: "pricing",
    question: "Is dotViewer free or paid?",
    answer:
      "Both. The direct DMG and the Homebrew cask are free. There's also a paid App Store option for people who prefer store-managed installation and want to support ongoing development.",
    schemaQuestion: "Is dotViewer free or paid?",
    schemaAnswer:
      "Both. The direct DMG and the Homebrew cask are free. There's also a paid App Store option for people who prefer store-managed installation and want to support ongoing development.",
  },
  {
    id: "extension-conflict",
    question:
      "Another Quick Look extension is overriding dotViewer. How do I fix it?",
    answer: (
      <>
        The Status screen includes a built-in conflict scanner that detects
        competing Quick Look extensions and lets you resolve them in one click.
        For manual inspection you can also use the free{" "}
        <a
          href="https://github.com/Oil3/PluginKits"
          target="_blank"
          rel="noopener noreferrer"
        >
          PluginKits
        </a>{" "}
        app. Both approaches take effect immediately.
      </>
    ),
    schemaQuestion:
      "Another Quick Look extension is overriding dotViewer. How do I fix it?",
    schemaAnswer:
      "The Status screen includes a built-in conflict scanner that detects competing Quick Look extensions and lets you resolve them in one click. For manual inspection you can also use the free PluginKits app (github.com/Oil3/PluginKits).",
  },
  {
    id: "custom-types",
    question: "Can I add my own file types?",
    answer: (
      <>
        You can override highlighting for any type dotViewer already ships.
        Brand-new types need a release update — file a GitHub issue and they get
        added.
      </>
    ),
    schemaQuestion: "Can I add my own file types?",
    schemaAnswer:
      "You can override highlighting for any type dotViewer already ships. Brand-new types need a release update — file a GitHub issue and they get added.",
  },
];

export default function HomePage() {
  const stats = getProductStats();
  const supportedFileTypes = getSupportedFileTypes();
  const routingCaveatCount = supportedFileTypes.reduce((count, type) => {
    return (
      count +
      type.routingLimitations.reduce((total, limitation) => {
        return total + limitation.matchedExtensions.length;
      }, 0)
    );
  }, 0);

  const config = getSiteConfig();
  const appStoreHref = config.appStoreUrl;
  const releasesHref = config.releasesUrl ?? "#install";
  const repoHref = config.repoUrl ?? releasesHref;
  const issuesHref = config.repoUrl ? `${config.repoUrl}/issues` : repoHref;
  const issueRequestHref = config.repoUrl
    ? `${config.repoUrl}/issues/new?title=${encodeURIComponent("File type support: ")}`
    : repoHref;

  const schema = buildHomeSchema(
    config,
    stats,
    faqs.map((item) => ({
      question: item.schemaQuestion,
      answer: item.schemaAnswer,
    })),
  );
  const schemaJson = JSON.stringify(schema);

  const proofStats = [
    { value: stats.fileTypes, label: "built-in file types" },
    { value: stats.extensions, label: "registered extensions" },
    { value: stats.filenameMappings, label: "filename mappings" },
    { value: stats.grammars, label: "highlight query files" },
  ];

  return (
    <div className={styles.page}>
      <AuroraBackground />
      <a className={styles.skipLink} href="#main-content">
        Skip to content
      </a>

      <header className={styles.nav}>
        <div className={styles.wrap}>
          <div className={styles.navInner}>
            <Link className={styles.brand} href="/" aria-label="dotViewer home">
              <span className={styles.brandMark}>
                <LogoAnimated size={28} interactive={false} />
              </span>
              <span>dotViewer</span>
            </Link>

            <nav className={styles.navLinks} aria-label="Primary">
              <a href="#previews">Previews</a>
              <a href="#controls">Controls</a>
              <a href="#coverage">Coverage</a>
              <a href="#install">Install</a>
              <a href="#faq">FAQ</a>
            </nav>

            <Link className={styles.navCta} href="/download">
              Download
            </Link>
          </div>
        </div>
      </header>

      <main className={styles.main} id="main-content">
        <div className={styles.wrap}>
          <HeroSection
            appStoreHref={appStoreHref}
            downloadHref="/download"
            eyebrow="Finder Quick Look, upgraded"
            titlePieces={heroTitle}
            lede={
              <>
                One native macOS app for dotfiles, configs, markdown, logs,
                plain text, and source code — right in Quick Look.
              </>
            }
            meta={heroMeta}
            heroImage={{
              src: "/product/markdown-rendered-toc.jpeg",
              alt: "dotViewer rendered markdown preview with table of contents open in Finder Quick Look",
              width: 3680,
              height: 2224,
            }}
          />

          <Reveal as="section" className={styles.proof} delay={0.05}>
            {proofStats.map((item, index) => (
              <article className={styles.proofItem} key={item.label}>
                <AnimatedStat
                  value={item.value}
                  className={styles.proofValue}
                />
                <div className={styles.proofLabel}>{item.label}</div>
                {index < proofStats.length - 1 ? (
                  <span className={styles.proofSep} aria-hidden="true" />
                ) : null}
              </article>
            ))}
          </Reveal>

          <Reveal as="section" className={styles.block} delay={0.05}>
            <div className={styles.sectionHead}>
              <div className={styles.label}>Why dotViewer</div>
              <h2 className={styles.h2}>
                One app. Replaces several Quick Look plugins.
              </h2>
              <p className={styles.sub}>
                Instead of stacking a markdown previewer, a plain-text viewer,
                and a syntax-highlighting add-on, install one signed app and get
                the whole technical-file surface at once.
              </p>
            </div>

            <div className={styles.chips}>
              {fileChips.map((chip) => (
                <span
                  key={chip.label}
                  className={`${styles.chip} ${chip.accent ? styles.chipAccent : ""}`}
                >
                  {chip.label}
                </span>
              ))}
            </div>
          </Reveal>

          <section
            className={styles.block}
            id="previews"
            aria-label="Preview modes"
          >
            <Reveal className={styles.feat}>
              <div className={styles.shot}>
                <ImageLightbox
                  src="/product/code-swift.jpeg"
                  alt="Swift source file preview with syntax highlighting in dotViewer"
                  width={2134}
                  height={1768}
                  sizes="(max-width: 860px) 100vw, 540px"
                  caption="Code & config — syntax-aware previews"
                />
              </div>
              <div className={styles.featText}>
                <div className={styles.microLabel}>Code & config</div>
                <h3 className={styles.featTitle}>
                  Syntax-aware previews for the files you actually open.
                </h3>
                <p className={styles.featBody}>
                  Token-level highlighting, line numbers, a language badge, and
                  a copy action — without ever leaving Finder.
                </p>
                <ul className={styles.featList}>
                  <li>Swift, C, Go, TypeScript, Python, Rust + 100 more</li>
                  <li>
                    JSON, YAML, TOML, INI, XML with structure-aware colour
                  </li>
                  <li>Shell scripts, Dockerfiles, Makefiles, Procfiles</li>
                </ul>
              </div>
            </Reveal>

            <Reveal
              className={`${styles.feat} ${styles.featReverse}`}
              delay={0.06}
            >
              <div className={styles.featText}>
                <div className={styles.microLabel}>Markdown</div>
                <h3 className={styles.featTitle}>
                  Read rendered. Inspect raw. One key away.
                </h3>
                <p className={styles.featBody}>
                  Toggle between styled output and the source with a keystroke.
                  Table of contents, code blocks, tables — all rendered
                  natively.
                </p>
              </div>
              <div className={styles.pair}>
                <div className={styles.shot}>
                  <ImageLightbox
                    src="/product/markdown-raw.jpeg"
                    alt="Raw markdown preview with syntax-highlighted source"
                    width={1644}
                    height={1676}
                    sizes="(max-width: 860px) 100vw, 260px"
                    caption="Markdown — raw mode"
                  />
                </div>
                <div className={styles.shot}>
                  <ImageLightbox
                    src="/product/markdown-copy-toast.jpeg"
                    alt="Rendered markdown preview with a copy confirmation toast"
                    width={3680}
                    height={2224}
                    sizes="(max-width: 860px) 100vw, 260px"
                    caption="Markdown — rendered mode"
                  />
                </div>
              </div>
            </Reveal>
          </section>

          <Reveal as="section" className={styles.block} id="install">
            <div className={styles.sectionHead}>
              <div className={styles.label}>Install</div>
              <h2 className={styles.h2}>Three ways. Takes a minute.</h2>
              <p className={styles.sub}>
                Homebrew, direct DMG, or the App Store — same signed binary.
                Pick whichever matches your taste.
              </p>
            </div>

            <div className={styles.installShell}>
              <InstallTabs
                homebrewCommand={config.homebrewCommand}
                homebrewTapUrl={config.homebrewTapUrl}
                directDownloadUrl="/download/latest?source=home_install_tab_dmg"
                appStoreUrl={appStoreHref}
                releasesUrl={releasesHref}
                releaseTag={null}
                source="home_install_tab_dmg"
              />

              <div className={styles.installSteps}>
                {installSteps.map((item) => (
                  <article className={styles.installStep} key={item.step}>
                    <div className={styles.installNum}>{item.step}</div>
                    <h4 className={styles.installTitle}>{item.title}</h4>
                    <p className={styles.installBody}>{item.body}</p>
                  </article>
                ))}
              </div>
            </div>
          </Reveal>

          <Reveal as="section" className={styles.block} id="controls">
            <div className={styles.sectionHead}>
              <div className={styles.label}>Companion app</div>
              <h2 className={styles.h2}>Everything tunable, in one place.</h2>
              <p className={styles.sub}>
                Themes, layout, copy behaviour, file-type mappings, and conflict
                resolution — consolidated into a single settings surface.
              </p>
            </div>

            <div className={styles.bento}>
              <figure className={`${styles.bentoCard} ${styles.bentoLead}`}>
                <ImageLightbox
                  src="/product/settings-appearance.jpeg"
                  alt="dotViewer appearance and preview layout settings"
                  width={2024}
                  height={1528}
                  sizes="(max-width: 860px) 100vw, 1140px"
                  caption="Appearance — font, width, wrap"
                />
                <figcaption>
                  <span>Appearance</span>
                  <span className={styles.bentoMeta}>font · width · wrap</span>
                </figcaption>
              </figure>

              <figure className={styles.bentoCard}>
                <ImageLightbox
                  src="/product/settings-theme.jpeg"
                  alt="dotViewer theme picker"
                  width={2024}
                  height={1528}
                  sizes="(max-width: 860px) 100vw, 560px"
                  caption="Theme — system, light, dark"
                />
                <figcaption>
                  <span>Theme</span>
                  <span className={styles.bentoMeta}>
                    system · light · dark
                  </span>
                </figcaption>
              </figure>

              <figure className={styles.bentoCard}>
                <ImageLightbox
                  src="/product/settings-copy.jpeg"
                  alt="dotViewer copy behaviour preferences"
                  width={2024}
                  height={1528}
                  sizes="(max-width: 860px) 100vw, 560px"
                  caption="Copy behaviour — 8 presets"
                />
                <figcaption>
                  <span>Copy behaviour</span>
                  <span className={styles.bentoMeta}>8 presets</span>
                </figcaption>
              </figure>

              <figure className={styles.bentoCard}>
                <ImageLightbox
                  src="/product/file-types.jpeg"
                  alt="dotViewer file types registry"
                  width={2024}
                  height={1528}
                  sizes="(max-width: 860px) 100vw, 560px"
                  caption={`File types — ${stats.fileTypes} types, ${stats.extensions} extensions`}
                />
                <figcaption>
                  <span>File types</span>
                  <span className={styles.bentoMeta}>
                    {stats.fileTypes} · {stats.extensions} ext
                  </span>
                </figcaption>
              </figure>

              <figure className={styles.bentoCard}>
                <ImageLightbox
                  src="/product/status.jpeg"
                  alt="dotViewer extension status screen"
                  width={2024}
                  height={1528}
                  sizes="(max-width: 860px) 100vw, 560px"
                  caption="Status — conflict scanner"
                />
                <figcaption>
                  <span>Status</span>
                  <span className={styles.bentoMeta}>conflict scanner</span>
                </figcaption>
              </figure>
            </div>
          </Reveal>

          <Reveal as="section" className={styles.block} id="coverage">
            <div className={styles.coverage}>
              <div className={styles.covLeft}>
                <div className={styles.label}>Coverage & honest limits</div>
                <h2 className={styles.h2}>
                  Broad where it helps, honest where macOS still wins.
                </h2>
                <p className={styles.sub}>
                  dotViewer improves Quick Look wherever third-party extensions
                  are allowed. Where macOS owns the preview path, the limitation
                  is stated directly.
                </p>

                <div className={styles.covStats}>
                  <div>
                    <b>{stats.fileTypes}+</b>
                    <small>built-in file types</small>
                  </div>
                  <div>
                    <b>{stats.extensions}+</b>
                    <small>registered extensions</small>
                  </div>
                  <div>
                    <b>{stats.filenameMappings}+</b>
                    <small>exact filenames</small>
                  </div>
                  <div>
                    <b>{routingCaveatCount}</b>
                    <small>macOS routing caveats</small>
                  </div>
                </div>
              </div>

              <div className={styles.covRight}>
                <h4>Known routing caveats</h4>
                <p className={styles.covNote}>
                  <Code>.html</Code> stays with the native HTML Quick Look
                  renderer. macOS routes it system-first, so third-party
                  extensions can't override it.
                </p>
                <p className={styles.covNote}>
                  <Code>.ts</Code> is sometimes claimed by macOS as MPEG-2
                  transport stream video — a platform routing quirk, not a
                  dotViewer bug.
                </p>
                <p className={styles.covNote}>
                  Need a type that isn't shipped?{" "}
                  <a href={issueRequestHref}>Open an issue</a> on GitHub and it
                  lands in a future release.
                </p>
              </div>
            </div>
          </Reveal>

          <Reveal as="section" className={styles.block} id="support-checker">
            <div className={styles.sectionHead}>
              <div className={styles.label}>Support checker</div>
              <h2 className={styles.h2}>
                Check if your file type is supported.
              </h2>
              <p className={styles.sub}>
                Search extensions, filenames, and language aliases. Caveats are
                listed inline when macOS still owns the preview path.
              </p>
            </div>

            <SupportChecker
              issueRequestHref={issueRequestHref}
              issuesHref={issuesHref}
              stats={stats}
              supportedFileTypes={supportedFileTypes}
            />
          </Reveal>

          <Reveal as="section" className={styles.block} id="faq">
            <div className={styles.sectionHead}>
              <div className={styles.label}>FAQ</div>
              <h2 className={styles.h2}>Short answers before installation.</h2>
            </div>

            <div className={styles.faqList}>
              {faqs.map((item) => (
                <details className={styles.faqItem} key={item.id}>
                  <summary>{item.question}</summary>
                  <div className={styles.faqAnswer}>{item.answer}</div>
                </details>
              ))}
            </div>
          </Reveal>

          <Reveal as="section" className={styles.finalCta} delay={0.05}>
            <div className={styles.finalCtaGlow} aria-hidden="true" />
            <h2 className={styles.h2}>
              A better Quick Look workflow for technical files.
            </h2>
            <p className={styles.sub}>
              Inspect the file, understand what it is, keep moving.
            </p>
            <div className={styles.ctaActions}>
              <Link className={styles.primary} href="/download">
                Get the free DMG
              </Link>
              {appStoreHref ? (
                <TrackedDownloadLink
                  assetKind="app_store"
                  className={styles.ghost}
                  releaseTag={null}
                  source="home_page_bottom_cta_app_store"
                  targetUrl={appStoreHref}
                >
                  Buy on App Store
                </TrackedDownloadLink>
              ) : null}
            </div>
          </Reveal>
        </div>
      </main>

      <footer className={styles.footer}>
        <div className={styles.wrap}>
          <div className={styles.footerInner}>
            <div className={styles.footerCopy}>
              <strong>dotViewer</strong> · Better Quick Look for macOS
              <div className={styles.footerSub}>
                Created by <a href={CREATOR_URL}>{CREATOR_NAME}</a>. Also from
                the same creator: <a href={DBHOST_URL}>dbHost</a> for free
                PostgreSQL database management.
              </div>
            </div>
            <div className={styles.footerLinks}>
              <a href="#previews">Previews</a>
              <a href="#install">Install</a>
              <a href="#controls">Controls</a>
              <a href="#coverage">Coverage</a>
              <a href="#faq">FAQ</a>
              <Link href="/download">Download</Link>
              {appStoreHref ? <a href={appStoreHref}>App Store</a> : null}
              <a href={releasesHref}>Releases</a>
              <a href={repoHref}>GitHub</a>
            </div>
          </div>
        </div>
      </footer>
      <script
        type="application/ld+json"
        suppressHydrationWarning
        {...({ dangerouslySetInnerHTML: { __html: schemaJson } } as Record<
          string,
          unknown
        >)}
      />
    </div>
  );
}
