/**
 * GV Content OS — CLI de generación (sin levantar servidor).
 *   npx tsx apps/content-cms/server/cli.ts generate "brief..." --platforms linkedin,x --format text_image
 *   npx tsx apps/content-cms/server/cli.ts platforms
 */
import { resolveGenerator, GenerateBrief } from './generator';
import { PLATFORM_SPECS, ContentFormat } from './platform-specs';

const args = process.argv.slice(2);
const command = args[0];
const flag = (name: string): string | undefined => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 ? args[i + 1] : undefined;
};

async function main(): Promise<void> {
  if (command === 'platforms') {
    for (const spec of Object.values(PLATFORM_SPECS)) {
      console.log(
        `${spec.id.padEnd(10)} ${spec.name.padEnd(22)} ${spec.charLimit} chars, img ${spec.imageSize.width}x${spec.imageSize.height}, best ${spec.bestTimes.join('/')}`,
      );
    }
    return;
  }
  if (command === 'generate') {
    const briefText = args[1];
    if (!briefText)
      throw new Error(
        'usage: generate "<brief>" --platforms linkedin,x [--format text_image] [--title t] [--objective o]',
      );
    const brief: GenerateBrief = {
      title: flag('title') ?? briefText.slice(0, 60),
      brief: briefText,
      objective: flag('objective') ?? '',
      voice: flag('voice') ?? '',
      platforms: (flag('platforms') ?? 'linkedin').split(',').filter((p) => PLATFORM_SPECS[p]),
      format: (flag('format') as ContentFormat) ?? 'text',
    };
    const generator = resolveGenerator(flag('provider'));
    console.error(
      `[content-os] provider=${generator.provider} platforms=${brief.platforms.join(',')}`,
    );
    const variants = await generator.generate(brief);
    for (const v of variants) {
      console.log(`\n=== ${v.platform} (${v.format}, score=${v.score ?? '—'}) ===`);
      console.log(v.body);
      if (v.imagePrompt) console.log(`[image] ${v.imagePrompt}`);
    }
    return;
  }
  throw new Error('comandos: generate | platforms');
}

main().catch((err) => {
  console.error(`[content-os] ERROR: ${(err as Error).message}`);
  process.exit(1);
});
