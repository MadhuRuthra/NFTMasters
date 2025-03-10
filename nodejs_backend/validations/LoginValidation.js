/**
 * It is used for user input validation.
 * LoginSchema function to validate the user.
 *
 * Version : 1.0
 * Author : Madhubala (YJ0009)
 * Date : 05-Jul-2023
 */

import Joi from "@hapi/joi";

// Define the LoginSchema object
const LoginSchema = Joi.object({
  request_id: Joi.string().required().label("Request ID"),
  email: Joi.string().required().label("Email"),
  password: Joi.string().required().label("Password"),
}).options({ abortEarly: false });

// Export the LoginSchema module
export default LoginSchema;
