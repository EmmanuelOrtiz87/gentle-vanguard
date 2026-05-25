}, });

// NEVER CREATE invisible buttons: // backgroundColor: 'transparent' without border // Text color
matching background

````

### 4. Accessibility Labels (REQUIRED)

```tsx
// EVERY interactive element needs accessibility props

// Buttons
<Pressable
  accessible={true}
  accessibilityRole="button"
  accessibilityLabel="Submit form"
  accessibilityHint="Double tap to submit your information"
>
  <Text>Submit</Text>
</Pressable>

// Icon buttons (NO visible text = MUST have label)
<Pressable
  accessible={true}
  accessibilityRole="button"
  accessibilityLabel="Close menu"
>
  <CloseIcon />
</Pressable>

// Images
<Image
  accessible={true}
  accessibilityRole="image"
  accessibilityLabel="User profile photo"
  source={...}
/>
````

### 5. Focus/Selection States

```tsx
// EVERY Pressable needs visible pressed state
<Pressable style={({ pressed }) => [styles.button, pressed && styles.buttonPressed]}>
  {children}
</Pressable>;

const styles = StyleSheet.create({
  button: {
    backgroundColor: '#1F2937',
  },
  buttonPressed: {
    opacity: 0.7,
    // OR
    backgroundColor: '#374151',
  },
});
```

---

---

## References

See `references/patterns.md` for: platform differences, component patterns, color tokens, navigation
patterns, and accessibility patterns.
