# API Key Rotation Procedure

## When to Rotate
- If an API key is ever committed to version control (even if later removed)
- If a key is suspected to be leaked or exposed
- On a regular schedule (e.g., every 90 days)

## Steps
1. **Generate a new API key** in the provider's dashboard (e.g., OpenAI, AWS, etc.).
2. **Update `.env.local`** with the new key:
   - Replace the old value for `agent_custom_apikey` with the new key.
3. **Restart all services** that use the key to ensure they load the new value.
4. **Revoke the old API key** in the provider's dashboard.
5. **Document the rotation** in the CHANGELOG or a security log.
6. **Notify team members** if manual action is required on their environments.

## Example
```
# .env.local
agent_custom_apikey=sk-prod-NEWKEYHERE
```

## Security Note
- Never commit `.env.local` or any secrets to version control.
- Always verify `.env.local` is in `.gitignore`.
- Rotate keys immediately if exposure is detected.
