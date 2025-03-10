-- phpMyAdmin SQL Dump
-- version 5.2.2-dev+20241129.61b4f6739ddeb1
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Mar 03, 2025 at 10:56 AM
-- Server version: 8.0.33
-- PHP Version: 8.2.24

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `nft_art`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`admin`@`localhost` PROCEDURE `LoginProcedure` (IN `p_txt_username` VARCHAR(255), IN `p_txt_password` VARCHAR(255), IN `p_request_id` VARCHAR(255), IN `p_bearer_token` VARCHAR(255), IN `p_ip_address` VARCHAR(255), IN `p_request_url` VARCHAR(255))   BEGIN
    
    DECLARE today_date DATE DEFAULT CURDATE();
    DECLARE crnt_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE user_id_check INT;
    DECLARE check_email VARCHAR(255);
    DECLARE usr_name VARCHAR(255);
    DECLARE usr_status VARCHAR(25);
    DECLARE check_password VARCHAR(255);
    DECLARE check_req_id INT DEFAULT 0;
    DECLARE log_exists INT DEFAULT 0;
    DECLARE entry_date DATETIME;
    DECLARE apikey VARCHAR(255);

    
    INSERT INTO api_log 
    VALUES (NULL, 0, p_request_url, p_ip_address, p_request_id, 'N', '-', 
            '0000-00-00 00:00:00', 'Y', crnt_date);

    
    SELECT COUNT(*) INTO check_req_id 
    FROM api_log 
    WHERE request_id = p_request_id 
      AND response_status != 'N' 
      AND api_log_status = 'Y';

    IF (check_req_id > 0) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Request already processed';
    ELSE
        
            SELECT id, email, usr_password, user_name, user_status, created_at, api_key
        INTO user_id_check, check_email, check_password, usr_name, usr_status, entry_date, apikey
        FROM users 
        WHERE email = p_txt_username 
          AND usr_password = p_txt_password 
          AND user_status IN ('N', 'R', 'Y') 
        LIMIT 1;

        -- If user does not exist
        IF user_id_check IS NULL THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Invalid credentials. Please try again!';
        ELSE
            -- Update bearer token for the user
            UPDATE users 
            SET token = p_bearer_token 
            WHERE id = user_id_check;

            -- Check if user log already exists for today
            SELECT COUNT(*) INTO log_exists 
            FROM user_log 
            WHERE user_id = user_id_check 
              AND user_log_status = 'I' 
              AND DATE(login_date) = today_date;

            -- Insert or update user log
            IF log_exists = 0 THEN
                INSERT INTO user_log (user_id, ip_address, login_date, login_time, user_log_status, user_log_entry_date)
                VALUES (user_id_check, p_ip_address, crnt_date, crnt_date, 'I', crnt_date);
            ELSE
                UPDATE user_log 
                SET user_log_status = 'O', logout_time = crnt_date 
                WHERE user_id = user_id_check 
                  AND user_log_status = 'I' 
                  AND DATE(login_date) = today_date;

                INSERT INTO user_log (user_id, ip_address, login_date, login_time, user_log_status, user_log_entry_date)
                VALUES (user_id_check, p_ip_address, crnt_date, crnt_date, 'I', crnt_date);
            END IF;

            -- Return response
            SELECT 'Success' AS response_msg, 
                   p_bearer_token AS bearer_token, 
                   user_id_check AS user_id, 
                   check_email AS user_email, 
                   check_password AS user_password, 
                   usr_name AS user_name, 
                   usr_status AS user_status,
                   entry_date AS created_at,
                   apikey AS api_key;
        END IF;
    END IF;
END$$

CREATE DEFINER=`admin`@`localhost` PROCEDURE `SignUpProcedure` (IN `p_user_name` VARCHAR(255), IN `p_user_email` VARCHAR(255), IN `p_login_password` VARCHAR(255))   BEGIN
    DECLARE apikey VARCHAR(20);
    DECLARE user_exists INT;

    -- Check if the email already exists
    SELECT COUNT(*) INTO user_exists FROM users WHERE email = p_user_email;

    IF user_exists > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email already in use. Please choose different credentials.';
    ELSE
        -- Generate a random API key (20 characters)
        SET apikey = SUBSTRING(MD5(RAND()), 1, 20);

        -- Insert user data into users table
        INSERT INTO users (user_name, email, usr_password, created_at, token, user_status, api_key)
        VALUES (p_user_name, p_user_email, p_login_password, CURRENT_TIMESTAMP, '-', 'Y', apikey);

        -- Return a success response
        SELECT 1 AS response_code, 200 AS response_status, 
               1 AS num_of_rows, 'Success' AS response_msg;
    END IF;
END$$

CREATE DEFINER=`admin`@`localhost` PROCEDURE `update_api_log` (IN `in_originalUrl` VARCHAR(255), IN `ip_address` VARCHAR(255), IN `in_request_id` VARCHAR(255), IN `bearerHeader` VARCHAR(255), IN `in_user_id` INT)  NO SQL BEGIN
    DECLARE Error_message VARCHAR(255);

    BEGIN
        DECLARE error_msg TEXT;
        GET DIAGNOSTICS CONDITION 1 error_msg = MESSAGE_TEXT;

        
        IF POSITION('fatal' IN error_msg) > 0 THEN
            ROLLBACK;
        END IF;

        
    END;

    START TRANSACTION; 

    
    INSERT INTO api_log (
        api_log_id, user_id, api_url, ip_address, request_id, response_status, response_comments, api_log_status, api_log_entry_date
    ) VALUES (
        NULL, 00, in_originalUrl, ip_address, in_request_id, 'N', '-', 'Y', CURRENT_TIMESTAMP
    );

    SET @new_api = CONCAT(
        'SELECT COUNT(*) INTO @new_log FROM api_log WHERE request_id = "', in_request_id,
        '" AND response_status != "N" AND api_log_status="Y"'
    );

    PREPARE stmt FROM @new_api;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    IF @new_log != 0 THEN
        UPDATE api_log SET
            response_status = 'F',
            response_date = CURRENT_TIMESTAMP,
            response_comments = 'Request already processed'
        WHERE request_id = in_request_id AND response_status = 'N';

        
        SELECT 'Request already processed' AS response_msg, 'Status' AS Status;
    END IF;

    IF LENGTH(bearerHeader) > 0 THEN
        
        SET @check_bearer = CONCAT(
            'SELECT COALESCE(id) INTO @result_user_id FROM users WHERE token = "',
            bearerHeader, '" AND user_status = "Y"'
        );

        SET Error_message = 'Invalid token';

        IF LENGTH(in_user_id) > 0 THEN
            SET @check_bearer = CONCAT(@check_bearer, ' AND id = ', in_user_id);
            SET Error_message = 'Invalid token or User ID';
        END IF;

        

        PREPARE stmt FROM @check_bearer;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        IF @result_user_id IS NULL THEN
            
            UPDATE api_log SET
                response_status = 'F',
                response_date = CURRENT_TIMESTAMP,
                response_comments = Error_message
            WHERE request_id = in_request_id AND response_status = 'N';

            
            SELECT Error_message AS response_msg, 'Failed' AS Failed;
        ELSE
            UPDATE api_log SET user_id = @result_user_id WHERE request_id = in_request_id AND response_status = 'N';
            SELECT @result_user_id AS response_user_id, 'success' AS Success;
        END IF;
    ELSE
        UPDATE api_log SET
            response_status = 'F',
            response_date = CURRENT_TIMESTAMP,
            response_comments = 'Token is required'
        WHERE request_id = in_request_id AND response_status = 'N';

        
        SELECT 'Token is required' AS response_msg, 'failed' AS Failed;
    END IF;

    COMMIT;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `api_log`
--

CREATE TABLE `api_log` (
  `api_log_id` int NOT NULL,
  `user_id` int NOT NULL,
  `api_url` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `ip_address` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `request_id` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `response_status` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `response_comments` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `response_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `api_log_status` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `api_log_entry_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `api_log`
--

INSERT INTO `api_log` (`api_log_id`, `user_id`, `api_url`, `ip_address`, `request_id`, `response_status`, `response_comments`, `response_date`, `api_log_status`, `api_log_entry_date`) VALUES
(1, 0, '/login/', '::1', '82784676238', 'F', 'Token is required', '2025-02-28 09:40:38', 'Y', '2025-02-28 09:40:38'),
(2, 0, '/login/', 'undefined', '82784676238', 'F', 'Request already processed', '2025-02-28 09:48:31', 'Y', '2025-02-28 09:45:54'),
(3, 0, '/login/', 'undefined', '82784676238', 'F', 'Request already processed', '2025-02-28 09:48:31', 'Y', '2025-02-28 09:48:31'),
(4, 0, '/login/', 'undefined', '82784676238', 'F', 'Request already processed', '2025-02-28 09:48:31', 'Y', '2025-02-28 09:48:31'),
(5, 0, '/login/', 'undefined', '827846769877868238', 'F', 'Invalid credentials. Please try again!', '2025-02-28 09:50:17', 'Y', '2025-02-28 09:48:40'),
(6, 0, '/login/', 'undefined', '827846769877868238', 'F', 'Invalid credentials. Please try again!', '2025-02-28 09:50:17', 'Y', '2025-02-28 09:48:40'),
(7, 0, '/login/', 'undefined', '827846769877868238', 'F', 'Invalid credentials. Please try again!', '2025-02-28 09:50:17', 'Y', '2025-02-28 09:50:17'),
(8, 0, '/login/', 'undefined', '827846769877868238', 'F', 'Invalid credentials. Please try again!', '2025-02-28 09:50:17', 'Y', '2025-02-28 09:50:17'),
(9, 0, '/login/', 'undefined', '827846769877868238', 'F', 'Request already processed', '2025-02-28 09:51:34', 'Y', '2025-02-28 09:51:34'),
(10, 0, '/login/', 'undefined', '827846769877868238', 'F', 'Request already processed', '2025-02-28 09:51:34', 'Y', '2025-02-28 09:51:34'),
(11, 0, '/login/', 'undefined', '987839', 'F', 'Invalid credentials. Please try again!', '2025-02-28 09:51:40', 'Y', '2025-02-28 09:51:40'),
(12, 0, '/login/', 'undefined', '987839', 'F', 'Invalid credentials. Please try again!', '2025-02-28 09:51:40', 'Y', '2025-02-28 09:51:40'),
(13, 0, '/login/', 'undefined', '987839', 'F', 'Request already processed', '2025-02-28 09:51:57', 'Y', '2025-02-28 09:51:57'),
(14, 0, '/login/', 'undefined', '987839', 'F', 'Request already processed', '2025-02-28 09:51:57', 'Y', '2025-02-28 09:51:57'),
(15, 0, '/login/', 'undefined', '9879839', 'F', 'Invalid credentials. Please try again!', '2025-02-28 09:52:05', 'Y', '2025-02-28 09:52:05'),
(16, 0, '/login/', 'undefined', '9879839', 'F', 'Invalid credentials. Please try again!', '2025-02-28 09:52:05', 'Y', '2025-02-28 09:52:05'),
(17, 0, '/login/', 'undefined', '9879839', 'F', 'Request already processed', '2025-02-28 09:52:43', 'Y', '2025-02-28 09:52:43'),
(18, 0, '/login/', 'undefined', '9879839', 'F', 'Request already processed', '2025-02-28 09:52:43', 'Y', '2025-02-28 09:52:43'),
(19, 0, '/login/', 'undefined', '987982139', 'F', 'Invalid credentials. Please try again!', '2025-02-28 09:52:48', 'Y', '2025-02-28 09:52:48'),
(20, 0, '/login/', 'undefined', '987982139', 'F', 'Invalid credentials. Please try again!', '2025-02-28 09:52:48', 'Y', '2025-02-28 09:52:48'),
(21, 0, '/login/', 'undefined', '987982139', 'F', 'Request already processed', '2025-02-28 09:54:12', 'Y', '2025-02-28 09:54:12'),
(22, 0, '/login/', 'undefined', '987982139', 'F', 'Request already processed', '2025-02-28 09:54:12', 'Y', '2025-02-28 09:54:12'),
(23, 0, '/login/', 'undefined', '9879828u139', 'F', 'Invalid credentials. Please try again!', '2025-02-28 09:54:18', 'Y', '2025-02-28 09:54:18'),
(24, 0, '/login/', 'undefined', '9879828u139', 'F', 'Invalid credentials. Please try again!', '2025-02-28 09:54:18', 'Y', '2025-02-28 09:54:18'),
(25, 0, '/login/', 'undefined', '9879828u139', 'F', 'Request already processed', '2025-02-28 09:55:49', 'Y', '2025-02-28 09:55:49'),
(26, 0, '/login/', 'undefined', '9879828u139', 'F', 'Request already processed', '2025-02-28 09:55:49', 'Y', '2025-02-28 09:55:49'),
(27, 0, '/login/', 'undefined', '9879828u139982', 'S', 'Success', '2025-02-28 10:03:14', 'Y', '2025-02-28 09:55:55'),
(28, 0, '/login/', 'undefined', '9879828u139982', 'S', 'Success', '2025-02-28 10:03:14', 'Y', '2025-02-28 09:55:55'),
(29, 0, '/login/', 'undefined', '9879828u139982', 'S', 'Success', '2025-02-28 10:03:14', 'Y', '2025-02-28 09:59:57'),
(30, 0, '/login/', 'undefined', '9879828u139982', 'S', 'Success', '2025-02-28 10:03:14', 'Y', '2025-02-28 09:59:57'),
(31, 0, '/login/', 'undefined', '9879828u139982', 'S', 'Success', '2025-02-28 10:03:14', 'Y', '2025-02-28 10:03:14'),
(32, 0, '/login/', 'undefined', '9879828u139982', 'S', 'Success', '2025-02-28 10:03:14', 'Y', '2025-02-28 10:03:14'),
(33, 0, '/login/', 'undefined', '628710823741', 'F', 'Invalid credentials. Please try again!', '2025-02-28 10:14:49', 'Y', '2025-02-28 10:14:49'),
(34, 0, '/login/', 'undefined', '628710823741', 'F', 'Invalid credentials. Please try again!', '2025-02-28 10:14:49', 'Y', '2025-02-28 10:14:49'),
(35, 0, '/login/', 'undefined', '660886820490', 'S', 'Success', '2025-02-28 10:15:54', 'Y', '2025-02-28 10:15:54'),
(36, 0, '/login/', 'undefined', '660886820490', 'S', 'Success', '2025-02-28 10:15:54', 'Y', '2025-02-28 10:15:54'),
(38, 0, '/login/logout', '::1', '9879828u139982', 'F', 'Request already processed', '2025-02-28 10:29:16', 'Y', '2025-02-28 10:29:16'),
(39, 0, '/login/logout', '::1', '9879828u139982', 'F', 'Request already processed', '2025-02-28 10:31:11', 'Y', '2025-02-28 10:31:11'),
(40, 0, '/login/logout', '::1', '9879828u139982', 'F', 'Request already processed', '2025-02-28 10:33:45', 'Y', '2025-02-28 10:33:45'),
(41, 0, '/login/logout', '::1', '9879828u139982', 'F', 'Request already processed', '2025-02-28 10:35:36', 'Y', '2025-02-28 10:35:36'),
(42, 0, '/login/logout', '::1', '9879828u139982', 'F', 'Request already processed', '2025-02-28 10:36:42', 'Y', '2025-02-28 10:36:42'),
(43, 0, '/login/logout', '::1', '9879828u139982', 'F', 'Request already processed', '2025-02-28 10:38:00', 'Y', '2025-02-28 10:38:00'),
(44, 0, '/login/logout', '::1', '9879828u139982', 'F', 'Request already processed', '2025-02-28 10:39:45', 'Y', '2025-02-28 10:39:45'),
(45, 0, '/login/logout', '::1', '9879828u139982', 'F', 'Request already processed', '2025-02-28 10:41:04', 'Y', '2025-02-28 10:41:04'),
(46, 0, '/login/logout', '::1', '9837289729', 'F', 'Invalid token', '2025-02-28 10:41:55', 'Y', '2025-02-28 10:41:55'),
(47, 0, '/login/logout', '::1', '9837289729', 'F', 'Request already processed', '2025-02-28 10:42:27', 'Y', '2025-02-28 10:42:27'),
(48, 1, '/login/logout', '::1', '9837289827989729', 'F', 'Error occurred', '2025-02-28 10:46:48', 'Y', '2025-02-28 10:42:45'),
(49, 0, '/login/logout', '::1', '9837289827989729', 'F', 'Request already processed', '2025-02-28 10:47:09', 'Y', '2025-02-28 10:47:09'),
(50, 0, '/login/logout', '::1', '9837289827989729', 'F', 'Request already processed', '2025-02-28 10:48:22', 'Y', '2025-02-28 10:48:22'),
(51, 0, '/login/logout', '::1', '9837289827989729', 'F', 'Request already processed', '2025-02-28 10:49:40', 'Y', '2025-02-28 10:49:40'),
(52, 0, '/login/logout', '::1', '9837289827989729', 'F', 'Request already processed', '2025-02-28 10:51:35', 'Y', '2025-02-28 10:51:35'),
(53, 1, '/login/logout', '::1', '98372898279ndk89729', 'S', 'Success', '2025-02-28 10:59:56', 'Y', '2025-02-28 10:51:40'),
(54, 0, '/login/logout', '::1', '98372898279ndk89729', 'F', 'Request already processed', '2025-02-28 11:02:19', 'Y', '2025-02-28 11:02:19'),
(55, 0, '/login/', 'undefined', '229385796024', 'S', 'Success', '2025-02-28 11:03:28', 'Y', '2025-02-28 11:03:28'),
(56, 0, '/login/', 'undefined', '229385796024', 'S', 'Success', '2025-02-28 11:03:28', 'Y', '2025-02-28 11:03:28'),
(57, 0, '/login/logout', '::1', '322615329059', 'F', 'Token is required', '2025-02-28 11:04:17', 'Y', '2025-02-28 11:04:17'),
(58, 0, '/login/logout', '::1', '867557157123', 'F', 'Token is required', '2025-02-28 11:05:09', 'Y', '2025-02-28 11:05:09'),
(59, 0, '/login/logout', 'NULL', '207309961294', 'F', 'Token is required', '2025-02-28 11:14:21', 'Y', '2025-02-28 11:14:21'),
(60, 0, '/login/logout', 'NULL', '98372898279ndk89729', 'F', 'Request already processed', '2025-02-28 11:14:59', 'Y', '2025-02-28 11:14:59'),
(61, 0, '/login/logout', 'NULL', '98372898279ndk89729', 'F', 'Request already processed', '2025-02-28 11:15:15', 'Y', '2025-02-28 11:15:15'),
(62, 0, 'https://yourdomain.com/api/endpoint', '192.168.1.1', 'request123', 'F', 'Invalid token or User ID', '2025-02-28 11:17:25', 'Y', '2025-02-28 11:17:25'),
(63, 0, '/login/logout', 'NULL', '966712617336', 'F', 'Token is required', '2025-02-28 11:18:17', 'Y', '2025-02-28 11:18:17'),
(64, 0, '/login/logout', 'NULL', '976905553939', 'F', 'Token is required', '2025-02-28 11:20:56', 'Y', '2025-02-28 11:20:56'),
(65, 0, '/login/logout', 'NULL', '814065926162', 'F', 'Token is required', '2025-02-28 11:22:14', 'Y', '2025-02-28 11:22:14'),
(66, 0, '/login/logout', 'NULL', '814065926162', 'F', 'Request already processed', '2025-02-28 11:22:40', 'Y', '2025-02-28 11:22:40'),
(67, 0, '/login/logout', 'NULL', '595405467110', 'F', 'Token is required', '2025-02-28 11:24:54', 'Y', '2025-02-28 11:24:54'),
(68, 0, '/login/', 'undefined', '773526602299', 'S', 'Success', '2025-02-28 11:26:43', 'Y', '2025-02-28 11:26:43'),
(69, 0, '/login/', 'undefined', '773526602299', 'S', 'Success', '2025-02-28 11:26:43', 'Y', '2025-02-28 11:26:43'),
(70, 1, '/login/logout', 'NULL', '735474436245', 'N', '-', '0000-00-00 00:00:00', 'Y', '2025-02-28 11:27:17'),
(71, 1, '/login/logout', 'NULL', '735474436245', 'N', '-', '0000-00-00 00:00:00', 'Y', '2025-02-28 11:27:47'),
(72, 1, '/login/logout', 'NULL', '627298065623', 'N', '-', '0000-00-00 00:00:00', 'Y', '2025-02-28 11:28:45'),
(73, 1, '/login/logout', 'NULL', '932374408746', 'N', '-', '0000-00-00 00:00:00', 'Y', '2025-02-28 11:29:05'),
(74, 1, '/login/logout', 'NULL', '709820800583', 'F', 'Error occurred', '2025-02-28 11:29:34', 'Y', '2025-02-28 11:29:34'),
(75, 1, '/login/logout', 'NULL', '242104121707', 'N', '-', '0000-00-00 00:00:00', 'Y', '2025-02-28 11:29:57'),
(76, 1, '/login/logout', 'NULL', '553779126911', 'N', '-', '0000-00-00 00:00:00', 'Y', '2025-02-28 11:30:48'),
(77, 1, '/login/logout', 'NULL', '581023623749', 'N', '-', '0000-00-00 00:00:00', 'Y', '2025-02-28 11:31:09'),
(78, 1, '/login/logout', 'NULL', '766086129584', 'N', '-', '0000-00-00 00:00:00', 'Y', '2025-02-28 11:32:48'),
(79, 1, '/login/logout', 'NULL', '354872780138', 'N', '-', '0000-00-00 00:00:00', 'Y', '2025-02-28 11:33:59'),
(80, 1, '/login/logout', 'NULL', '870455117507', 'N', '-', '0000-00-00 00:00:00', 'Y', '2025-02-28 11:34:33'),
(81, 1, '/login/logout', 'NULL', '147832156162', 'S', 'Success', '2025-02-28 11:35:31', 'Y', '2025-02-28 11:35:31'),
(82, 0, '/login/', 'undefined', '927985704137', 'S', 'Success', '2025-02-28 11:42:35', 'Y', '2025-02-28 11:42:35'),
(83, 0, '/login/', 'undefined', '927985704137', 'S', 'Success', '2025-02-28 11:42:35', 'Y', '2025-02-28 11:42:35'),
(84, 0, '/login/logout', 'NULL', '133471311850', 'F', 'Invalid token', '2025-02-28 11:49:06', 'Y', '2025-02-28 11:49:06'),
(85, 1, '/login/logout', 'NULL', '762703300479', 'S', 'Success', '2025-02-28 11:50:05', 'Y', '2025-02-28 11:50:05'),
(86, 0, '/login/', 'undefined', '553351541512', 'S', 'Success', '2025-02-28 11:50:16', 'Y', '2025-02-28 11:50:16'),
(87, 0, '/login/', 'undefined', '553351541512', 'S', 'Success', '2025-02-28 11:50:16', 'Y', '2025-02-28 11:50:16'),
(88, 1, '/login/logout', 'NULL', '514285426000', 'S', 'Success', '2025-02-28 11:52:04', 'Y', '2025-02-28 11:52:04'),
(89, 0, '/login/', 'undefined', '462074910904', 'S', 'Success', '2025-02-28 11:52:11', 'Y', '2025-02-28 11:52:11'),
(90, 0, '/login/', 'undefined', '462074910904', 'S', 'Success', '2025-02-28 11:52:11', 'Y', '2025-02-28 11:52:11'),
(91, 0, '/login/', 'undefined', '142801678368', 'S', 'Success', '2025-02-28 11:59:35', 'Y', '2025-02-28 11:59:35'),
(92, 0, '/login/', 'undefined', '142801678368', 'S', 'Success', '2025-02-28 11:59:35', 'Y', '2025-02-28 11:59:35'),
(93, 1, '/login/logout', 'NULL', '880858342960', 'S', 'Success', '2025-02-28 11:59:41', 'Y', '2025-02-28 11:59:41'),
(94, 0, '/login/', 'undefined', '858751454976', 'S', 'Success', '2025-02-28 12:00:33', 'Y', '2025-02-28 12:00:33'),
(95, 0, '/login/', 'undefined', '858751454976', 'S', 'Success', '2025-02-28 12:00:33', 'Y', '2025-02-28 12:00:33'),
(96, 0, '/login/', 'undefined', '141009983386', 'S', 'Success', '2025-02-28 12:00:36', 'Y', '2025-02-28 12:00:36'),
(97, 0, '/login/', 'undefined', '141009983386', 'S', 'Success', '2025-02-28 12:00:36', 'Y', '2025-02-28 12:00:36'),
(98, 0, '/login/', 'undefined', '716710902505', 'S', 'Success', '2025-02-28 12:00:42', 'Y', '2025-02-28 12:00:42'),
(99, 0, '/login/', 'undefined', '716710902505', 'S', 'Success', '2025-02-28 12:00:42', 'Y', '2025-02-28 12:00:42'),
(100, 0, '/login/', 'undefined', '660903250494', 'S', 'Success', '2025-02-28 12:01:04', 'Y', '2025-02-28 12:01:04'),
(101, 0, '/login/', 'undefined', '660903250494', 'S', 'Success', '2025-02-28 12:01:04', 'Y', '2025-02-28 12:01:04'),
(102, 0, '/login/', 'undefined', '323000428248', 'S', 'Success', '2025-02-28 12:01:31', 'Y', '2025-02-28 12:01:31'),
(103, 0, '/login/', 'undefined', '323000428248', 'S', 'Success', '2025-02-28 12:01:31', 'Y', '2025-02-28 12:01:31'),
(104, 0, '/login/', 'undefined', '357147674242', 'S', 'Success', '2025-02-28 12:02:26', 'Y', '2025-02-28 12:02:26'),
(105, 0, '/login/', 'undefined', '357147674242', 'S', 'Success', '2025-02-28 12:02:26', 'Y', '2025-02-28 12:02:26'),
(106, 0, '/login/', 'undefined', '267843137411', 'S', 'Success', '2025-02-28 12:02:41', 'Y', '2025-02-28 12:02:41'),
(107, 0, '/login/', 'undefined', '267843137411', 'S', 'Success', '2025-02-28 12:02:41', 'Y', '2025-02-28 12:02:41'),
(108, 0, '/login/logout', 'NULL', '842350635954', 'F', 'Invalid token', '2025-02-28 12:07:21', 'Y', '2025-02-28 12:07:21'),
(109, 0, '/login/logout', 'NULL', '662452844563', 'F', 'Invalid token', '2025-02-28 12:11:03', 'Y', '2025-02-28 12:11:03'),
(110, 0, '/login/logout', 'NULL', '424620928241', 'F', 'Invalid token', '2025-02-28 12:11:16', 'Y', '2025-02-28 12:11:16'),
(111, 0, '/login/logout', 'NULL', '716889839733', 'F', 'Invalid token', '2025-02-28 12:11:55', 'Y', '2025-02-28 12:11:55'),
(112, 0, '/login/logout', 'NULL', '508084000257', 'F', 'Invalid token', '2025-02-28 12:12:25', 'Y', '2025-02-28 12:12:25'),
(113, 0, '/login/', 'undefined', '855749069441', 'S', 'Success', '2025-02-28 12:13:00', 'Y', '2025-02-28 12:13:00'),
(114, 0, '/login/', 'undefined', '855749069441', 'S', 'Success', '2025-02-28 12:13:00', 'Y', '2025-02-28 12:13:00'),
(115, 1, '/login/logout', 'NULL', '571730364289', 'S', 'Success', '2025-02-28 12:13:05', 'Y', '2025-02-28 12:13:05'),
(116, 0, '/login/', 'undefined', '891367109822', 'S', 'Success', '2025-02-28 12:13:07', 'Y', '2025-02-28 12:13:07'),
(117, 0, '/login/', 'undefined', '891367109822', 'S', 'Success', '2025-02-28 12:13:07', 'Y', '2025-02-28 12:13:07'),
(118, 0, '/login/', 'undefined', '470797670074', 'S', 'Success', '2025-02-28 12:18:19', 'Y', '2025-02-28 12:18:19'),
(119, 0, '/login/', 'undefined', '470797670074', 'S', 'Success', '2025-02-28 12:18:19', 'Y', '2025-02-28 12:18:19'),
(120, 0, '/login/', 'undefined', '631171411081', 'S', 'Success', '2025-02-28 12:21:01', 'Y', '2025-02-28 12:21:01'),
(121, 0, '/login/', 'undefined', '631171411081', 'S', 'Success', '2025-02-28 12:21:01', 'Y', '2025-02-28 12:21:01'),
(122, 0, '/login/', 'undefined', '360308748575', 'S', 'Success', '2025-02-28 12:21:27', 'Y', '2025-02-28 12:21:27'),
(123, 0, '/login/', 'undefined', '360308748575', 'S', 'Success', '2025-02-28 12:21:27', 'Y', '2025-02-28 12:21:27'),
(124, 0, '/login/', 'undefined', '646135568497', 'S', 'Success', '2025-02-28 12:21:36', 'Y', '2025-02-28 12:21:36'),
(125, 0, '/login/', 'undefined', '646135568497', 'S', 'Success', '2025-02-28 12:21:36', 'Y', '2025-02-28 12:21:36'),
(126, 0, '/login/', 'undefined', '612719982002', 'S', 'Success', '2025-02-28 12:21:44', 'Y', '2025-02-28 12:21:44'),
(127, 0, '/login/', 'undefined', '612719982002', 'S', 'Success', '2025-02-28 12:21:44', 'Y', '2025-02-28 12:21:44'),
(128, 0, '/login/', 'undefined', '757713531201', 'S', 'Success', '2025-02-28 12:23:50', 'Y', '2025-02-28 12:23:50'),
(129, 0, '/login/', 'undefined', '757713531201', 'S', 'Success', '2025-02-28 12:23:50', 'Y', '2025-02-28 12:23:50'),
(130, 0, '/login/', 'undefined', '945769299509', 'S', 'Success', '2025-02-28 12:24:13', 'Y', '2025-02-28 12:24:12'),
(131, 0, '/login/', 'undefined', '945769299509', 'S', 'Success', '2025-02-28 12:24:13', 'Y', '2025-02-28 12:24:12'),
(132, 0, '/login/', 'undefined', '589363757030', 'S', 'Success', '2025-02-28 12:50:42', 'Y', '2025-02-28 12:50:42'),
(133, 0, '/login/', 'undefined', '589363757030', 'S', 'Success', '2025-02-28 12:50:42', 'Y', '2025-02-28 12:50:42'),
(134, 0, '/login/', 'undefined', '583756692906', 'S', 'Success', '2025-02-28 12:57:43', 'Y', '2025-02-28 12:57:43'),
(135, 0, '/login/', 'undefined', '583756692906', 'S', 'Success', '2025-02-28 12:57:43', 'Y', '2025-02-28 12:57:43'),
(136, 0, '/login/', 'undefined', '783138126279', 'S', 'Success', '2025-03-01 04:48:53', 'Y', '2025-03-01 04:48:53'),
(137, 0, '/login/', 'undefined', '783138126279', 'S', 'Success', '2025-03-01 04:48:53', 'Y', '2025-03-01 04:48:53'),
(138, 0, '/login/', 'undefined', '821525473465', 'S', 'Success', '2025-03-01 07:49:25', 'Y', '2025-03-01 07:49:25'),
(139, 0, '/login/', 'undefined', '821525473465', 'S', 'Success', '2025-03-01 07:49:25', 'Y', '2025-03-01 07:49:25'),
(140, 0, '/login/', 'undefined', '204836657957', 'S', 'Success', '2025-03-01 07:52:02', 'Y', '2025-03-01 07:52:02'),
(141, 0, '/login/', 'undefined', '204836657957', 'S', 'Success', '2025-03-01 07:52:02', 'Y', '2025-03-01 07:52:02'),
(142, 0, '/login/', 'undefined', '904127221474', 'S', 'Success', '2025-03-01 09:34:07', 'Y', '2025-03-01 09:34:07'),
(143, 0, '/login/', 'undefined', '904127221474', 'S', 'Success', '2025-03-01 09:34:07', 'Y', '2025-03-01 09:34:07'),
(144, 0, '/login/', 'undefined', '535819895415', 'S', 'Success', '2025-03-01 09:34:31', 'Y', '2025-03-01 09:34:31'),
(145, 0, '/login/', 'undefined', '535819895415', 'S', 'Success', '2025-03-01 09:34:31', 'Y', '2025-03-01 09:34:31'),
(146, 0, '/login/', 'undefined', '304534594812', 'S', 'Success', '2025-03-01 09:36:57', 'Y', '2025-03-01 09:36:57'),
(147, 0, '/login/', 'undefined', '304534594812', 'S', 'Success', '2025-03-01 09:36:57', 'Y', '2025-03-01 09:36:57'),
(148, 0, '/login/', 'undefined', '996969039946', 'S', 'Success', '2025-03-01 09:45:15', 'Y', '2025-03-01 09:45:15'),
(149, 0, '/login/', 'undefined', '996969039946', 'S', 'Success', '2025-03-01 09:45:15', 'Y', '2025-03-01 09:45:15'),
(150, 0, '/login/', 'undefined', '410585276761', 'S', 'Success', '2025-03-01 10:08:00', 'Y', '2025-03-01 10:08:00'),
(151, 0, '/login/', 'undefined', '410585276761', 'S', 'Success', '2025-03-01 10:08:00', 'Y', '2025-03-01 10:08:00'),
(152, 0, '/login/', 'undefined', '264149499383', 'S', 'Success', '2025-03-01 10:24:58', 'Y', '2025-03-01 10:24:58'),
(153, 0, '/login/', 'undefined', '264149499383', 'S', 'Success', '2025-03-01 10:24:58', 'Y', '2025-03-01 10:24:58'),
(154, 0, '/login/', 'undefined', '184610196421', 'S', 'Success', '2025-03-01 10:30:41', 'Y', '2025-03-01 10:30:41'),
(155, 0, '/login/', 'undefined', '184610196421', 'S', 'Success', '2025-03-01 10:30:41', 'Y', '2025-03-01 10:30:41'),
(156, 0, '/login/', 'undefined', '104055642201', 'S', 'Success', '2025-03-01 10:39:38', 'Y', '2025-03-01 10:39:37'),
(157, 0, '/login/', 'undefined', '104055642201', 'S', 'Success', '2025-03-01 10:39:38', 'Y', '2025-03-01 10:39:37'),
(158, 0, '/login/', 'undefined', '227109585409', 'S', 'Success', '2025-03-01 10:40:29', 'Y', '2025-03-01 10:40:29'),
(159, 0, '/login/', 'undefined', '227109585409', 'S', 'Success', '2025-03-01 10:40:29', 'Y', '2025-03-01 10:40:29'),
(160, 0, '/login/', 'undefined', '908567225118', 'S', 'Success', '2025-03-03 07:17:17', 'Y', '2025-03-03 07:17:16'),
(161, 0, '/login/', 'undefined', '908567225118', 'S', 'Success', '2025-03-03 07:17:17', 'Y', '2025-03-03 07:17:17'),
(162, 0, '/login/', 'undefined', '320654410077', 'S', 'Success', '2025-03-03 07:19:22', 'Y', '2025-03-03 07:19:22'),
(163, 0, '/login/', 'undefined', '320654410077', 'S', 'Success', '2025-03-03 07:19:22', 'Y', '2025-03-03 07:19:22'),
(164, 1, '/login/logout', 'NULL', '547713887586', 'S', 'Success', '2025-03-03 07:28:06', 'Y', '2025-03-03 07:28:06'),
(165, 0, '/login/logout', 'NULL', '993838935325', 'F', 'Token is required', '2025-03-03 07:31:47', 'Y', '2025-03-03 07:31:47'),
(166, 0, '/login/', 'undefined', '648722908782', 'S', 'Success', '2025-03-03 07:32:09', 'Y', '2025-03-03 07:32:09'),
(167, 0, '/login/', 'undefined', '648722908782', 'S', 'Success', '2025-03-03 07:32:09', 'Y', '2025-03-03 07:32:09'),
(168, 1, '/login/logout', 'NULL', '916827757273', 'S', 'Success', '2025-03-03 07:32:14', 'Y', '2025-03-03 07:32:14'),
(169, 0, '/login/', 'undefined', '628790611977', 'S', 'Success', '2025-03-03 07:32:19', 'Y', '2025-03-03 07:32:19'),
(170, 0, '/login/', 'undefined', '628790611977', 'S', 'Success', '2025-03-03 07:32:19', 'Y', '2025-03-03 07:32:19'),
(171, 1, '/login/logout', 'NULL', '326802904359', 'S', 'Success', '2025-03-03 07:32:29', 'Y', '2025-03-03 07:32:29'),
(172, 0, '/login/', 'undefined', '205128240080', 'S', 'Success', '2025-03-03 07:36:23', 'Y', '2025-03-03 07:36:23'),
(173, 0, '/login/', 'undefined', '205128240080', 'S', 'Success', '2025-03-03 07:36:23', 'Y', '2025-03-03 07:36:23'),
(174, 1, '/login/logout', 'NULL', '807098862469', 'S', 'Success', '2025-03-03 07:38:38', 'Y', '2025-03-03 07:38:38'),
(175, 0, '/login/', 'undefined', '979532145396', 'S', 'Success', '2025-03-03 07:39:11', 'Y', '2025-03-03 07:39:11'),
(176, 0, '/login/', 'undefined', '979532145396', 'S', 'Success', '2025-03-03 07:39:11', 'Y', '2025-03-03 07:39:11'),
(177, 1, '/login/logout', 'NULL', '783309329846', 'S', 'Success', '2025-03-03 07:39:37', 'Y', '2025-03-03 07:39:37'),
(178, 0, '/login/', 'undefined', '588258451346', 'S', 'Success', '2025-03-03 07:41:13', 'Y', '2025-03-03 07:41:13'),
(179, 0, '/login/', 'undefined', '588258451346', 'S', 'Success', '2025-03-03 07:41:13', 'Y', '2025-03-03 07:41:13'),
(180, 1, '/login/logout', 'NULL', '668852265609', 'S', 'Success', '2025-03-03 07:41:23', 'Y', '2025-03-03 07:41:23'),
(181, 0, '/login/', 'undefined', '971958515256', 'S', 'Success', '2025-03-03 09:42:19', 'Y', '2025-03-03 09:42:19'),
(182, 0, '/login/', 'undefined', '971958515256', 'S', 'Success', '2025-03-03 09:42:19', 'Y', '2025-03-03 09:42:19'),
(183, 1, '/login/logout', 'NULL', '461635041810', 'S', 'Success', '2025-03-03 09:42:25', 'Y', '2025-03-03 09:42:25'),
(184, 0, '/login/', 'undefined', '352513715757', 'S', 'Success', '2025-03-03 09:42:27', 'Y', '2025-03-03 09:42:27'),
(185, 0, '/login/', 'undefined', '352513715757', 'S', 'Success', '2025-03-03 09:42:27', 'Y', '2025-03-03 09:42:27'),
(186, 1, '/login/logout', 'NULL', '321777654607', 'S', 'Success', '2025-03-03 09:42:48', 'Y', '2025-03-03 09:42:48'),
(187, 0, '/login/', 'undefined', '661805320800', 'S', 'Success', '2025-03-03 09:44:03', 'Y', '2025-03-03 09:44:03'),
(188, 0, '/login/', 'undefined', '661805320800', 'S', 'Success', '2025-03-03 09:44:03', 'Y', '2025-03-03 09:44:03'),
(189, 1, '/login/logout', 'NULL', '567661538787', 'S', 'Success', '2025-03-03 09:44:11', 'Y', '2025-03-03 09:44:11'),
(190, 0, '/login/signup', 'undefined', '869778515391', 'S', 'Success', '2025-03-03 10:49:13', 'Y', '2025-03-03 10:49:13'),
(191, 0, '/login/logout', 'NULL', '823275382005', 'F', 'Token is required', '2025-03-03 10:50:23', 'Y', '2025-03-03 10:50:23'),
(192, 0, '/login/logout', 'NULL', '450772129204', 'F', 'Token is required', '2025-03-03 10:51:36', 'Y', '2025-03-03 10:51:36'),
(193, 0, '/login/', 'undefined', '189201047354', 'S', 'Success', '2025-03-03 10:52:33', 'Y', '2025-03-03 10:52:33'),
(194, 0, '/login/', 'undefined', '189201047354', 'S', 'Success', '2025-03-03 10:52:33', 'Y', '2025-03-03 10:52:33'),
(195, 1, '/login/logout', 'NULL', '838501867133', 'S', 'Success', '2025-03-03 10:52:38', 'Y', '2025-03-03 10:52:38');

-- --------------------------------------------------------

--
-- Table structure for table `nfts`
--

CREATE TABLE `nfts` (
  `id` int NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text,
  `price` decimal(10,2) DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `user_id` int NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

--
-- Dumping data for table `nfts`
--

INSERT INTO `nfts` (`id`, `name`, `description`, `price`, `image_url`, `user_id`, `created_at`) VALUES
(1, 'dempo', 'skdsd', 60.00, 'https://yeejai.in/ucp/uploads/whatsapp_images/1_1736310405480.png', 1, '2025-01-17 15:49:06'),
(2, 'dempo', 'skdsd', 60.00, 'https://yeejai.in/ucp/uploads/whatsapp_images/1_1736310405480.png', 1, '2025-01-17 15:52:32'),
(3, 'sndks', 'skdnks', 20.00, 'https://yeejai.in/ucp/uploads/whatsapp_images/1_1736310405480.png', 1, '2025-01-17 15:53:15'),
(4, 'skndksnd', 'ksndks', 757.00, 'https://yeejai.in/ucp/uploads/whatsapp_images/1_1736310405480.png', 1, '2025-01-17 15:55:47');

-- --------------------------------------------------------

--
-- Table structure for table `transactions`
--

CREATE TABLE `transactions` (
  `id` int NOT NULL,
  `nft_id` int NOT NULL,
  `user_id` int NOT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

--
-- Dumping data for table `transactions`
--

INSERT INTO `transactions` (`id`, `nft_id`, `user_id`, `amount`, `created_at`) VALUES
(1, 2, 1, 10.00, '2025-01-17 16:09:40');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int NOT NULL,
  `user_name` varchar(50) DEFAULT NULL,
  `email` varchar(255) NOT NULL,
  `usr_password` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `token` varchar(500) DEFAULT NULL,
  `user_status` char(1) DEFAULT NULL,
  `api_key` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `user_name`, `email`, `usr_password`, `created_at`, `token`, `user_status`, `api_key`) VALUES
(1, 'admin', 'info@codedthemes.com', 'e10adc3949ba59abbe56e057f20f883e', '2025-01-17 14:51:21', '-', 'Y', '283768jhejfebbewjk'),
(2, 'madhu bala', 'madhubalajapk@gmail.com', '1a2bf6296df8d4f8149a9d3a0cb89882', '2025-03-03 10:49:13', '-', 'Y', 'c6b193dd733785079f69');

-- --------------------------------------------------------

--
-- Table structure for table `user_log`
--

CREATE TABLE `user_log` (
  `user_log_id` int NOT NULL,
  `user_id` int NOT NULL,
  `ip_address` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `login_date` date NOT NULL,
  `login_time` timestamp NOT NULL,
  `logout_time` timestamp NULL DEFAULT NULL,
  `user_log_status` char(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `user_log_entry_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

--
-- Dumping data for table `user_log`
--

INSERT INTO `user_log` (`user_log_id`, `user_id`, `ip_address`, `login_date`, `login_time`, `logout_time`, `user_log_status`, `user_log_entry_date`) VALUES
(1, 1, 'undefined', '2025-02-28', '2025-02-28 10:03:14', '2025-02-28 10:15:54', 'O', '2025-02-28 10:03:14'),
(2, 1, 'undefined', '2025-02-28', '2025-02-28 10:15:54', '2025-02-28 11:03:28', 'O', '2025-02-28 10:15:54'),
(3, 1, 'undefined', '2025-02-28', '2025-02-28 11:03:28', '2025-02-28 11:26:43', 'O', '2025-02-28 11:03:28'),
(4, 1, 'undefined', '2025-02-28', '2025-02-28 11:26:43', '2025-02-28 11:42:35', 'O', '2025-02-28 11:26:43'),
(5, 1, 'undefined', '2025-02-28', '2025-02-28 11:42:35', '2025-02-28 11:50:16', 'O', '2025-02-28 11:42:35'),
(6, 1, 'undefined', '2025-02-28', '2025-02-28 11:50:16', '2025-02-28 11:52:11', 'O', '2025-02-28 11:50:16'),
(7, 1, 'undefined', '2025-02-28', '2025-02-28 11:52:11', '2025-02-28 11:59:35', 'O', '2025-02-28 11:52:11'),
(8, 1, 'undefined', '2025-02-28', '2025-02-28 11:59:35', '2025-02-28 12:00:33', 'O', '2025-02-28 11:59:35'),
(9, 1, 'undefined', '2025-02-28', '2025-02-28 12:00:33', '2025-02-28 12:00:36', 'O', '2025-02-28 12:00:33'),
(10, 1, 'undefined', '2025-02-28', '2025-02-28 12:00:36', '2025-02-28 12:00:42', 'O', '2025-02-28 12:00:36'),
(11, 1, 'undefined', '2025-02-28', '2025-02-28 12:00:42', '2025-02-28 12:01:04', 'O', '2025-02-28 12:00:42'),
(12, 1, 'undefined', '2025-02-28', '2025-02-28 12:01:04', '2025-02-28 12:01:31', 'O', '2025-02-28 12:01:04'),
(13, 1, 'undefined', '2025-02-28', '2025-02-28 12:01:31', '2025-02-28 12:02:26', 'O', '2025-02-28 12:01:31'),
(14, 1, 'undefined', '2025-02-28', '2025-02-28 12:02:26', '2025-02-28 12:02:41', 'O', '2025-02-28 12:02:26'),
(15, 1, 'undefined', '2025-02-28', '2025-02-28 12:02:41', '2025-02-28 12:13:00', 'O', '2025-02-28 12:02:41'),
(16, 1, 'undefined', '2025-02-28', '2025-02-28 12:13:00', '2025-02-28 12:13:07', 'O', '2025-02-28 12:13:00'),
(17, 1, 'undefined', '2025-02-28', '2025-02-28 12:13:07', '2025-02-28 12:18:19', 'O', '2025-02-28 12:13:07'),
(18, 1, 'undefined', '2025-02-28', '2025-02-28 12:18:19', '2025-02-28 12:21:01', 'O', '2025-02-28 12:18:19'),
(19, 1, 'undefined', '2025-02-28', '2025-02-28 12:21:01', '2025-02-28 12:21:27', 'O', '2025-02-28 12:21:01'),
(20, 1, 'undefined', '2025-02-28', '2025-02-28 12:21:27', '2025-02-28 12:21:36', 'O', '2025-02-28 12:21:27'),
(21, 1, 'undefined', '2025-02-28', '2025-02-28 12:21:36', '2025-02-28 12:21:44', 'O', '2025-02-28 12:21:36'),
(22, 1, 'undefined', '2025-02-28', '2025-02-28 12:21:44', '2025-02-28 12:23:50', 'O', '2025-02-28 12:21:44'),
(23, 1, 'undefined', '2025-02-28', '2025-02-28 12:23:50', '2025-02-28 12:24:12', 'O', '2025-02-28 12:23:50'),
(24, 1, 'undefined', '2025-02-28', '2025-02-28 12:24:12', '2025-02-28 12:50:42', 'O', '2025-02-28 12:24:12'),
(25, 1, 'undefined', '2025-02-28', '2025-02-28 12:50:42', '2025-02-28 12:57:43', 'O', '2025-02-28 12:50:42'),
(26, 1, 'undefined', '2025-02-28', '2025-02-28 12:57:43', NULL, 'I', '2025-02-28 12:57:43'),
(27, 1, 'undefined', '2025-03-01', '2025-03-01 04:48:53', '2025-03-01 07:49:25', 'O', '2025-03-01 04:48:53'),
(28, 1, 'undefined', '2025-03-01', '2025-03-01 07:49:25', '2025-03-01 07:52:02', 'O', '2025-03-01 07:49:25'),
(29, 1, 'undefined', '2025-03-01', '2025-03-01 07:52:02', '2025-03-01 09:34:07', 'O', '2025-03-01 07:52:02'),
(30, 1, 'undefined', '2025-03-01', '2025-03-01 09:34:07', '2025-03-01 09:34:31', 'O', '2025-03-01 09:34:07'),
(31, 1, 'undefined', '2025-03-01', '2025-03-01 09:34:31', '2025-03-01 09:36:57', 'O', '2025-03-01 09:34:31'),
(32, 1, 'undefined', '2025-03-01', '2025-03-01 09:36:57', '2025-03-01 09:45:15', 'O', '2025-03-01 09:36:57'),
(33, 1, 'undefined', '2025-03-01', '2025-03-01 09:45:15', '2025-03-01 10:08:00', 'O', '2025-03-01 09:45:15'),
(34, 1, 'undefined', '2025-03-01', '2025-03-01 10:08:00', '2025-03-01 10:24:58', 'O', '2025-03-01 10:08:00'),
(35, 1, 'undefined', '2025-03-01', '2025-03-01 10:24:58', '2025-03-01 10:30:41', 'O', '2025-03-01 10:24:58'),
(36, 1, 'undefined', '2025-03-01', '2025-03-01 10:30:41', '2025-03-01 10:39:37', 'O', '2025-03-01 10:30:41'),
(37, 1, 'undefined', '2025-03-01', '2025-03-01 10:39:37', '2025-03-01 10:40:29', 'O', '2025-03-01 10:39:37'),
(38, 1, 'undefined', '2025-03-01', '2025-03-01 10:40:29', NULL, 'I', '2025-03-01 10:40:29'),
(39, 1, 'undefined', '2025-03-03', '2025-03-03 07:17:17', '2025-03-03 07:19:22', 'O', '2025-03-03 07:17:17'),
(40, 1, 'undefined', '2025-03-03', '2025-03-03 07:19:22', '2025-03-03 07:32:09', 'O', '2025-03-03 07:19:22'),
(41, 1, 'undefined', '2025-03-03', '2025-03-03 07:32:09', '2025-03-03 07:32:19', 'O', '2025-03-03 07:32:09'),
(42, 1, 'undefined', '2025-03-03', '2025-03-03 07:32:19', '2025-03-03 07:36:23', 'O', '2025-03-03 07:32:19'),
(43, 1, 'undefined', '2025-03-03', '2025-03-03 07:36:23', '2025-03-03 07:39:11', 'O', '2025-03-03 07:36:23'),
(44, 1, 'undefined', '2025-03-03', '2025-03-03 07:39:11', '2025-03-03 07:41:13', 'O', '2025-03-03 07:39:11'),
(45, 1, 'undefined', '2025-03-03', '2025-03-03 07:41:13', '2025-03-03 09:42:19', 'O', '2025-03-03 07:41:13'),
(46, 1, 'undefined', '2025-03-03', '2025-03-03 09:42:19', '2025-03-03 09:42:27', 'O', '2025-03-03 09:42:19'),
(47, 1, 'undefined', '2025-03-03', '2025-03-03 09:42:27', '2025-03-03 09:44:03', 'O', '2025-03-03 09:42:27'),
(48, 1, 'undefined', '2025-03-03', '2025-03-03 09:44:03', '2025-03-03 10:52:33', 'O', '2025-03-03 09:44:03'),
(49, 1, 'undefined', '2025-03-03', '2025-03-03 10:52:33', NULL, 'I', '2025-03-03 10:52:33');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `api_log`
--
ALTER TABLE `api_log`
  ADD PRIMARY KEY (`api_log_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `nfts`
--
ALTER TABLE `nfts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `nft_id` (`nft_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `user_log`
--
ALTER TABLE `user_log`
  ADD PRIMARY KEY (`user_log_id`),
  ADD KEY `user_id` (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `api_log`
--
ALTER TABLE `api_log`
  MODIFY `api_log_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=196;

--
-- AUTO_INCREMENT for table `nfts`
--
ALTER TABLE `nfts`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `transactions`
--
ALTER TABLE `transactions`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `user_log`
--
ALTER TABLE `user_log`
  MODIFY `user_log_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=50;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `nfts`
--
ALTER TABLE `nfts`
  ADD CONSTRAINT `nfts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `transactions`
--
ALTER TABLE `transactions`
  ADD CONSTRAINT `transactions_ibfk_1` FOREIGN KEY (`nft_id`) REFERENCES `nfts` (`id`),
  ADD CONSTRAINT `transactions_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
