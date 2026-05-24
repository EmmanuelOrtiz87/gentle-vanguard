9. **Export PNG**: Use `cairosvg` (recommended). See **SVG → PNG Conversion** section below for full
   method comparison
10. **Report** the generated file paths
11. **(Optional) Visual self-review** — if your runtime can read images, load the exported PNG back
    and inspect it. Syntactic validity does not guarantee visual correctness: arrows may cross
    through component interiors, labels may collide with lifelines or other labels, boxes may
    overlap, alt-frame text may sit on top of a message, or a legend may cover content. If you see
    any of these, revise the SVG and re-export; repeat until the rendered image is clean. Common
    fixes:
    - Route arrows through gaps between boxes, not through box interiors
    - Add background rects behind arrow labels (opacity 0.95, matching canvas color)
    - Widen inter-row/inter-column gutters so same-layer arrows have clear corridors
    - Collapse repeated cross-layer arrows into a single "delegates down" rail outside the content
      area
    - Move legend/notes out of any region where arrows or labels land
    - Increase viewBox height/width rather than packing elements tighter Skip this step silently if
      image reading is unavailable — do not guess.

---

## References

See `references/patterns.md` for detailed patterns and code examples.