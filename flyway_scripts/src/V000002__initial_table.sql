CREATE TABLE IF NOT EXISTS `Account` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` varchar(64) NOT NULL,
  `name` varchar(128) DEFAULT NULL,
  `level_id` smallint(6) DEFAULT '1',
  `is_active` bit(1) DEFAULT b'1',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uid_UNIQUE` (`uid`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `AccountLevel` (
  `id` tinyint(4) NOT NULL,
  `name` varchar(128) DEFAULT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `Level_UNIQUE` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `Benchmark` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `config_json` json NOT NULL,
  `benchmark_key` varchar(64) NOT NULL,
  `name` varchar(128) NOT NULL,
  `frequency_id` int(11) NOT NULL,
  `status_id` tinyint(4) DEFAULT '1',
  `is_active` bit(1) DEFAULT b'1',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `benchmark_UNIQUE` (`benchmark_key`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `BenchmarkCompetitorBrands` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `benchmark_id` int(11) NOT NULL,
  `benchmark_session_id` int(11) NOT NULL,
  `brand_id` int(11) NOT NULL,
  `is_active` bit(1) DEFAULT b'1',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `BenchmarkScore` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `benchmark_id` int(11) NOT NULL,
  `score_json` json NOT NULL,
  `score_type_id` int(11) NOT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `benchmark_score_UNIQUE` (`benchmark_id`,`score_type_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `BenchmarkSession` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `benchmark_id` int(11) NOT NULL,
  `benchmark_session_key` varchar(64) NOT NULL,
  `config_json` json NOT NULL,
  `score_json` json DEFAULT NULL,
  `status_id` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` bit(1) DEFAULT b'1',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `BenchmarkSessionRequest` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `benchmark_session_id` int(11) NOT NULL,
  `benchmark_session_key` varchar(64) NOT NULL,
  `status_id` tinyint(1) NOT NULL DEFAULT '1',
  `priority` int(11) NOT NULL DEFAULT '1',
  `is_active` bit(1) DEFAULT b'1',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `BenchmarkSessionResult` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `benchmark_id` int(11) NOT NULL,
  `benchmark_session_id` int(11) NOT NULL,
  `result_json` json NOT NULL,
  `result_type_id` int(11) NOT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `benchmark_session_result_UNIQUE` (`benchmark_id`,`benchmark_session_id`,`result_type_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `Brand` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `brand_name` varchar(128) CHARACTER SET utf8 NOT NULL,
  `brand_key` varchar(64) NOT NULL,
  `frequency_id` int(11) NOT NULL,
  `config_json` json NOT NULL,
  `origin_id` tinyint(4) NOT NULL,
  `group_id` int(11) DEFAULT NULL,
  `status_id` tinyint(4) NOT NULL DEFAULT '1',
  `last_access_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `last_refresh_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `is_active` bit(1) DEFAULT b'1',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `description` varchar(512) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_Brand_brand_key` (`brand_key`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `BrandArchetypeGoal` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `brand_id` int(11) NOT NULL,
  `archetype_target` varchar(32) NOT NULL,
  `score_json` json DEFAULT NULL,
  `status_id` tinyint(1) NOT NULL DEFAULT '1',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `brand_goal_UNIQUE` (`brand_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `BrandBenchmark` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `benchmark_id` int(11) NOT NULL,
  `brand_id` int(11) NOT NULL,
  `status_id` tinyint(4) NOT NULL DEFAULT '1',
  `is_active` bit(1) DEFAULT b'1',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_brand_UNIQUE` (`brand_id`,`benchmark_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `BrandLogo` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `brand_id` int(11) NOT NULL,
  `brand_logo_url` varchar(1024) CHARACTER SET utf8 NOT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_Brand_Logo` (`brand_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `BrandSession` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `session_key` varchar(64) NOT NULL,
  `brand_id` int(11) NOT NULL,
  `run_status_id` int(11) DEFAULT NULL,
  `config_json` json NOT NULL,
  `last_access_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `is_active` bit(1) DEFAULT b'1',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_Brand_session_key` (`session_key`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `BrandSessionArchetypeScore` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `session_id` int(11) NOT NULL,
  `session_key` varchar(64) NOT NULL,
  `score_type` varchar(32) NOT NULL,
  `score_json` json NOT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `BrandSessionResult` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `brand_session_id` int(11) NOT NULL,
  `result_type_id` smallint(6) NOT NULL,
  `result_json` json NOT NULL,
  `is_active` bit(1) DEFAULT b'1',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `BrandSessionTask` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `brand_session_id` int(11) NOT NULL,
  `content_source_id` int(11) NOT NULL,
  `content_blob_id` int(11) DEFAULT NULL,
  `status_id` tinyint(4) DEFAULT '1',
  `is_active` bit(1) DEFAULT b'1',
  `start_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `end_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `session_task_UNIQUE` (`brand_session_id`,`content_source_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `BrandSetupRequest` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `brand_id` int(11) NOT NULL,
  `status_id` tinyint(4) NOT NULL DEFAULT '1',
  `priority` tinyint(4) NOT NULL DEFAULT '1',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `ChannelType` (
  `id` tinyint(4) NOT NULL,
  `content_type_id` tinyint(4) NOT NULL,
  `name` varchar(128) NOT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `Company` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `logo` text,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_Date` datetime DEFAULT CURRENT_TIMESTAMP,
  `is_active` bit(1) DEFAULT b'1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `ContentBlobMetaInfo` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `content_source_id` int(11) NOT NULL,
  `blob_uri` varchar(1024) CHARACTER SET utf8 NOT NULL,
  `blob_size` int(11) NOT NULL,
  `max_blob_timestamp` timestamp NULL DEFAULT NULL,
  `create_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `ContentSource` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `channel_type_id` int(11) NOT NULL,
  `handle_id` varchar(128) NOT NULL,
  `source_aux` json DEFAULT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `is_active` bit(1) DEFAULT b'1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `source_UNIQUE` (`handle_id`,`channel_type_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3010 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `ContentType` (
  `id` tinyint(4) NOT NULL,
  `name` varchar(128) NOT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `Message` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `msg_uri` varchar(512) NOT NULL,
  `msg_content` varchar(1024) NOT NULL,
  `freq_id` int(11) DEFAULT '1',
  `cat_id` smallint(4) NOT NULL,
  `urge_id` int(11) DEFAULT '2',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `deleted` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `MessageCategory` (
  `id` smallint(6) NOT NULL,
  `name` varchar(64) CHARACTER SET utf8 NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `MessageFrequency` (
  `id` smallint(6) NOT NULL,
  `name` varchar(64) CHARACTER SET utf8 NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `MessageUrgency` (
  `id` smallint(6) NOT NULL,
  `name` varchar(64) CHARACTER SET utf8 NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `ModuleConfiguration` (
  `id` smallint(6) NOT NULL AUTO_INCREMENT,
  `module_name` varchar(128) NOT NULL,
  `sub_module_name` varchar(128) NOT NULL,
  `type_name` varchar(128) NOT NULL,
  `config_json` text NOT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `OriginType` (
  `id` tinyint(4) NOT NULL,
  `name` varchar(32) NOT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `Payment` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `paymentMethodId` varchar(64) DEFAULT NULL,
  `email` varchar(128) DEFAULT NULL,
  `customerId` varchar(64) DEFAULT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `ResultType` (
  `id` tinyint(4) NOT NULL,
  `name` varchar(32) NOT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `result_UNIQUE` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `RoleType` (
  `id` tinyint(4) NOT NULL,
  `name` varchar(64) NOT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `role_UNIQUE` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `ScheduleFrequency` (
  `id` smallint(6) NOT NULL,
  `day_interval` int(11) DEFAULT NULL,
  `name` varchar(32) NOT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name_UNIQUE` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `ScoreType` (
  `id` smallint(6) NOT NULL,
  `name` varchar(32) NOT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name_UNIQUE` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `t_list_row` (
  `_row` int(10) unsigned NOT NULL,
  PRIMARY KEY (`_row`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `User` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(128) NOT NULL,
  `user_id` varchar(64) NOT NULL,
  `auth0UserId` varchar(128) NOT NULL,
  `authSource` varchar(128) NOT NULL,
  `emailVerified` bit(1) DEFAULT b'0',
  `firstName` varchar(64) DEFAULT NULL,
  `lastName` varchar(64) DEFAULT NULL,
  `phone` varchar(32) DEFAULT NULL,
  `companyId` int(11) DEFAULT NULL,
  `roleTypeId` tinyint(4) DEFAULT '1',
  `picture` text,
  `lastLogin` datetime DEFAULT NULL,
  `loginsCount` int(11) DEFAULT NULL,
  `accountId` int(11) NOT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `is_active` bit(1) DEFAULT b'1',
  `interstitialCount` int(11) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_UNIQUE` (`email`,`authSource`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `UserBrand` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `brand_id` int(11) NOT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `is_active` bit(1) DEFAULT b'1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_brand_UNIQUE` (`user_id`,`brand_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `UserFeedback` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `userId` varchar(45) NOT NULL,
  `email` varchar(255) NOT NULL,
  `feedback` varchar(1024) DEFAULT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `UserMessage` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` varchar(128) NOT NULL,
  `user_email` varchar(256) NOT NULL,
  `msg_id` int(11) NOT NULL,
  `is_read` bit(1) DEFAULT b'0',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `UserRole` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `role_type_id` tinyint(4) NOT NULL,
  `status_id` tinyint(4) NOT NULL DEFAULT '1',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `modified_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_role_UNIQUE` (`user_id`,`role_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
