// Import the required modules
import db from "../../db.js";
import jwt from "jsonwebtoken";
import md5 from "md5";
import dotenv from "dotenv";
import { logger, logger_all } from "../../logger.js";
dotenv.config();

// Login Function
async function login(req) {

  // Extract request data
  const { email, password, request_id } = req.body;
  const hashed_password = md5(password);
  const ip_address = req.headers["x-forwarded-for"];

  logger_all.info("process.env.ACCESS_TOKEN_SECRET" + process.env.ACCESS_TOKEN_SECRET);

  // Generate JWT Token
  const user = {
    username: email,
    user_password: password,
  };

  const accessToken = jwt.sign(user, process.env.ACCESS_TOKEN_SECRET, {
    expiresIn: process.env.ONEWEEK,
  });

  const user_bearer_token = `Bearer ${accessToken}`;

  try {

    const header_json = req.headers;
    const ip_address = header_json['x-forwarded-for'];
  
    logger.info("[API REQUEST] " + req.originalUrl + " - " + JSON.stringify(req.body) + " - " + JSON.stringify(req.headers) + " - " + ip_address);
  
  
     await db.query(
        `INSERT INTO api_log VALUES(NULL, 0, '${req.originalUrl}', '${ip_address}', '${request_id}', 'N', '-', '0000-00-00 00:00:00', 'Y', CURRENT_TIMESTAMP)`
      );
    // console.log(`CALL LoginProcedure('${user_email}', '${hashed_password}', '${request_id}','${user_bearer_token}','${ip_address}','${req.originalUrl}')`)
    const results = await db.query(`CALL LoginProcedure('${email}', '${hashed_password}', '${request_id}','${user_bearer_token}','${ip_address}','${req.originalUrl}')`);


    if (results?.length > 0) {
      const {
        response_msg,
        user_id,
        user_master_id,
        parent_id,
        user_email,
        user_status,
        user_theme,
        user_view,
        api_key,
      } = results[0][0][0];

      return {
        response_code: 1,
        response_status: 200,
        num_of_rows: 1,
        response_msg,
        user_bearer_token,
        user_id,
        user_master_id,
        parent_id,
        user_email,
        user_status,
        user_theme,
        user_view,
        api_key,
      };
    } else {
      logger_all.info(": [Login] Failed - Error occurred.");

      return {
        response_code: 0,
        response_status: 201,
        response_msg: "Error occurred.",
      };
    }
  } catch (err) {
    logger_all.info(`: [Login] Failed - ${err.message}`);
    return {
      response_code: 0,
      response_status: 201,
      response_msg: err.message,
    };
  }
};

export default { login };