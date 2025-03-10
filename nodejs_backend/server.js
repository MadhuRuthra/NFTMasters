process.env.TZ = 'Asia/Kolkata';
import express from "express";
import cors from "cors";
import dotenv from "dotenv";
// import db from "./db.js"; // Ensure db.js also uses ES module syntax
import loginRoutes from "./api_request/authendications/route.js";
import { logger_all } from "./logger.js";
import loggerMiddleware from "./loggerMiddleware.js";

dotenv.config(); // Load environment variables

const app = express(); // Initialize Express

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cors());
app.use(loggerMiddleware);

// Use login route
app.use("/login", loginRoutes); // Calls login routes


app.get("/", (req, res) => {
  res.json({ message: "ok" });
});


// // Test route
// app.get("/", (req, res) => {
//   res.send("Welcome to Node.js with MySQL!");
// });

// Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  logger_all.info(`Server is running on port ${PORT}`);
});