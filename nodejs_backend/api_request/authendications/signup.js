// Import the required modules
import db from "../../db.js";
import md5 from "md5";
import dotenv from "dotenv";
import { logger, logger_all } from "../../logger.js";
dotenv.config();

// SignUp Function
async function SignUp(req) {

  // Extract request data
  const { user_name,email, password, request_id } = req.body;


  try {

    const header_json = req.headers;
    const ip_address = header_json['x-forwarded-for'];
  
    logger.info("[API REQUEST] " + req.originalUrl + " - " + JSON.stringify(req.body) + " - " + JSON.stringify(req.headers) + " - " + ip_address);
  
  
     await db.query(
        `INSERT INTO api_log VALUES(NULL, 0, '${req.originalUrl}', '${ip_address}', '${request_id}', 'N', '-', '0000-00-00 00:00:00', 'Y', CURRENT_TIMESTAMP)`
      );

    const results = await db.query(`CALL SignUpProcedure('${user_name}', '${email}', '${md5(password)}')`);


    if (results?.length > 0) {
      const {
        response_msg
      } = results[0][0][0];

      return {
        response_code: 1,
        response_status: 200,
        response_msg,
      };
    } else {
      logger_all.info(": [SignUp] Failed - Error occurred.");

      return {
        response_code: 0,
        response_status: 201,
        response_msg: "Error occurred.",
      };
    }
  } catch (err) {
    logger_all.info(`: [SignUp] Failed - ${err.message}`);
    return {
      response_code: 0,
      response_status: 201,
      response_msg: err.message,
    };
  }
};

export default { SignUp };