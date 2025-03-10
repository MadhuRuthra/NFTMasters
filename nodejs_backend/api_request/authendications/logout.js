// Import the required modules
import db from "../../db.js";
import dotenv from "dotenv";
import { logger_all } from "../../logger.js";
dotenv.config();

async function logout(req) {
  try {
    const { user_id } = req.body;
    // console.log(user_id +"user_id")

    const logoutRecords = await db.query(
      `SELECT * FROM user_log WHERE user_id = '${user_id}' AND login_date = CURRENT_TIMESTAMP AND user_log_status = 'I'`
    );

    if (logoutRecords.length) {

      await db.query(`UPDATE user_log SET logout_time = CURRENT_TIMESTAMP, user_log_status = 'O' WHERE user_id = '${user_id}' AND login_date = CURRENT_TIMESTAMP AND user_log_status = 'I'`);
      await db.query(`UPDATE users SET token = '-' WHERE id = '${user_id}' AND user_status = 'Y'`);
      
    }

    return { response_code: 1, response_status: 200, response_msg: "Success" };
  } catch (error) {
    logger_all.info(`: [Logout] Failed - ${error}`);
    return { response_code: 0, response_status: 201, response_msg: "Error Occurred." };
  }
}

export default { logout };