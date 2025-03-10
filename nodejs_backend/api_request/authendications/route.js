import express from "express";
import validator from "../../validations/middleware.js";
import SignUpValidation from "../../validations/SignupValidation.js"; 
import LoginValidation from "../../validations/LoginValidation.js"; 

import db from "./../../db.js"; 
import Login from "./login.js"; 
import SignUp from "./signup.js";
import Logout from "./logout.js"; 
import { logger, logger_all } from "../../logger.js";
import request_id_check from "../../validations/valid_user_middleware_reqID.js";

const router = express.Router();

router.post(
  "/",
  validator.body(LoginValidation),
  async (req, res, next) => {
    try {

      var result = await Login.login(req);
      result['request_id'] = req.body.request_id;

      logger.info("[API RESPONSE] " + JSON.stringify(result))

      if (result.response_code == 0) {
        await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP,response_comments = '${result.response_msg}' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
      }
      else {
        await db.query(`UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP,response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
      }
      res.json(result);
    }
    catch (err) {
      console.error(`Error while processing login request:`, err.message);
      next(err);
    }
  }
);

router.post(
  "/logout",
  request_id_check,
  // validator.body(LoginValidation),
  async (req, res, next) => {
    try {
      const result = await Logout.logout(req);
      result['request_id'] = req.body.request_id;

      logger.info("[API RESPONSE] " + JSON.stringify(result))

      if (result.response_code == 0) {
        await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP,response_comments = '${result.response_msg}' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
      }
      else {
        await db.query(`UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP,response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
      }
      res.json(result);
    } catch (err) {
      console.error(`Error while processing login request:`, err.message);
      next(err);
    }
  }
);


router.post(
  "/signup",
  validator.body(SignUpValidation),
  async (req, res, next) => {
    try {

      var result = await SignUp.SignUp(req);
      result['request_id'] = req.body.request_id;

      logger.info("[API RESPONSE] " + JSON.stringify(result))

      if (result.response_code == 0) {
        await db.query(`UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP,response_comments = '${result.response_msg}' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
      }
      else {
        await db.query(`UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP,response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`);
      }
      res.json(result);
    }
    catch (err) {
      console.error(`Error while processing login request:`, err.message);
      next(err);
    }
  }
);


export default router;