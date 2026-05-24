---
name: ui-mobile
description: Mobile UI patterns - React Native, iOS/Android, touch targets
when-to-use: When building mobile UI components
user-invocable: false
paths: ['**/*.tsx', '**/*.jsx', 'ios/**', 'android/**', '**/*.dart']
effort: medium
---

# Mobile UI Design Skill (React Native)

---

## MANDATORY: Mobile Accessibility Standards

**These rules are NON-NEGOTIABLE. Every UI element must pass these checks.**

### 1. Touch Targets (CRITICAL)

```typescript
// MINIMUM 44x44 points for ALL interactive elements
const MINIMUM_TOUCH_SIZE = 44;

// EVERY button, link, icon button must meet this
const styles = StyleSheet.create({
  button: {
    minHeight: MINIMUM_TOUCH_SIZE,
    minWidth: MINIMUM_TOUCH_SIZE,
    paddingVertical: 12,
    paddingHorizontal: 16,
  },
  iconButton: {
    width: MINIMUM_TOUCH_SIZE,
    height: MINIMUM_TOUCH_SIZE,
    justifyContent: 'center',
    alignItems: 'center',
  },
});

// NEVER DO THIS:
style={{ height: 30 }}  //  TOO SMALL
style={{ padding: 4 }}  //  RESULTS IN TINY TARGET
```

### 2. Color Contrast (CRITICAL)

```typescript
// WCAG 2.1 AA: 4.5:1 for text, 3:1 for large text/UI

// SAFE COMBINATIONS:
const colors = {
  // Light mode
  textPrimary: '#000000', // on white = 21:1
  textSecondary: '#374151', // gray-700 on white = 9.2:1

  // Dark mode
  textPrimaryDark: '#FFFFFF', // on gray-900 = 16:1
  textSecondaryDark: '#E5E7EB', // gray-200 on gray-900 = 11:1
};

// FORBIDDEN - FAILS CONTRAST:
//  '#9CA3AF' (gray-400) on white = 2.6:1
//  '#6B7280' (gray-500) on '#111827' = 4.0:1
//  Any text below 4.5:1 ratio
```

### 3. Visibility Rules

```typescript
// ALL BUTTONS MUST HAVE visible boundaries

// PRIMARY: Solid background with contrasting text
<Pressable style={styles.primaryButton}>
  <Text style={{ color: '#FFFFFF' }}>Submit</Text>
</Pressable>

const styles = StyleSheet.create({
  primaryButton: {
    backgroundColor: '#1F2937', // gray-800
    paddingVertical: 16,
    paddingHorizontal: 24,
    borderRadius: 12,
    minHeight: 44,
  },
});

// SECONDARY: Visible background
<Pressable style={styles.secondaryButton}>
  <Text style={{ color: '#1F2937' }}>Cancel</Text>
</Pressable>

const styles = StyleSheet.create({
  secondaryButton: {
    backgroundColor: '#F3F4F6', // gray-100
    minHeight: 44,
  },
});

// GHOST: MUST have visible border
<Pressable style={styles.ghostButton}>
  <Text style={{ color: '#374151' }}>Skip</Text>
</Pressable>

const styles = StyleSheet.create({
  ghostButton: {
    borderWidth: 1,
    borderColor: '#D1D5DB', // gray-300
    minHeight: 44,

---

> **Referencia detallada**: [eferences/detail.md](references/detail.md)