import winston from 'winston';
import DailyRotateFile from 'winston-daily-rotate-file';
import config from './config/default.js';
import configAll from './config/allLog.js';

// Create the log format
const logFormat = winston.format.combine(
  winston.format.timestamp({
    format: 'DD-MM-YYYY HH:mm:ss',
  }),
  winston.format.printf(
    (info) => `${info.timestamp} ${info.level}: ${info.message}`
  )
);

// Create transports for daily rotating files
const transport = new DailyRotateFile({
  filename: `${config.logConfig.logFolder}${config.logConfig.logFile}`,
  datePattern: 'YYYY-MM-DD',
  maxSize: '20m',
});

const transportAll = new DailyRotateFile({
  filename: `${configAll.logConfig.logFolder}${configAll.logConfig.logFile}`,
  datePattern: 'YYYY-MM-DD',
  maxSize: '20m',
});

// Create loggers
const logger = winston.createLogger({
  format: logFormat,
  transports: [
    transport,
    new winston.transports.Console({
      level: 'info',
    }),
  ],
});

const logger_all = winston.createLogger({
  format: logFormat,
  transports: [
    transportAll,
    new winston.transports.Console({
      level: 'info',
    }),
  ],
});

export { logger, logger_all };