import { createLogger, format, transports } from 'winston';
import { join } from 'path';

const LOG_DIR = join(process.cwd(), 'logs');

export const logger = createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: format.combine(
    format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    format.errors({ stack: true }),
    format.splat(),
    format.json(),
  ),
  defaultMeta: { service: 'gentle-vanguard-bot' },
  transports: [
    // Console output
    new transports.Console({
      format: format.combine(
        format.colorize(),
        format.printf(({ level, message, timestamp, ...metadata }) => {
          let msg = `${timestamp} [${level}] : ${message}`;
          if (Object.keys(metadata).length > 0) {
            msg += ` ${JSON.stringify(metadata)}`;
          }
          return msg;
        }),
      ),
    }),
    // File output
    new transports.File({
      filename: join(LOG_DIR, 'error.log'),
      level: 'error',
    }),
    new transports.File({
      filename: join(LOG_DIR, 'combined.log'),
    }),
  ],
});
