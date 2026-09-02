# Cleanup Guide - Obsolete Design Apps

> **Last Updated**: 2026-09-01  
> **Purpose**: Remove obsolete design apps after Design Hub migration  
> **Status**: Ready for execution

---

## 📋 Pre-Cleanup Checklist

Before running cleanup, verify:

- [ ] Design Hub is working correctly
- [ ] Run: `cd apps/design-hub && npm run status`
- [ ] Should show: `✅ Design Hub is operational`
- [ ] URL accessible: http://127.0.0.1:8095
- [ ] All needed assets copied to Design Hub
- [ ] No other apps depend on obsolete apps

---

## 🗑️ Apps to Remove

| App                             | Replaced By | Files | Status          |
| ------------------------------- | ----------- | ----- | --------------- |
| `apps/gv-design-studio`         | Design Hub  | ~47   | Ready to delete |
| `apps/gv-design-system-catalog` | Design Hub  | ~5    | Ready to delete |

---

## 🚀 Cleanup Methods

### Method 1: PowerShell Script (Recommended)

```powershell
# Dry run first (shows what will be deleted without deleting)
.\scripts\cleanup-obsolete-apps.ps1 -DryRun

# Actually delete (requires confirmation)
.\scripts\cleanup-obsolete-apps.ps1

# Skip confirmation (dangerous!)
.\scripts\cleanup-obsolete-apps.ps1 -Force
```

### Method 2: Manual Removal

```bash
# From project root
rm -rf apps/gv-design-studio
rm -rf apps/gv-design-system-catalog
```

### Method 3: Git Remove (if using git)

```bash
git rm -rf apps/gv-design-studio
git rm -rf apps/gv-design-system-catalog
git commit -m "chore: remove obsolete design apps, replaced by Design Hub"
```

---

## ✅ Post-Cleanup Verification

After cleanup, verify:

```bash
# 1. Design Hub still works
cd apps/design-hub
npm run status
# Expected: ✅ Design Hub is operational

# 2. Command Center starts without errors
cd ../command-center
npm run dev
# Expected: Server starts, no 404s for /api/apps

# 3. No stale references
grep -r "gv-design-studio" apps/ || echo "✓ No references found"
grep -r "gv-design-system-catalog" apps/ || echo "✓ No references found"
```

---

## 🔄 Rollback (If Needed)

If you deleted by mistake:

```bash
# If using git
git checkout HEAD -- apps/gv-design-studio
git checkout HEAD -- apps/gv-design-system-catalog

# Otherwise: restore from backup
```

---

## 📁 What Was Already Migrated

**From `apps/gv-design-system-catalog/`**:

- ✅ Token display → `Design Hub > Token Editor`
- ✅ Component catalog → `Design Hub > Components`
- ✅ Logo files → `apps/design-hub/public/assets/`

**From `apps/gv-design-studio/`**:

- ✅ Token editing → `Design Hub > Token Editor`
- ✅ Asset generation → `Design Hub > Asset Generator`
- ✅ Visual comparison → `Design Hub > Visual Comparison`

---

## 🎯 Expected Result

After cleanup, the `apps/` directory should contain:

```
apps/
├── academy-web/          ✅ Keep
├── analytics/            ✅ Keep
├── archify/              ✅ Keep
├── command-center/       ✅ Keep
├── content-cms/          ✅ Keep
├── design-hub/            ✅ NEW (replacement)
├── prompt-studio/         ✅ Keep
├── web-dashboard/         ✅ Keep
└── (no gv-design-studio)  ✅ REMOVED
└── (no gv-design-system-catalog) ✅ REMOVED
```

---

## ⚠️ Important Notes

1. **DO NOT** delete if Design Hub is not working
2. **KEEP** deprecation files (`DEPRECATED.md`) until full migration verified
3. **BACKUP** first if unsure
4. **TEST** Command Center after cleanup
5. **VERIFY** no CI/CD pipelines reference obsolete apps

---

## 📞 Support

If something breaks:

1. Check Design Hub status: `npm run status`
2. Restart Command Center
3. Restore from backup if needed
4. Check logs: `.runtime/`

---

**Ready to cleanup?** Run the PowerShell script above or execute manually.

**Last verification**: 2026-09-01  
**Design Hub status**: ✅ Operational
