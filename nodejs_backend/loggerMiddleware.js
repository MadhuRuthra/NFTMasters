import { logger,logger_all } from "./logger.js";
const loggerMiddleware = (req, res, next) => {
    // Log the incoming request data
    logger_all.info(`Request received: ${req.method} ${req.url} - Request Body: ${JSON.stringify(req.body)} - Request Params: ${JSON.stringify(req.params)} - Request Query: ${JSON.stringify(req.query)} - Request Headers: ${JSON.stringify(req.headers)}`);
    logger.info(`Request received: ${req.method} ${req.url} - Request Body: ${JSON.stringify(req.body)} - Request Params: ${JSON.stringify(req.params)} - Request Query: ${JSON.stringify(req.query)} - Request Headers: ${JSON.stringify(req.headers)}`);
  
    // Store the original `send` function so we can override it
    const originalSend = res.send;
  
    res.send = function (body) {
      // Log the response data before sending it
      logger_all.info(`Response for ${req.method} ${req.url}: ${body}`);
      logger.info(`Response for ${req.method} ${req.url}: ${body}`);

      return originalSend.call(this, body);
    };
  
    // Pass control to the next middleware/route handler
    next();
  };
  
  export default loggerMiddleware;