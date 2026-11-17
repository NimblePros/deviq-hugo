---
title: "Hanlon's Razor: Never Attribute to Malice What Incompetence Explains"
date: 2026-11-17
description: Hanlon's Razor advises against assuming malice when ignorance, mistakes, or incompetence adequately explain an outcome. In software, misconfiguration and bugs cause far more failures than attackers do.
params:
  image: /laws/images/hanlons-razor.png
weight: 105
---

![hanlon's razor](./images/hanlons-razor.png)

*"Never attribute to malice that which is adequately explained by stupidity."* — Hanlon's Razor

Hanlon's Razor is a rule of thumb for choosing between explanations. When something goes wrong, the simplest and most likely cause is usually an honest mistake, not a deliberate act of sabotage. In software, this matches experience: far more outages, data leaks, and strange behaviors trace back to bugs, misconfiguration, and human error than to hackers and attackers.

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Origin](#origin)
- [The Razor Stated](#the-razor-stated)
- [Why It Matters to Software Teams](#why-it-matters-to-software-teams)
- [Hanlon's Razor in Practice](#hanlons-razor-in-practice)
- [What the Razor Does Not Mean](#what-the-razor-does-not-mean)
- [Relation to Other Principles](#relation-to-other-principles)
- [See Also](#see-also)
- [References](#references)

## Origin

The name comes from Robert J. Hanlon, who submitted the line "Never attribute to malice that which is adequately explained by stupidity" to *Murphy's Law Book Two: More Reasons Why Things Go Wrong!* (1980), a collection of Murphy's Law variations compiled by Arthur Bloch. The sentiment is older than that attribution. Similar ideas appear in H. G. Wells's *The Wheels of Chance* (1896) and in the writing of William James Laidlay, and Robert A. Heinlein expressed it in the 1941 novella *Logic of Empire*: "You have attributed conditions to villainy that simply result from stupidity." A similar quote is often misattributed to Napoleon Bonaparte. The phrase "Hanlon's Razor" itself was popularized by the Jargon File, a glossary of programmer slang, in 1990.

A *razor* is a principle that lets you "shave away" unlikely explanations. The best-known example is Occam's Razor, which favors the explanation with the fewest assumptions. Hanlon's Razor applies the same idea to human behavior: explaining a problem with malice requires an adversary with motive, skill, and opportunity, while explaining it with a mistake requires only a person being human.

## The Razor Stated

Many people prefer a gentler wording than the original, and "stupidity" is a poor fit for a professional setting. Common variations include:

- Never attribute to malice that which can be explained by incompetence.
- Never attribute to malice that which is adequately explained by neglect, ignorance, or error.
- Assume good faith until the evidence says otherwise.

In every form, the razor sets the default: investigate the ordinary explanations first and move to the extraordinary ones only when the ordinary ones fail.

## Why It Matters to Software Teams

Software is written by people under deadline pressure, working with incomplete information, on systems too large to hold in one head. Mistakes are the normal operating condition. Consider where production problems typically come from:

- A configuration change that points at the wrong database or disables a safeguard.
- An expired certificate that nobody remembered to renew.
- A deployment that skipped a migration step.
- A cloud storage bucket left publicly readable because the default was never changed.
- A bug in a rarely exercised code path that finally runs.

Each of these can look like an attack from the outside. Data is exposed, a service stops responding, records change unexpectedly. Yet the cause is far more often internal and unintentional than the work of an attacker. Teams that review their own incidents commonly find that misconfiguration, a faulty change, or human error sits at the root. This is closely related to [Murphy's Law](/laws/murphys-law/): if something can go wrong, someone will eventually make it go wrong without meaning to.

The same applies to how teammates treat each other. A confusing pull request, a missed requirement, or a broken build is far more likely to come from a misunderstanding than from someone trying to make your life difficult.

## Hanlon's Razor in Practice

### Debugging

When a system misbehaves, suspect your own changes first. Check recent deployments, configuration changes, and dependency updates before concluding that the compiler, the framework, or an attacker is at fault. The maxim "select isn't broken," popularized by *The Pragmatic Programmer* (Hunt and Thomas), is Hanlon's Razor applied to debugging: the problem is almost always in code you control, not in the compiler, database, or operating system. Techniques like [rubber duck debugging](/practices/rubber-duck-debugging/) work in part because explaining your assumptions aloud exposes the ordinary mistake you overlooked.

```csharp
// A "mysterious" outage: requests suddenly fail in production only.
// Before suspecting an attack, compare the configuration that actually shipped.
public sealed class ConnectionSettings
{
    public string Host { get; init; } = string.Empty;
    public int TimeoutSeconds { get; init; }
}

public static class StartupValidator
{
    // Failing fast on bad configuration turns a vague outage into a clear message.
    public static void Validate(ConnectionSettings settings)
    {
        if (string.IsNullOrWhiteSpace(settings.Host))
            throw new InvalidOperationException("ConnectionSettings:Host is required.");

        if (settings.TimeoutSeconds is <= 0 or > 300)
            throw new InvalidOperationException(
                $"ConnectionSettings:TimeoutSeconds must be 1-300 but was {settings.TimeoutSeconds}.");
    }
}
```

Validating configuration at startup is a direct response to the razor. If mistakes are the likely cause, make them loud and cheap to find. See [Fail Fast](/principles/fail-fast/).

### Postmortems and Incident Response

A *blameless postmortem* examines an incident to understand what happened and how to prevent it, without assigning fault to individuals. It is Hanlon's Razor institutionalized. If you assume people acted with good intent and made reasonable decisions with the information they had, the useful question shifts from "who did this?" to "what allowed this to happen?" That question leads to better guardrails: validation, automation, safer defaults, and clearer documentation. Hunting for a culprit tends to teach people to hide mistakes, which makes the next incident harder to diagnose.

### Code Review and Team Communication

Assume good intent when reviewing code and reading messages. A strange design choice is more likely a gap in context than carelessness or spite, so ask a question before leveling a criticism. A short, curious "what was the reason for this approach?" resolves most disagreements faster than an accusation. This habit supports [feedback](/values/feedback/) and [communication](/values/communication/) on a team, and it is the practical side of [respecting people](/principles/respect-people/).

## What the Razor Does Not Mean

Hanlon's Razor is a heuristic for ordering your hypotheses, not a guarantee that no one is ever acting maliciously.

- **Security still matters.** Real attackers exist, and treating every anomaly as a mistake is as dangerous as treating every anomaly as an attack. Authenticate, authorize, validate input, and monitor regardless of how likely any single incident is to be malicious. [The network is not secure](/fallacies/the-network-is-secure/).
- **Defense in depth beats guessing intent.** Good security design assumes both mistakes and attacks and protects against each. A guardrail that stops an accidental misconfiguration often stops a malicious one too.
- **It is not an excuse for negligence.** "It was just a mistake" explains a failure but does not erase responsibility for fixing it. Repeated, unaddressed incompetence still needs to be handled through training, process, or staffing.
- **Evidence overrides the default.** When logs show a pattern of targeted, repeated, or concealed activity, stop assuming an accident. Grey's law, a riff on Clarke's third law, holds that sufficiently advanced incompetence is indistinguishable from malice. When the two are hard to tell apart, treat the situation with caution while you gather evidence.

## Relation to Other Principles

- [Murphy's Law](/laws/murphys-law/) explains why mistakes are inevitable; Hanlon's Razor tells you to expect them first when diagnosing a failure.
- [Wheaton's Law](/laws/wheatons-law/) asks you to treat colleagues decently. Assuming good intent is one way to follow it.
- [Hofstadter's Law](/laws/hofstadters-law/) and [Postel's Law](/laws/postels-law/) both acknowledge that people and systems behave imperfectly and ask you to plan for it.
- [Fail Fast](/principles/fail-fast/) and [Defensive Programming](/practices/defensive-programming/) make errors visible early, which keeps honest mistakes from being mistaken for something worse.

## See Also

- [Murphy's Law](/laws/murphys-law/)
- [Wheaton's Law](/laws/wheatons-law/)
- [Respect People](/principles/respect-people/)
- [Fail Fast](/principles/fail-fast/)
- [Defensive Programming](/practices/defensive-programming/)
- [Rubber Duck Debugging](/practices/rubber-duck-debugging/)

## References

- [Hanlon's Razor](https://en.wikipedia.org/wiki/Hanlon%27s_razor) (Wikipedia)
- [Murphy's Law Book Two: More Reasons Why Things Go Wrong!](https://archive.org/details/murphyslawbooktw00bloc) (Arthur Bloch, 1980)
