#!/usr/bin/env node

export interface ProviderProfile {
  provider: 'AWS' | 'Azure';
  cost: number;
  latency: number;
  load: number;
  capacity: number;
  reliability: number;
}

export interface HybridExecutorConfig {
  AWS_ESTIMATED_COST?: string;
  AWS_ESTIMATED_LATENCY_MS?: string;
  AWS_CURRENT_LOAD?: string;
  AZURE_ESTIMATED_COST?: string;
  AZURE_ESTIMATED_LATENCY_MS?: string;
  AZURE_CURRENT_LOAD?: string;
}

export function getProviderCatalog(env: HybridExecutorConfig = {}): ProviderProfile[] {
  return [
    {
      provider: 'AWS',
      cost: Number(env.AWS_ESTIMATED_COST ?? '0.0000167'),
      latency: Number(env.AWS_ESTIMATED_LATENCY_MS ?? '45'),
      load: Number(env.AWS_CURRENT_LOAD ?? '0.7'),
      capacity: 1000,
      reliability: 0.99,
    },
    {
      provider: 'Azure',
      cost: Number(env.AZURE_ESTIMATED_COST ?? '0.00002'),
      latency: Number(env.AZURE_ESTIMATED_LATENCY_MS ?? '60'),
      load: Number(env.AZURE_CURRENT_LOAD ?? '0.5'),
      capacity: 500,
      reliability: 0.985,
    },
  ];
}

export function selectProvider(
  providers: ProviderProfile[],
  preferredProvider: 'auto' | 'AWS' | 'Azure' = 'auto',
  routingStrategy: 'cost' | 'latency' | 'load' = 'cost',
): ProviderProfile {
  if (preferredProvider !== 'auto') {
    return providers.find((provider) => provider.provider === preferredProvider) ?? providers[0];
  }

  switch (routingStrategy) {
    case 'latency':
      return [...providers].sort((a, b) => a.latency - b.latency)[0];
    case 'load':
      return [...providers].sort((a, b) => a.load / a.capacity - b.load / b.capacity)[0];
    default:
      return [...providers].sort((a, b) => a.cost - b.cost)[0];
  }
}

export function getProviderOrder(selected: ProviderProfile): Array<'AWS' | 'Azure'> {
  return selected.provider === 'AWS' ? ['AWS', 'Azure'] : ['Azure', 'AWS'];
}

if (process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href) {
  const providers = getProviderCatalog(process.env as HybridExecutorConfig);
  const selected = selectProvider(providers, 'auto', 'cost');
  console.log(JSON.stringify({ selectedProvider: selected.provider, providers }, null, 2));
}
