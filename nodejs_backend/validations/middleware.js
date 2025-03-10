import { logger, logger_all } from "../logger.js";

const validator = {
  body: (schema) => (req, res, next) => {
    logger_all.info(req.body);
    const { error } = schema.validate(req.body);
    if (error) {
      // Create an array of error messages from the validation error details.
      const error_array = error.details.map(detail => detail.message);
      logger_all.info(error_array);
      return res.status(200).send({
        response_code: 0,
        response_status: 201,
        response_msg: "Error occurred",
        data: error_array
      });
    }
    next();
  }
};

export default validator;
