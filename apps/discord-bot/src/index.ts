import { Client, GatewayIntentBits, Events, Collection } from 'discord.js';
import { config } from 'dotenv';
import { logger } from './utils/logger';
import { loadCommands } from './commands';
import { loadEvents } from './events';

// Load environment variables
config();

const TOKEN = process.env.DISCORD_TOKEN;
const CLIENT_ID = process.env.DISCORD_CLIENT_ID;
const GUILD_ID = process.env.DISCORD_GUILD_ID;

if (!TOKEN || !CLIENT_ID) {
  logger.error('Missing required environment variables');
  process.exit(1);
}

// Create client
const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent,
    GatewayIntentBits.GuildMembers,
    GatewayIntentBits.GuildMessageReactions,
  ],
});

// Store commands
client.commands = new Collection();

// Initialize bot
async function init() {
  try {
    // Load commands
    await loadCommands(client);
    logger.info('Commands loaded');

    // Load events
    await loadEvents(client);
    logger.info('Events loaded');

    // Login
    await client.login(TOKEN);
    logger.info('Bot logged in successfully');
  } catch (error) {
    logger.error('Failed to initialize bot:', error);
    process.exit(1);
  }
}

// Handle process errors
process.on('unhandledRejection', (error) => {
  logger.error('Unhandled rejection:', error);
});

process.on('uncaughtException', (error) => {
  logger.error('Uncaught exception:', error);
  process.exit(1);
});

// Start
init();

export { client };
