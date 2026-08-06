---
name: image-generation-skill
description: >
  AI Image Generation — generates images natively via DALL-E, Stable Diffusion, or ComfyUI. Trigger:
  "generate image", "create image", "AI art", "DALL-E", "Stable Diffusion", "FLUX", "visual asset",
  "banner", "logo", "illustration", "image generation".
metadata:
  source: GV-native
---

## When to Use

- Generating visual assets (logos, banners, icons, illustrations)
- Creating AI art for presentations, documentation, or UI mockups
- Generating images programmatically for dashboards or reports
- Batch image generation for social media or marketing
- Fallback SVG generation when AI APIs are unavailable

## Architecture

```
User Request
  ↓
image-gen.ts (CLI / API client)
  ├── Provider: DALL-E 3 (OpenAI API)
  ├── Provider: Stable Diffusion (Replicate / StabilityAI)
  ├── Provider: FLUX.1 (Replicate)
  └── Fallback: SVG template engine (offline)
        ↓
  Output: PNG / SVG / JPEG file
```

## Usage

```bash
# Generate image via DALL-E 3
npx tsx src/cli/image-gen.ts "a futuristic dashboard interface" --provider dall-e --output dashboard-concept.png

# Generate via Stable Diffusion
npx tsx src/cli/image-gen.ts "cyberpunk city at night" --provider stability --style cinematic --output city.png

# Generate via FLUX (Replicate)
npx tsx src/cli/image-gen.ts "abstract geometric pattern" --provider flux --output pattern.png

# Batch generation from JSON config
npx tsx src/cli/image-gen.ts --config config/image-batch.json --output-dir assets/generated/

# Offline SVG fallback (no API key needed)
npx tsx src/cli/image-gen.ts "Gentle-Vanguard hero banner" --provider svg --banner hero --brand config/brand.json
```

## Output Formats

| Flag           | Format | Description                       |
| -------------- | ------ | --------------------------------- |
| `--output`     | auto   | Auto-detect from extension        |
| `--format png` | PNG    | Raster (default for AI APIs)      |
| `--format svg` | SVG    | Vector (only with --provider svg) |
| `--format jpg` | JPEG   | Compressed raster                 |

## Providers

### DALL-E 3 (OpenAI)

- **Quality**: Best for photorealistic, complex scenes
- **Cost**: ~$0.040/image (standard), ~$0.080/image (HD)
- **Size**: 1024x1024, 1792x1024, 1024x1792
- **Config**: `OPENAI_API_KEY` env var

### Stable Diffusion (StabilityAI / Replicate)

- **Quality**: Good for artistic, stylized, creative
- **Cost**: ~$0.005-0.010/image (Replicate)
- **Sizes**: 512x512, 768x768, 1024x1024
- **Config**: `REPLICATE_API_TOKEN` or `STABILITY_API_KEY` env var

### FLUX.1 (Replicate)

- **Quality**: Excellent for photorealistic, fast
- **Cost**: ~$0.003-0.005/image
- **Sizes**: 1024x1024
- **Config**: `REPLICATE_API_TOKEN` env var

### SVG Fallback (Offline)

- **Zero cost**, no API key needed
- Uses `config/brand.json` for theming
- Templates: hero, feature, diagram, icon, avatar

## Configuration

Create `config/image-gen.json`:

```json
{
  "defaultProvider": "svg",
  "providers": {
    "dall-e": {
      "model": "dall-e-3",
      "quality": "standard",
      "size": "1024x1024"
    },
    "stability": {
      "model": "stable-diffusion-xl-1024-v1-0",
      "style": "cinematic",
      "steps": 30
    },
    "flux": {
      "model": "flux-1.1-pro",
      "steps": 25
    }
  },
  "svgTemplate": {
    "colors": { "$ref": "config/brand.json#/colors" },
    "defaultBanner": "hero"
  },
  "outputDir": "assets/generated/"
}
```

## Integration with Stack

- **svc-generator.ts**: For pure SVG assets (logos, banners) — zero dependencies
- **image-gen.ts**: For AI-generated images — requires API keys
- **Dashboard**: Generated images can be served from `assets/generated/`

## Error Handling

- API failures → retry with exponential backoff (3 attempts)
- All providers fail → fallback to SVG template
- Missing API key → clear error with config instructions
- Rate limits → queued batch processing
