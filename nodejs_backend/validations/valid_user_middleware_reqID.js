import db from "../db.js";
import jwt from "jsonwebtoken";
import { logger, logger_all } from "../logger.js";


const VerifyUser = async (req, res, next) => {

    let request_id = req.body.request_id;

    try {
        // Get the IP address from headers or connection
        const header_json = req.headers;
        const ip_address = header_json['x-forwarded-for'] || 'NULL';

        logger_all.info("Verify user");
        logger_all.info("Request ID: " + request_id);
        logger.info(
            `[API REQUEST] ${req.originalUrl} - ${JSON.stringify(req.body)} - ${JSON.stringify(req.headers)} - ${ip_address}`
        );

        let user_id;
        const bearerHeader = req.headers["authorization"];
        let parameters = bearerHeader ? `,'${bearerHeader}'` : `,null`;
        parameters += req.body.user_id ? `,${req.body.user_id}` : `,null`;

        // Call stored procedure
        let update_api_log_result = await db.query(`CALL update_api_log(?, ?, ? ${parameters})`, [req.originalUrl, ip_address, request_id]
        );

        user_id = update_api_log_result[0][0][0].response_user_id;

        if (update_api_log_result[0][0][0].Success) {
            try {
                if (bearerHeader && bearerHeader.startsWith("Bearer ")) {
                    let user_bearer_token = bearerHeader.split("Bearer ")[1];
                    jwt.verify(user_bearer_token, process.env.ACCESS_TOKEN_SECRET);
                } else {
                    throw new Error("Invalid authorization header");
                }

                req.body.user_id = user_id;
                next();
            } catch (e) {
                logger_all.info("[Validate user error]: " + e.message);

                await db.query(
                    `UPDATE user_log SET user_log_status = 'O', logout_time = CURRENT_TIMESTAMP WHERE user_id = ?`,
                    [user_id]
                );

                await db.query(
                    `UPDATE api_log SET response_status = 'F', response_date = CURRENT_TIMESTAMP, response_comments = 'Token expired' WHERE request_id = ? AND response_status = 'N'`,
                    [request_id]
                );

                let response_json = {
                    request_id: request_id,
                    response_code: 0,
                    response_status: 403,
                    response_msg: "Token expired",
                };

                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json));
                return res.status(403).send(response_json);
            }
        } else if (update_api_log_result[0][0].Status) {
            let response_json = {
                request_id: request_id,
                response_code: 0,
                response_status: 201,
                response_msg: update_api_log_result[0][0].response_msg,
            };

            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json));
            return res.status(201).send(response_json);
        } else {
            let response_json = {
                request_id: request_id,
                response_code: 0,
                response_status: 403,
                response_msg: update_api_log_result[0][0].response_msg,
            };

            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json));
            return res.status(403).send(response_json);
        }
    } catch (e) {
        logger_all.info("[Validate user error]: " + e.message);

        await db.query(
            `UPDATE api_log SET response_status = 'F', response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = ? AND response_status = 'N'`,
            [request_id]
        );

        let response_json = {
            request_id: request_id,
            response_code: 0,
            response_status: 201,
            response_msg: "Error occurred",
        };

        logger_all.info("[API RESPONSE] " + JSON.stringify(response_json));
        logger.info("[API RESPONSE] " + JSON.stringify(response_json));

        return res.json(response_json);
    }
};

export default VerifyUser;