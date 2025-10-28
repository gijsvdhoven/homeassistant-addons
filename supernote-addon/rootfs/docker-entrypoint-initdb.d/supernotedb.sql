-- Supernote Private Cloud Database Initialization Script
-- Home Assistant Add-on Version
-- This script creates the necessary database structure for Supernote Private Cloud
-- Generated on 2025-10-28

-- Create database if not exists (handled by Docker environment variables)
-- USE supernotedb;

-- Create dictionary table for system configuration
CREATE TABLE IF NOT EXISTS `b_dictionary` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dict_type` varchar(100) NOT NULL COMMENT 'Dictionary type',
  `dict_key` varchar(100) NOT NULL COMMENT 'Dictionary key',
  `dict_value` varchar(500) DEFAULT NULL COMMENT 'Dictionary value',
  `description` varchar(255) DEFAULT NULL COMMENT 'Description',
  `status` tinyint(1) DEFAULT 1 COMMENT 'Status: 1=active, 0=inactive',
  `create_time` timestamp DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_type_key` (`dict_type`, `dict_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='System dictionary table';

-- Create task table for background tasks
CREATE TABLE IF NOT EXISTS `e_task` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `task_id` varchar(64) NOT NULL COMMENT 'Task ID',
  `task_type` varchar(50) NOT NULL COMMENT 'Task type',
  `task_name` varchar(200) DEFAULT NULL COMMENT 'Task name',
  `task_data` text COMMENT 'Task data (JSON)',
  `status` tinyint(1) DEFAULT 0 COMMENT 'Status: 0=pending, 1=running, 2=completed, 3=failed',
  `progress` int(3) DEFAULT 0 COMMENT 'Progress percentage',
  `result` text COMMENT 'Task result',
  `error_message` text COMMENT 'Error message',
  `create_time` timestamp DEFAULT CURRENT_TIMESTAMP,
  `start_time` timestamp NULL DEFAULT NULL,
  `end_time` timestamp NULL DEFAULT NULL,
  `update_time` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_id` (`task_id`),
  KEY `idx_status` (`status`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Task execution table';

-- Create capacity table for storage management
CREATE TABLE IF NOT EXISTS `f_capacity` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL COMMENT 'User ID',
  `total_capacity` bigint(20) DEFAULT 0 COMMENT 'Total capacity in bytes',
  `used_capacity` bigint(20) DEFAULT 0 COMMENT 'Used capacity in bytes',
  `file_count` int(11) DEFAULT 0 COMMENT 'Total file count',
  `last_calculated` timestamp NULL DEFAULT NULL COMMENT 'Last calculation time',
  `create_time` timestamp DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='User capacity management table';

-- Create user table for authentication
CREATE TABLE IF NOT EXISTS `s_user` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL COMMENT 'Username',
  `email` varchar(100) DEFAULT NULL COMMENT 'Email',
  `password` varchar(255) NOT NULL COMMENT 'Encrypted password',
  `salt` varchar(50) DEFAULT NULL COMMENT 'Password salt',
  `nickname` varchar(100) DEFAULT NULL COMMENT 'Nickname',
  `avatar` varchar(500) DEFAULT NULL COMMENT 'Avatar URL',
  `status` tinyint(1) DEFAULT 1 COMMENT 'Status: 1=active, 0=inactive',
  `last_login` timestamp NULL DEFAULT NULL COMMENT 'Last login time',
  `is_admin` tinyint(1) DEFAULT 0 COMMENT 'Admin privileges: 1=admin, 0=user',
  `home_assistant_user` varchar(100) DEFAULT NULL COMMENT 'Linked Home Assistant user',
  `create_time` timestamp DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  UNIQUE KEY `uk_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='User table';

-- Create file table for document management
CREATE TABLE IF NOT EXISTS `n_file` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `file_id` varchar(64) NOT NULL COMMENT 'File ID',
  `user_id` bigint(20) NOT NULL COMMENT 'Owner user ID',
  `file_name` varchar(255) NOT NULL COMMENT 'File name',
  `file_path` varchar(1000) NOT NULL COMMENT 'File path',
  `file_size` bigint(20) DEFAULT 0 COMMENT 'File size in bytes',
  `file_type` varchar(50) DEFAULT NULL COMMENT 'File type',
  `mime_type` varchar(100) DEFAULT NULL COMMENT 'MIME type',
  `checksum` varchar(64) DEFAULT NULL COMMENT 'File checksum',
  `status` tinyint(1) DEFAULT 1 COMMENT 'Status: 1=active, 0=deleted',
  `is_folder` tinyint(1) DEFAULT 0 COMMENT 'Is folder: 1=yes, 0=no',
  `parent_id` bigint(20) DEFAULT NULL COMMENT 'Parent folder ID',
  `sync_status` tinyint(1) DEFAULT 0 COMMENT 'Sync status: 0=pending, 1=synced, 2=conflict',
  `device_id` varchar(100) DEFAULT NULL COMMENT 'Last synced device ID',
  `create_time` timestamp DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_file_id` (`file_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_parent_id` (`parent_id`),
  KEY `idx_status` (`status`),
  KEY `idx_sync_status` (`sync_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='File management table';

-- Create device table for Supernote device management
CREATE TABLE IF NOT EXISTS `d_device` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `device_id` varchar(100) NOT NULL COMMENT 'Unique device identifier',
  `user_id` bigint(20) NOT NULL COMMENT 'Owner user ID',
  `device_name` varchar(200) DEFAULT NULL COMMENT 'Device display name',
  `device_type` varchar(50) DEFAULT NULL COMMENT 'Device type (A5X, A6X, etc.)',
  `firmware_version` varchar(50) DEFAULT NULL COMMENT 'Device firmware version',
  `last_sync` timestamp NULL DEFAULT NULL COMMENT 'Last synchronization time',
  `sync_enabled` tinyint(1) DEFAULT 1 COMMENT 'Sync enabled: 1=yes, 0=no',
  `status` tinyint(1) DEFAULT 1 COMMENT 'Status: 1=active, 0=inactive',
  `create_time` timestamp DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_device_id` (`device_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Device management table';

-- Create system log table for addon monitoring
CREATE TABLE IF NOT EXISTS `s_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `log_level` varchar(20) NOT NULL COMMENT 'Log level',
  `component` varchar(50) NOT NULL COMMENT 'Component name',
  `message` text NOT NULL COMMENT 'Log message',
  `user_id` bigint(20) DEFAULT NULL COMMENT 'Related user ID',
  `device_id` varchar(100) DEFAULT NULL COMMENT 'Related device ID',
  `ip_address` varchar(45) DEFAULT NULL COMMENT 'Client IP address',
  `user_agent` varchar(500) DEFAULT NULL COMMENT 'Client user agent',
  `create_time` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_log_level` (`log_level`),
  KEY `idx_component` (`component`),
  KEY `idx_create_time` (`create_time`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='System log table';

-- Insert default system configuration
INSERT IGNORE INTO `b_dictionary` (`dict_type`, `dict_key`, `dict_value`, `description`) VALUES
('system', 'version', '1.2.0', 'System version'),
('system', 'addon_version', '1.2.0', 'Home Assistant addon version'),
('system', 'max_file_size', '104857600', 'Maximum file size in bytes (100MB)'),
('system', 'allowed_file_types', '.note,.pdf,.txt,.md,.doc,.docx,.png,.jpg,.jpeg', 'Allowed file extensions'),
('system', 'storage_path', '/app/data/supernote_data', 'Default storage path'),
('system', 'backup_enabled', '1', 'Backup feature enabled'),
('system', 'conversion_enabled', '1', 'File conversion enabled'),
('system', 'home_assistant_integration', '1', 'Home Assistant integration enabled'),
('system', 'web_ui_enabled', '1', 'Web UI access enabled'),
('system', 'api_enabled', '1', 'API access enabled'),
('redis', 'session_timeout', '3600', 'Session timeout in seconds'),
('redis', 'cache_timeout', '1800', 'Cache timeout in seconds'),
('security', 'password_min_length', '8', 'Minimum password length'),
('security', 'session_secure', '1', 'Secure session cookies'),
('security', 'api_rate_limit', '100', 'API rate limit per minute'),
('sync', 'auto_sync_enabled', '1', 'Automatic sync enabled'),
('sync', 'sync_interval', '300', 'Sync interval in seconds'),
('sync', 'conflict_resolution', 'newer', 'Conflict resolution strategy'),
('backup', 'auto_backup_enabled', '1', 'Automatic backup enabled'),
('backup', 'backup_retention_days', '30', 'Backup retention period'),
('backup', 'backup_schedule', '0 2 * * *', 'Backup schedule (cron format)');

-- Create default admin user (password: admin123)
-- Note: In production, change this password immediately
INSERT IGNORE INTO `s_user` (`username`, `email`, `password`, `salt`, `nickname`, `is_admin`, `status`) VALUES
('admin', 'admin@homeassistant.local', 'e10adc3949ba59abbe56e057f20f883e', 'default_salt', 'Administrator', 1, 1);

-- Initialize capacity for admin user (100GB default)
INSERT IGNORE INTO `f_capacity` (`user_id`, `total_capacity`, `used_capacity`) VALUES
(1, 107374182400, 0);

-- Create default folders for admin user
INSERT IGNORE INTO `n_file` (`file_id`, `user_id`, `file_name`, `file_path`, `is_folder`, `status`) VALUES
('folder_inbox', 1, 'Inbox', '/Inbox', 1, 1),
('folder_documents', 1, 'Documents', '/Documents', 1, 1),
('folder_notes', 1, 'Notes', '/Notes', 1, 1),
('folder_templates', 1, 'Templates', '/Templates', 1, 1),
('folder_archive', 1, 'Archive', '/Archive', 1, 1);

-- Log initial setup
INSERT INTO `s_log` (`log_level`, `component`, `message`) VALUES
('INFO', 'DATABASE', 'Supernote Private Cloud database initialized successfully'),
('INFO', 'ADDON', 'Home Assistant addon database setup completed'),
('WARN', 'SECURITY', 'Default admin password is active - change immediately');

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS `idx_files_user_path` ON `n_file` (`user_id`, `file_path`);
CREATE INDEX IF NOT EXISTS `idx_files_checksum` ON `n_file` (`checksum`);
CREATE INDEX IF NOT EXISTS `idx_tasks_type_status` ON `e_task` (`task_type`, `status`);
CREATE INDEX IF NOT EXISTS `idx_logs_component_time` ON `s_log` (`component`, `create_time`);
CREATE INDEX IF NOT EXISTS `idx_devices_user_status` ON `d_device` (`user_id`, `status`);

-- Set proper character set and collation
ALTER DATABASE supernotedb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

COMMIT;