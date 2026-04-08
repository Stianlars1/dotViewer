# dotViewer Growth And Monetization Plan

*Prepared: 2026-04-04*

## Current baseline

- `dotviewer.app` already has a solid technical SEO base: canonical metadata, sitemap, robots, JSON-LD, release-backed `/download`, and first-party analytics hooks.
- Public GitHub release data shows `17` total DMG downloads so far: `12` for `v1.0.0` and `5` for `v1.1.0`.
- Public GitHub repo baseline is still effectively zero social proof: `0` stars, `0` watchers, `0` forks.
- A public Apple App Store listing for `dotViewer` is already live. The site previously positioned the app as free/direct-only, which created a monetization mismatch.
- The site currently has strong homepage and download pages, but no content engine yet. That means search intent is being captured only by two pages instead of a compounding library.

## Core strategy

### 1. Use a two-lane model instead of one-lane positioning

- **Lane 1: Free direct DMG**
  Best for reach, trials, linkability, GitHub distribution, and low-friction adoption.
- **Lane 2: Paid App Store**
  Best for monetization, convenience, trust, and store-managed installation.

This is the right model for a utility like dotViewer because:

- `Zero-price effect`: free direct download removes the first barrier.
- `Endowment effect`: once people install and use dotViewer, paying for convenience becomes easier.
- `Paradox of choice`: two install choices are enough. More pricing surfaces would add friction.
- `Mental accounting`: users can frame the App Store purchase as “support the developer” and “get the store version,” not “pay for basic access.”

### 2. Sell the job, not the feature list

The winning job-to-be-done is:

> “Let me inspect technical files in Finder without opening an editor.”

Everything in acquisition should reinforce that job:

- preview dotfiles on macOS
- preview config files in Finder
- Quick Look markdown viewer
- Finder code preview
- preview `.gitignore`
- preview `.env`

Do not lead with implementation details like tree-sitter or file-type counts unless the audience is already technical and evaluating depth.

### 3. Build distribution before building more product

dotViewer does not have a product problem first. It has a discovery and proof problem:

- not enough public distribution
- not enough third-party mentions
- not enough reviews
- not enough “people like me use this” signals

For the next 60-90 days, distribution should beat feature expansion unless a feature directly improves conversion or retention.

## North star and KPIs

### North star

- **Qualified installs per month**
  Count both direct DMG handoffs and App Store intent/purchases.

### Leading indicators

- Search impressions and clicks from Google Search Console
- `/download` page visits
- direct DMG click-through rate
- App Store click-through rate
- GitHub release download count
- App Store ratings and reviews
- branded search volume for `dotViewer`
- number of third-party mentions and backlinks

### Weekly operating metrics

- new landing pages published
- new content pieces published
- new directories/platforms listed
- new social/community posts shipped
- new reviews collected

## The acquisition plan

## Phase 1: Fix distribution and attribution (week 1)

### Goals

- stop hiding the monetization path
- measure paid-channel intent separately
- create a stable channel story

### Actions

1. Keep `dotviewer.app/download` as the main install chooser.
2. Surface both paths clearly:
   - free direct DMG
   - paid App Store
3. Track App Store clicks the same way DMG clicks are tracked.
4. Add Search Console and Bing Webmaster Tools if not already set up.
5. Submit sitemap through Search Console and monitor the indexed pages report.
6. Establish a weekly funnel report:
   - homepage visits
   - `/download` visits
   - DMG clicks
   - App Store clicks
   - GitHub release downloads

### Success criteria

- you can answer “which pages create installs?”
- you can answer “which channel creates paid intent?”

## Phase 2: Ship the highest-leverage distribution channels (weeks 1-3)

### 1. Homebrew Cask

This is one of the highest-fit channels for dotViewer because the target user is already technical and comfortable with package managers.

Current local check:

- `brew search --casks dotviewer` does not show a `dotviewer` cask right now.

Action:

- submit a Homebrew Cask for dotViewer
- point it at the notarized DMG
- mention it on the site and README after it lands

Expected value:

- stronger developer credibility
- recurring passive discovery from Mac power users
- easier word-of-mouth sharing

### 2. Product Hunt

Use Product Hunt as a launch event, not as the entire strategy.

Action:

- prepare a short launch pack:
  - 45-60 second demo
  - 4-6 screenshots
  - one-line hook focused on Finder Quick Look pain
  - “why this exists” founder comment
- launch when the Homebrew cask and install chooser are live
- drive traffic from personal accounts and relevant communities, not from paid ads first

Expected value:

- burst traffic
- early reviews
- public proof point

### 3. Hacker News / Show HN

dotViewer fits `Show HN` well because it solves a specific developer annoyance.

Angle:

- “Show HN: a macOS Quick Look extension for dotfiles, configs, markdown, and code”

What matters:

- honest story
- technical screenshots
- clear limitation handling
- fast answers in comments

Expected value:

- high-signal early adopters
- strong feedback
- durable backlinks and discussion

### 4. Mac and dev communities

Priority communities:

- `r/macapps`
- `r/mac`
- `r/swift`
- `r/programming`
- Indie Hackers
- X / LinkedIn from the founder account

Rules:

- do not post generic launch copy
- show the pain and the before/after workflow
- use real screenshots
- post as the founder in first person

### 5. Existing plugin and app lists

dotViewer should be added anywhere technical Mac users browse utilities:

- Quick Look plugin lists
- Mac app newsletters
- Mac productivity and developer-tool roundups
- “best apps for developers on Mac” collections

This is boring work, but it compounds.

## Phase 3: Build the SEO content engine (weeks 2-8)

### Content thesis

The content should end the search, not just match the keyword.

The best topics are painkiller topics where the reader is actively trying to solve a workflow annoyance on macOS.

### Page types to build first

1. **Problem-solving pages**
   - `how to preview dotfiles on macOS`
   - `how to preview .env files in Finder`
   - `how to preview README.md in Quick Look`
   - `how to preview JSON and YAML files on Mac`

2. **Alternative / comparison pages**
   - `dotViewer vs QLMarkdown`
   - `dotViewer vs QLStephen`
   - `best Quick Look plugins for developers on Mac`

3. **Use-case landing pages**
   - `Quick Look for developers`
   - `Quick Look for DevOps and SRE workflows`
   - `Finder markdown viewer for Mac`

4. **Evergreen proof assets**
   - `supported file types`
   - `dotfiles you can preview with dotViewer`
   - `why macOS Quick Look misses technical files`

### First 12 article/page ideas

1. Preview dotfiles on macOS without opening an editor
2. How to preview `.env` files safely on Mac
3. The best way to preview `README.md` in Finder
4. How to Quick Look JSON, YAML, XML, and INI files on macOS
5. Best Quick Look plugins for developers on Mac
6. dotViewer vs QLMarkdown
7. dotViewer vs QLStephen
8. How to preview shell scripts in Finder
9. How to preview log files on macOS
10. Why Finder Quick Look is weak for technical files
11. How to inspect config files faster during code review
12. How to reduce editor context switching on Mac

### Content rules

- use first-person founder voice where appropriate
- use real screenshots from the product
- answer the search fully
- keep the CTA soft and relevant:
  - “Try the free DMG”
  - “Prefer store installs? Buy on the App Store”

## SEO and schema priorities

### What to keep doing

- keep canonical URLs tight
- keep crawlable links and internal links plain and simple
- keep sitemap current and submitted
- keep structured data accurate

### What not to over-invest in

- FAQ rich results are not a near-term growth lever

Google’s current FAQ rich-result guidance limits that feature to well-known, authoritative government or health sites. Keep FAQ content for users, but do not expect SERP FAQ expansion to drive growth here.

### Highest-value schema improvements

1. Keep `SoftwareApplication`, `Organization`, `WebSite`, `CollectionPage`, and `BreadcrumbList`.
2. Link the software entity to the App Store listing using `sameAs`.
3. Once there are real public ratings and reviews that are visible on-page, add `aggregateRating` or review markup where it accurately matches the page content.
4. If you publish demo videos on-page, add `VideoObject`.

## Monetization plan

## Layer 1: Direct free DMG + paid App Store

This should be the default operating model now.

### Why it works

- free DMG maximizes usage and linkability
- paid App Store monetizes convenience and trust
- the two channels do not cannibalize each other as much as people fear because they serve different buying motives

### Messaging

- **Free DMG**: fastest way to try dotViewer
- **App Store**: easiest way to buy, install, and support the app

### What to measure

- ratio of DMG clicks to App Store clicks
- ratio of homepage visitors to chooser clicks
- App Store ratings velocity after launches

## Layer 2: Setapp

Setapp is worth testing because it already markets Mac apps to a large paid audience and explicitly supports additional distribution rather than exclusivity.

Why it fits:

- technical Mac audience
- another monetization stream without killing direct download
- helpful for visibility even if direct revenue starts modestly

Action:

- apply after the site/install chooser and review collection are cleaner
- use Setapp as an additional channel, not the only business model

## Layer 3: Direct supporter or team monetization later

Do not rush to subscriptions for a utility like this.

More sensible later-stage options:

- supporter license / tip jar on the site
- team or company license for developer teams
- paid “priority support / file-type request” lane for companies
- advanced team settings export/import or policy management if enterprise demand appears

### What not to do yet

- do not put the core product behind a subscription now
- do not split the experience into confusing free/pro tiers before distribution is working
- do not add pricing complexity before the App Store + direct model has been tested properly

## The 30-day execution checklist

- [ ] Add and verify Google Search Console
- [ ] Submit sitemap and inspect indexing
- [ ] Ship Homebrew Cask
- [ ] Launch Product Hunt
- [ ] Post Show HN
- [ ] Publish 4 painkiller SEO pages
- [ ] Publish 2 comparison pages
- [ ] Ask every new happy user for an App Store rating
- [ ] Add dotViewer to at least 10 directories/lists/newsletters
- [ ] Build a weekly funnel dashboard from existing analytics + GitHub + App Store data

## The 90-day target

- move from “single launch page” to “content-backed search surface”
- move from “unknown utility” to “present in the main Mac/dev discovery channels”
- move from “free app with unclear money path” to “clear dual-channel product with measured paid intent”

## Sources

- Google Search Central SEO starter guide: https://developers.google.com/search/docs/fundamentals/seo-starter-guide
- Google Search Central on crawlable links: https://developers.google.com/search/docs/crawling-indexing/links-crawlable
- Google Search Central on building and submitting sitemaps: https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap
- Google Search Central FAQ structured data guidance: https://developers.google.com/search/docs/appearance/structured-data/faqpage
- Setapp developer program: https://setapp.com/developers
- Product Hunt help: https://help.producthunt.com/en/articles/1444961-how-do-i-get-my-product-promoted
- Apple App Store listing discovered for dotViewer: https://apps.apple.com/us/app/dotviewer/id6757806533?mt=12
