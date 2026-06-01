---
name: comment-writer
description:
  'Write warm, direct collaboration comments. Trigger: PR feedback, issue replies, reviews, Slack
  messages, or GitHub comments.'
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: '1.0'
  origin: https://github.com/Gentleman-Programming/gentle-ai
metadata:
  source: GV-native
---

## When to Use

Load this skill whenever you write a comment that another human will read.

Use it for:

- GitHub PR or issue comments.
- Review feedback and requested changes.
- Maintainer replies.
- Slack, Discord, or async project updates.

## Voice Rules

| Rule                  | Requirement                                                                                                                  |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Be useful fast        | Start with the actionable point. Do not recap the whole PR before feedback.                                                  |
| Be warm and direct    | Sound like a thoughtful teammate, not a corporate bot.                                                                       |
| Keep it short         | Prefer 1 to 3 short paragraphs or a tight bullet list.                                                                       |
| Explain why           | Give the technical reason when asking for a change.                                                                          |
| Avoid pile-ons        | Comment on the highest-value issue, not every tiny preference.                                                               |
| Match thread language | Write in the thread/user language. If writing in Spanish, use Rioplatense Spanish/voseo: `podés`, `tenés`, `fijate`, `dale`. |
| No em dashes          | Use commas, periods, or parentheses instead.                                                                                 |

## Comment Formula

```text
<Direct observation or request>

<Why it matters, only if needed>

<Concrete next action>
```

## Examples

### Request change

```markdown
Buenísimo el enfoque. Acá separaría este cambio en otro commit porque mezcla la validación con el
wiring de UI.

Eso le baja carga al reviewer y hace que el rollback sea más claro si falla la integración.
```

### Approve with a note

```markdown
Está bien encaminado y el scope se entiende rápido.

Dejo aprobado. Para el próximo PR, agregá el link al anterior y al siguiente así la cadena queda
navegable.
```

### Ask for split

```markdown
Este PR supera el presupuesto de 400 líneas cambiadas, así que necesitamos dividirlo o justificar
`size:exception`.

Mi sugerencia: primero gentle-vanguard + tests, después integración, después docs. Así cada review
tiene inicio y fin claros.
```

## Commands

```bash
# Inspect a PR before writing review feedback
gh pr view <PR_NUMBER> --json title,body,additions,deletions,changedFiles
```

---

_Origin: [gentle-ai](https://github.com/Gentleman-Programming/gentle-ai) — Apache-2.0 License.
Powered by [Gentleman Programming](https://github.com/Gentleman-Programming)._
