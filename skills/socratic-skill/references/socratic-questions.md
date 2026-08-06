# The Six Types of Socratic Questions

Full reference: detailed tables, questions, and examples for each type.

## 1. Clarification Questions

**Purpose:** Ensure clear understanding of the claim or concept.

| Question                      | Use When                |
| ----------------------------- | ----------------------- |
| "What do you mean by X?"      | Term is ambiguous       |
| "Can you give me an example?" | Concept is abstract     |
| "How does this relate to Y?"  | Connection unclear      |
| "Can you rephrase that?"      | Statement is confusing  |
| "What is the main point?"     | Discussion is scattered |

**Example:**

> "The system needs to be fast." → "What do you mean by 'fast'? What latency is acceptable?" → "Fast
> for whom? End users? Batch processes?"

## 2. Assumption-Probing Questions

**Purpose:** Expose underlying beliefs that may be unexamined.

| Question                                          | Use When                   |
| ------------------------------------------------- | -------------------------- |
| "What are we assuming here?"                      | Conclusion seems too quick |
| "Is this always true?"                            | Generalization made        |
| "What if that assumption is wrong?"               | Testing robustness         |
| "Why do we believe this?"                         | Basis unclear              |
| "What would have to change for this to be false?" | Finding conditions         |

**Example:**

> "We need microservices for scale." → "What are we assuming about our scale requirements?" → "Is it
> always true that microservices scale better?" → "What if a modular monolith could meet our needs?"

## 3. Reason & Evidence Questions

**Purpose:** Examine the support for a claim.

| Question                        | Use When                |
| ------------------------------- | ----------------------- |
| "What evidence supports this?"  | Claim is asserted       |
| "How do we know this?"          | Source unclear          |
| "Are there other explanations?" | Causation assumed       |
| "What would prove this wrong?"  | Testing falsifiability  |
| "Is this evidence sufficient?"  | Conclusion seems strong |

**Example:**

> "Users don't want feature X." → "What evidence do we have for this?" → "How many users did we ask?
> How were they selected?" → "Could there be other explanations for the feedback?"

## 4. Perspective & Viewpoint Questions

**Purpose:** Consider alternative angles and stakeholders.

| Question                          | Use When                     |
| --------------------------------- | ---------------------------- |
| "How would X see this?"           | Single perspective dominates |
| "What's the opposite view?"       | No alternatives considered   |
| "Who disagrees, and why?"         | Consensus seems too easy     |
| "What are we not seeing?"         | Blind spots suspected        |
| "How does this look from [role]?" | Stakeholder impact unclear   |

**Example:**

> "This API design is intuitive." → "How would a new developer view this?" → "What would someone
> from a different language background expect?" → "Who might find this confusing, and why?"

## 5. Implication & Consequence Questions

**Purpose:** Explore downstream effects and logical conclusions.

| Question                                   | Use When                      |
| ------------------------------------------ | ----------------------------- |
| "What follows from this?"                  | Implications unexplored       |
| "If this is true, what else must be true?" | Testing consistency           |
| "What are the consequences?"               | Impact unclear                |
| "How does this affect X?"                  | Ripple effects not considered |
| "What are the second-order effects?"       | Only immediate effects seen   |

**Example:**

> "We'll add this field to the API response." → "What follows from adding this field?" → "How does
> this affect clients that don't need it?" → "What are the implications for backward compatibility?"

## 6. Questions About the Question

**Purpose:** Reflect on the inquiry itself; meta-level examination.

| Question                             | Use When                   |
| ------------------------------------ | -------------------------- |
| "Why is this question important?"    | Purpose unclear            |
| "What would answering this tell us?" | Value of question unclear  |
| "Is this the right question?"        | May be missing the point   |
| "What question should we be asking?" | Reframing needed           |
| "Why are we asking this now?"        | Timing or priority unclear |

**Example:**

> "Which database should we use?" → "Why is this question important right now?" → "What would
> answering this tell us that we don't know?" → "Is the real question about database, or about data
> modeling?"
