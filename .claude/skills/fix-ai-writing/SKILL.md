---
name: fix-ai-writing
version: 3.1.0
description: |
  Use when editing prose, technical docs, or READMEs to remove AI writing
  patterns. Detects and rewrites 42 general patterns plus 7 technical-doc
  patterns. Based on Wikipedia's "Signs of AI writing" guide.
license: MIT
compatibility: any-agent
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - AskUserQuestion
---

# Fix AI Writing

Identify and rewrite AI-generated text patterns. Based on [Wikipedia:Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing).

## Process

1. Scan for the patterns below. For technical docs, also apply T1-T7.
2. Write a **draft rewrite**. Match the register. Vary sentence length. Prefer simple constructions (is/are/has) and concrete specifics.
3. Self-check: **"What still reads as AI?"** List remaining tells.
4. Revise into a **final rewrite**. Scan for `—` and `–` before returning (see §14).

Deliver: draft, "still AI" bullets, final rewrite, summary of changes.

## Voice

**If the user provides a writing sample,** read it first. Note:
- Sentence length (short and punchy? long and flowing? mixed?)
- Word choice level (casual? academic?)
- How they start paragraphs and handle transitions
- Punctuation habits (parenthetical asides? semicolons?)
- Recurring phrases or verbal tics

Match their voice in the rewrite. If they write short sentences, don't produce long ones. If they use "stuff," don't upgrade to "elements."

To provide a sample: inline ("Here's a sample of my writing: [sample]") or by file path.

**When no sample is provided** and the content calls for it (blog posts, essays, opinion): have opinions, vary rhythm, let some mess in. For technical, legal, or reference text, neutral and plain *is* the correct voice.

Signs that clean text is still soulless:
- Every sentence is the same length and structure
- No opinions, just neutral reporting
- No acknowledgment of uncertainty or mixed feelings
- No first-person perspective when appropriate
- Reads like a Wikipedia article or press release

> Soulless: "The experiment produced interesting results. The agents generated 3 million lines of code. Some developers were impressed while others were skeptical."
> Has a pulse: "I genuinely don't know how to feel about this one. 3 million lines of code, generated while the humans presumably slept. Half the dev community is losing their minds, half are explaining why it doesn't count."


## CONTENT PATTERNS

### 1. Significance inflation

**Watch for:** stands/serves as, is a testament, vital/crucial/pivotal role, underscores importance, reflects broader, evolving landscape, indelible mark, deeply rooted

**Problem:** LLMs puff up importance with statements about how things represent or contribute to broader topics.

> Before: "established in 1989, marking a pivotal moment in the evolution of regional statistics"
> After: "established in 1989 to collect and publish regional statistics independently"


### 2. Notability inflation

**Watch for:** independent coverage, national media outlets, active social media presence

**Problem:** Lists sources without context to hammer notability.

> Before: "cited in The New York Times, BBC, Financial Times, and The Hindu"
> After: "In a 2024 New York Times interview, she argued that AI regulation should focus on outcomes"


### 3. Superficial -ing analyses

**Watch for:** highlighting, underscoring, ensuring, reflecting, symbolizing, contributing to, fostering, showcasing

**Problem:** Present participle phrases tacked onto sentences for fake depth.

> Before: "resonates with the region's natural beauty, symbolizing Texas bluebonnets"
> After: "The architect said these colors reference local bluebonnets and the Gulf coast."


### 4. Promotional language

**Watch for:** boasts, vibrant, rich, profound, showcasing, nestled, in the heart of, groundbreaking, renowned, breathtaking, must-visit, stunning

> Before: "Nestled within the breathtaking region, it stands as a vibrant town"
> After: "Alamata Raya Kobo is a town in the Gonder region, known for its weekly market"


### 5. Vague attributions

**Watch for:** Industry reports, Experts argue, Some critics argue, several sources

**Problem:** Opinions attributed to unnamed authorities.

> Before: "Experts believe it plays a crucial role in the regional ecosystem"
> After: "supports several endemic fish species, according to a 2019 survey by the Chinese Academy of Sciences"


### 6. "Challenges and Future Prospects" formula

**Watch for:** Despite its... faces several challenges..., Despite these challenges, Future Outlook

> Before: "Despite these challenges, Korattur continues to thrive as an integral part of Chennai's growth"
> After: "Traffic congestion increased after 2015 when three new IT parks opened"


## LANGUAGE AND GRAMMAR PATTERNS

### 7. AI vocabulary words

**High-frequency:** additionally, align with, crucial, delve, enduring, enhance, fostering, garner, highlight (verb), interplay, intricate, key (adj), landscape (abstract), pivotal, showcase, tapestry (abstract), testament, underscore, valuable, vibrant

These words co-occur far more frequently in post-2023 text.


### 8. Copula avoidance

**Watch for:** serves as, stands as, marks, represents [a], boasts, features, offers [a]

> Before: "Gallery 825 serves as LAAA's exhibition space... boasts over 3,000 square feet"
> After: "Gallery 825 is LAAA's exhibition space... has four rooms totaling 3,000 square feet"


### 9. Negative parallelisms

"Not only...but..." and "It's not just about..., it's..." are overused. Also tailing negation fragments: "no guessing," "no wasted motion."

> Before: "It's not merely a song, it's a statement"
> After: "The heavy beat adds to the aggressive tone"

> Before (tailing negation): "The options come from the selected item, no guessing."
> After: "The options come from the selected item without forcing the user to guess."


### 10. Rule of three

LLMs force ideas into groups of three.

> Before: "keynote sessions, panel discussions, and networking opportunities"
> After: "The event includes talks and panels. There's also time for informal networking."


### 11. Synonym cycling

Repetition-penalty causes excessive synonym substitution.

> Before: "The protagonist faces many challenges. The main character must overcome obstacles. The central figure eventually triumphs. The hero returns home."
> After: "The protagonist faces many challenges but eventually triumphs and returns home."


### 12. False ranges

"From X to Y" where X and Y aren't on a meaningful scale.

> Before: "from the singularity of the Big Bang to the grand cosmic web"
> After: "covers the Big Bang, star formation, and current theories about dark matter"


### 13. Passive voice / subjectless fragments

> Before: "No configuration file needed. The results are preserved automatically."
> After: "You do not need a configuration file. The system preserves the results automatically."


## STYLE PATTERNS

### 14. Em dashes: cut them

**Hard constraint.** The final rewrite contains no em dashes (—) or en dashes (–). Replace with: period, comma, colon, parentheses, or restructure. Also catch spaced em dashes (` — `) and double hyphens (` -- `).

Scan the final output for `—` and `–` before returning. Any hit means the draft isn't done.


### 15. Boldface overuse

> Before: "blends **OKRs**, **KPIs**, and **Business Model Canvas**"
> After: "blends OKRs, KPIs, and visual strategy tools like the Business Model Canvas"


### 16. Inline-header vertical lists

> Before:
> - **User Experience:** The user experience has been significantly improved.
> - **Performance:** Performance has been enhanced through optimized algorithms.
> - **Security:** Security has been strengthened with end-to-end encryption.

> After: "The update improves the interface, speeds up load times through optimized algorithms, and adds end-to-end encryption."


### 17. Title case in headings

> Before: "## Strategic Negotiations And Global Partnerships"
> After: "## Strategic negotiations and global partnerships"


### 18. Emojis

> Before: "🚀 **Launch Phase:** The product launches in Q3"
> After: "The product launches in Q3."


### 19. Curly quotation marks

Replace "..." with "...".


## COMMUNICATION PATTERNS

### 20. Chatbot artifacts

**Watch for:** I hope this helps, Of course!, Certainly!, Would you like..., let me know

> Before: "Here is an overview of the French Revolution. I hope this helps! Let me know if you'd like me to expand on any section."
> After: "The French Revolution began in 1789 when financial crisis and food shortages led to widespread unrest."


### 21. Knowledge-cutoff disclaimers / speculative gap-filling

> Before: "While specific details about the company's founding are not extensively documented in readily available sources, it appears to have been established sometime in the 1990s."
> After: "The company was founded in 1994, according to its registration documents."

When a model can't find a source, it writes a paragraph *about* not finding one and invents plausible filler. Say what's unknown, or cut the sentence.


### 22. Sycophantic tone

> Before: "Great question! You're absolutely right that this is a complex topic. That's an excellent point about the economic factors."
> After: "The economic factors you mentioned are relevant here."


## FILLER AND HEDGING

### 23. Filler phrases

"In order to" → "To". "Due to the fact that" → "Because". "At this point in time" → "Now". "Has the ability to" → "Can". "It is important to note that" → cut.


### 24. Excessive hedging

> Before: "It could potentially possibly be argued that the policy might have some effect"
> After: "The policy may affect outcomes"


### 25. Generic positive conclusions

"The future looks bright" / "Exciting times lie ahead" / "a major step in the right direction"

Replace with a concrete fact or cut.


### 26. Hyphenated word overuse

AI hyphenates uniformly, including in predicate position. Humans drop the hyphen after the noun.

> Before: "The team is cross-functional, the report is high-quality, and the methodology is data-driven."
> After: "The team is cross functional, the report is high quality, and the methodology is data driven."


### 27. Persuasive authority tropes

"The real question is...", "At its core...", "What really matters is..."

Replace the formula with the concrete claim.


### 28. Signposting

"Let's dive in," "let's explore," "here's what you need to know"

Cut. Just say the thing.


### 29. Fragmented headers

A heading followed by a one-line paragraph restating the heading. Delete the restatement.


### 30. Diff-anchored writing

Writing that narrates a change ("This was added to replace...") instead of describing the current state. Unless the document is a changelog, write about what exists now.


### 31. Manufactured punchlines

Stacked short declarative fragments for drama. One short sentence for emphasis is fine. A run of them is engineered.

> Before: "Then AlphaEvolve arrived. It had no preference for symmetry. No aesthetic prior. The old rules were gone."
> After: "AlphaEvolve did not favor symmetry or human-looking designs. That made some older assumptions less useful."


### 32. Aphorism formulas

"X is the Y of Z," "X becomes a trap," "the language of," "the architecture of"

Replace with the concrete claim.


### 33. Conversational rhetorical openers

"Honestly?", "Look,", "Here's the thing" as standalone hooks before an ordinary point. The tell is the theatrical pause-and-reveal, not the word itself.


### 34. Section summaries

A paragraph at the end of a section restating what it just said. Delete it.


### 35. Abrupt style shifts

Register, sentence length, or vocabulary changes sharply between adjacent sections. LLMs don't maintain voice across long outputs.


### 36-42. Quick checks

- **36. Markdown in non-Markdown contexts.** `**bold**` in plain text, emails, or wiki markup.
- **37. Heading level skips.** H2 to H4 without H3.
- **38. Horizontal rules before headings.** `---` before a section header. Redundant.
- **39. Placeholder language.** [Insert X here], "as appropriate," "as applicable."
- **40. Fabricated references.** DOIs, ISBNs, or URLs that don't resolve. Check if possible, flag if not.
- **41. Prompt refusal leaking.** "I can't help with," "As an AI."
- **42. Abrupt cutoffs.** Text stopping mid-sentence from token limits.


## TECHNICAL DOC PATTERNS

Apply these when the target is a README, API doc, architecture doc, or runbook.

### T1. Feature-list puffery

"Powerful," "robust," "seamless," "comprehensive." Describe what the thing does, not how great it is.

> Before: "Our powerful CLI provides seamless integration with robust error handling"
> After: "The CLI reads your config, runs the migration, and logs each step to stdout"

### T2. Fake simplicity

"Simply run..." / "Just add..." before a multi-step process.

> Before: "Simply install the package and you're ready to go!"
> After: "Install the package. You'll also need a database connection (see Configuration)."

### T3. Badge walls

15+ badges at the top of a README. Keep ones the reader needs to decide whether to use the project. Cut the rest.

### T4. Aspirational architecture

Documenting the system you wish you had. Write what the code does today.

### T5. Copy-paste API docs

Every endpoint: "This endpoint allows you to [verb] a [noun]. It accepts the following parameters..." Vary the structure or just show request/response.

### T6. Changelog theater

"Improved performance," "enhanced stability," "fixed minor bugs." If you can't name the change, the entry is filler.

> Before: "Improved overall performance"
> After: "Reduced cold-start time from 4s to 800ms by lazy-loading the config parser"

### T7. Redundant overview sections

> Before: "## Overview\nMyTool is a command-line tool for managing database migrations. It provides..."
> After: "MyTool manages database migrations from the command line."


## FALSE POSITIVES

Single instances of any pattern are not reliable tells. Look for **clusters**. Do not flag:

- Perfect grammar (professionals exist)
- Formal vocabulary (§7 targets *specific* AI words, not all fancy words)
- Em dashes alone (common among editors; flag only with other tells)
- One short emphatic sentence (flag only stacked runs)
- Curly quotes alone (OS auto-curl)
- Unsourced claims (most of the web is unsourced)
- Secondhand text (don't rewrite watched phrases inside quotations, titles, or examples)

A single em dash means nothing. Em dashes plus rule-of-three plus *vibrant tapestry* plus a "Conclusion" section is a confession.

**Preserve signs of human writing:** specific hard-to-fabricate details, mixed feelings, era-bound references, genuine asides and self-corrections, varied sentence length.


## Example

See `example-lisbon.md` in this directory for a full before/draft/audit/final walkthrough.


## Reference

Based on [Wikipedia:Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing), maintained by WikiProject AI Cleanup. Patterns 34-42 and T1-T7 extend the Wikipedia source.
