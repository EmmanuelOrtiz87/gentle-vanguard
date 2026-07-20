# Rollback Plan Template

Copy this template and fill it in before every deployment.

```markdown
## Rollback Plan for [Feature/Release]

### Trigger Conditions

- Error rate > 2x baseline
- P95 latency > [X]ms
- User reports of [specific issue]

### Rollback Steps

1. Disable feature flag (if applicable) OR
1. Deploy previous version: `git revert <commit> && git push`
1. Verify rollback: health check, error monitoring
1. Communicate: notify team of rollback

### Database Considerations

- Migration [X] has a rollback: `npx prisma migrate rollback`
- Data inserted by new feature: [preserved / cleaned up]

### Time to Rollback

- Feature flag: < 1 minute
- Redeploy previous version: < 5 minutes
- Database rollback: < 15 minutes
```

## Key Principles

- **Every deployment needs a rollback plan before it happens**
- Document trigger conditions explicitly
- Include database migration rollback steps
- Estimate time to rollback for each strategy
- Test the rollback mechanism (dry run) during post-launch verification
