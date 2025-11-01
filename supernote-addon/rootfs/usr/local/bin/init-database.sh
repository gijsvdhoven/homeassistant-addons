#!/usr/bin/with-contenv bashio
# ==============================================================================
# Initialize MariaDB database for Supernote Private Cloud
# ==============================================================================

set -e

MYSQL_ROOT_PASSWORD=$(bashio::config 'mysql_root_password')
MYSQL_PASSWORD=$(bashio::config 'mysql_password')

bashio::log.info "Initializing database..."

# Wait for MySQL to be ready
for i in {1..30}; do
    if mysqladmin ping --silent; then
        bashio::log.info "MySQL is ready"
        break
    fi
    bashio::log.info "Waiting for MySQL to be ready... ($i/30)"
    sleep 2
done

# Set root password (only if not already set)
if /usr/bin/mariadb -u root -e "SELECT 1" &>/dev/null; then
    bashio::log.info "Setting root password..."
    /usr/bin/mariadb -u root <<-EOSQL
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        FLUSH PRIVILEGES;
EOSQL
fi

# Run initialization scripts if database doesn't exist
if ! /usr/bin/mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "USE supernotedb;" 2>/dev/null; then
    bashio::log.info "Creating database and user..."
    
    /usr/bin/mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOSQL

    CREATE DATABASE IF NOT EXISTS supernotedb
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

    CREATE USER IF NOT EXISTS 'supernote'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
    GRANT ALL PRIVILEGES ON supernotedb.* TO 'supernote'@'localhost';
    FLUSH PRIVILEGES;

    USE supernotedb;

    SET FOREIGN_KEY_CHECKS=0;

    CREATE TABLE IF NOT EXISTS  supernotedb.`b_dictionary` (
    `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
    `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '数据名称',
    `value` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '数据值',
    `value_cn` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '中文含义',
    `value_en` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '英文含义',
    `op_user` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '创建人',
    `op_time` datetime NOT NULL COMMENT '创建时间',
    `remark` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
    PRIMARY KEY (`id`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=508 DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;


    CREATE TABLE IF NOT EXISTS  supernotedb.`b_pwd_his` (
    `id` int(65) NOT NULL AUTO_INCREMENT COMMENT '主键 seq_pwd_his',
    `username` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '用户名',
    `pwd` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '密码',
    `op_time` datetime DEFAULT NULL COMMENT '操作时间',
    PRIMARY KEY (`id`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=301 DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;


    CREATE TABLE IF NOT EXISTS  supernotedb.`b_reference` (
    `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'PK(seq_reference)\r\n',
    `serial` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '序号',
    `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '参数值',
    `value` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '参数值',
    `value_cn` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '中文简体参数值\r说明',
    `op_user` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '修改人员\r\n',
    `op_time` datetime NOT NULL COMMENT '修改时间\r\n',
    `remark` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE KEY `SERIAL,NAME` (`serial`,`name`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=221 DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;

    CREATE TABLE IF NOT EXISTS  supernotedb.`b_resource` (
    `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '资源ID',
    `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '资源名称',
    `remark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '资源描述',
    `seq` int(10) DEFAULT NULL COMMENT '资源序号',
    `url` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '资源地址',
    `pid` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '父级ID',
    `system_id` int(11) NOT NULL COMMENT '系统类别',
    `tresourcetype_id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '0-菜单，1-功能 引用数据字典表',
    `create_time` datetime DEFAULT NULL COMMENT '创建时间',
    `create_user` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建用户',
    `update_time` datetime DEFAULT NULL COMMENT '修改时间',
    `update_user` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '修改用户',
    PRIMARY KEY (`id`),
    KEY `idx_resource_id` (`id`) USING BTREE
    ) ENGINE=InnoDB DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;

    CREATE TABLE IF NOT EXISTS  supernotedb.`b_role` (
    `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'PK(seq_trole)',
    `name` varchar(25) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '角色名称',
    `remark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '角色描述',
    `pid` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '父角色',
    `create_time` datetime DEFAULT NULL COMMENT '创建时间',
    `modify_time` datetime DEFAULT NULL COMMENT '修改时间',
    `create_user` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人员',
    `modify_user` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '修改人员',
    PRIMARY KEY (`id`) USING BTREE,
    KEY `idx_role_id` (`id`) USING BTREE
    ) ENGINE=InnoDB DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;


    CREATE TABLE IF NOT EXISTS  supernotedb.`b_role_tresource` (
    `trole_id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '角色id',
    `tresource_id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '资源id',
    PRIMARY KEY (`tresource_id`,`trole_id`) USING BTREE,
    KEY `TROLE_ID` (`trole_id`) USING BTREE,
    KEY `idx_roleresource_roldid` (`trole_id`) USING BTREE,
    KEY `idx_roleresource_resourceid` (`tresource_id`) USING BTREE
    ) ENGINE=InnoDB DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;


    CREATE TABLE IF NOT EXISTS  supernotedb.`b_schedule_log` (
    `id` int(65) NOT NULL AUTO_INCREMENT COMMENT 'seq_schedule_log',
    `ksrq` datetime DEFAULT NULL COMMENT '开始执行时间',
    `jsrq` datetime DEFAULT NULL COMMENT '结束执行时间',
    `task_id` int(65) DEFAULT NULL COMMENT '任务ID',
    `result` varchar(4) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '执行结果(0成功,1失败)',
    PRIMARY KEY (`id`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=200640 DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;

    CREATE TABLE IF NOT EXISTS  supernotedb.`b_schedule_task` (
    `id` int(65) NOT NULL AUTO_INCREMENT COMMENT '主键(seq_schedule_task)',
    `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '任务名称',
    `remark` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '任务描述',
    `cron` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '克隆表达式',
    `status` varchar(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '任务状态，0 启用，1 停用',
    `create_time` datetime DEFAULT NULL COMMENT '创建时间',
    `create_user` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人员',
    `update_time` datetime DEFAULT NULL COMMENT '修改时间',
    `update_user` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '修改人员',
    `bzcode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '业务码',
    PRIMARY KEY (`id`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;


    CREATE TABLE IF NOT EXISTS  supernotedb.`b_user` (
    `id` int(65) NOT NULL AUTO_INCREMENT COMMENT 'pk',
    `username` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '用户名',
    `name` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '姓名',
    `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '手机号码',
    `address` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '联系地址',
    `email` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '电子邮箱',
    `pwd` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '登录密码',
    `counts` int(65) DEFAULT 0 COMMENT '登录密码错误次数',
    `status` varchar(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '状态1：正常，0：锁定，2：停用',
    `is_active` varchar(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '有效标识（Y：有效，N：无效）',
    `last_login_date` datetime DEFAULT NULL COMMENT '最后一次登录时间',
    `role_id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '所属角色',
    `create_time` datetime DEFAULT NULL COMMENT '创建时间',
    `create_user` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人员',
    `update_time` datetime DEFAULT NULL COMMENT '修改时间',
    `update_user` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '修改人员',
    `modify_pwd` varchar(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '0' COMMENT '是否已经修改密码:0未修改,1已修改',
    PRIMARY KEY (`id`) USING BTREE,
    KEY `idx_user_id` (`id`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=148 DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;


    CREATE TABLE IF NOT EXISTS  supernotedb.`b_user_trole` (
    `tuser_id` int(65) NOT NULL COMMENT '用户id',
    `trole_id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '角色id',
    PRIMARY KEY (`trole_id`,`tuser_id`) USING BTREE,
    KEY `idx_roleuser_roldid` (`trole_id`) USING BTREE,
    KEY `idx_roleuser_userid` (`tuser_id`) USING BTREE
    ) ENGINE=InnoDB DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;

    CREATE TABLE IF NOT EXISTS  supernotedb.`e_equipment` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
    `equipment_number` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '设备号',
    `firmware_version` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '固件版本号',
    `update_status` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '0' COMMENT '更新状态（0 初始版本   1  未更新  2  已更新）',
    `remark` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
    `create_time` datetime NOT NULL COMMENT '创建时间',
    `update_time` datetime NOT NULL COMMENT '修改时间',
    `equipment_model` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '终端型号',
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE KEY `equipment_number_UNIQUE_Index` (`equipment_number`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=3535 DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;


    CREATE TABLE IF NOT EXISTS  supernotedb.`e_equipment_authorize` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
    `equipment_number` varchar(30) NOT NULL COMMENT '设备号',
    `authorize` text DEFAULT NULL COMMENT '授权值',
    `app_name` varchar(30) NOT NULL DEFAULT 'Dropbox' COMMENT '授权的应用名称',
    `random` varchar(10) NOT NULL COMMENT '随机数',
    `status` char(2) NOT NULL DEFAULT 'N' COMMENT '''N'' = 正在授权中；''Y'' = 已授权; ''Z'' = 超时',
    `create_time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT '授权时间',
    PRIMARY KEY (`id`)
    ) ENGINE=InnoDB AUTO_INCREMENT=3351 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


    CREATE TABLE IF NOT EXISTS  supernotedb.`e_equipment_log` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键PK',
    `equipment_number` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '设备号',
    `log_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '日志名',
    `type` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '日志类型(1：普通日志；2：错误日志）',
    `firmware_version` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '固件版本号',
    `create_time` datetime NOT NULL COMMENT '日志上传时间',
    `remark` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
    `is_download` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '0' COMMENT '是否已下载（0：未下载 1：已下载）',
    `flag` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '0' COMMENT '标识（0：未查看 1：已查看 2：已审阅）',
    `domain` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '文件服务器（cn、com）',
    PRIMARY KEY (`id`) USING BTREE,
    KEY `equipment_number_Index` (`equipment_number`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=54632 DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC COMMENT='终端日志上传数据表';

    CREATE TABLE IF NOT EXISTS  supernotedb.`e_equipment_manual` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
    `logic_version` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '逻辑版本号',
    `language` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '0' COMMENT '语言-JP、CN、HK、EN',
    `file_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '文件名称',
    `version` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '版本',
    `url` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '地址',
    `create_time` datetime NOT NULL COMMENT '创建时间',
    `md5` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'md5',
    PRIMARY KEY (`id`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=3786 DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;

    CREATE TABLE IF NOT EXISTS  supernotedb.`e_equipment_warranty` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
    `order_no` varchar(30) DEFAULT NULL COMMENT '订单号',
    `equipment_number` varchar(50) NOT NULL COMMENT '设备号',
    `warranty_start_time` datetime DEFAULT NULL COMMENT '保修起始日期',
    `warranty_end_time` datetime DEFAULT NULL COMMENT '保修截止日期',
    `type` char(2) DEFAULT NULL COMMENT '类别（0：查询物流api[DHL、sf]，1：根据发货日期推算[ems,历史数据]，2：报表导入[日亚，欧洲代理]）',
    `order_time` datetime DEFAULT NULL COMMENT '订单下单时间',
    `dealer` varchar(50) DEFAULT NULL COMMENT '渠道',
    `op_time` datetime DEFAULT NULL COMMENT '操作时间',
    `op_user` varchar(50) DEFAULT NULL COMMENT '操作人',
    PRIMARY KEY (`id`)
    ) ENGINE=InnoDB AUTO_INCREMENT=5831 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


    CREATE TABLE IF NOT EXISTS  supernotedb.`e_language` (
    `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
    `file_name` varchar(100) NOT NULL COMMENT '文件名',
    `country_code` varchar(10) NOT NULL COMMENT '国家码',
    `md5` varchar(50) NOT NULL COMMENT 'md5',
    `size` varchar(20) NOT NULL COMMENT '文件字节大小',
    PRIMARY KEY (`id`)
    ) ENGINE=InnoDB AUTO_INCREMENT=67 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


    CREATE TABLE IF NOT EXISTS  supernotedb.`e_task` (
    `task_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '任务id',
    `equipment_number` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '设备号',
    `task_code` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '任务码(01:锁设备；02:解锁设备；03:固件更新)',
    `create_time` datetime NOT NULL COMMENT '创建时间',
    PRIMARY KEY (`task_id`) USING BTREE,
    KEY `equipment_number_Index` (`equipment_number`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=175 DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;


    CREATE TABLE IF NOT EXISTS  supernotedb.`e_task_his` (
    `task_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '任务id',
    `equipment_number` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '设备号',
    `task_code` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '任务码',
    `result` char(2) NOT NULL COMMENT '执行结果（0：未执行  1：执行成功）',
    `create_time` datetime NOT NULL COMMENT '创建时间',
    PRIMARY KEY (`task_id`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=176 DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;

    CREATE TABLE IF NOT EXISTS  supernotedb.`e_temp` (
    `user_id` bigint(20) NOT NULL,
    PRIMARY KEY (`user_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

    CREATE TABLE IF NOT EXISTS  supernotedb.`e_temp_now` (
    `user_id` bigint(20) NOT NULL,
    PRIMARY KEY (`user_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

    CREATE TABLE IF NOT EXISTS  supernotedb.`e_user_equipment` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT 'PK',
    `equipment_number` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '设备编号',
    `user_id` bigint(20) unsigned NOT NULL COMMENT '用户id',
    `name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '设备名称(用户命名，方便识别)',
    `status` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Y' COMMENT '设备状态：Y正常；N锁定',
    `create_time` datetime NOT NULL COMMENT '创建时间',
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE KEY `equipment_number_user_id_UNIQUE_Index` (`equipment_number`,`user_id`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=3638 DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;


    CREATE TABLE IF NOT EXISTS  supernotedb.`e_user_equipment_record` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT 'PK',
    `equipment_number` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '' COMMENT '设备编号',
    `user_id` bigint(20) unsigned NOT NULL COMMENT '用户id',
    `type` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Y' COMMENT '类型：0绑定；1解绑, 2迁移解绑， 3登录解绑',
    `create_time` datetime NOT NULL COMMENT '操作时间',
    PRIMARY KEY (`id`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=3539 DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;


    CREATE TABLE IF NOT EXISTS  supernotedb.`f_capacity` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
    `user_id` bigint(20) unsigned NOT NULL COMMENT '用户id',
    `used_capacity` bigint(20) unsigned NOT NULL COMMENT '已用容量',
    `total_capacity` bigint(20) unsigned NOT NULL COMMENT '总容量',
    `create_time` datetime NOT NULL COMMENT '创建时间',
    `update_time` datetime NOT NULL COMMENT '更新时间',
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE KEY `user_id_UNIQUE_Index` (`user_id`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=54319 DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;

    CREATE TABLE IF NOT EXISTS  supernotedb.`f_file_action` (
    `id` bigint(20) unsigned NOT NULL COMMENT '主键',
    `user_id` bigint(20) unsigned NOT NULL COMMENT '用户id',
    `file_id` bigint(20) NOT NULL COMMENT '文件id',
    `file_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '文件名',
    `new_file_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '重命名后的文件名',
    `path` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '路径',
    `new_path` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '新路径',
    `md5` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'md5',
    `inner_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'ufile上存储名称',
    `is_folder` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Y' COMMENT '是否是文件夹;Y--是；N--不是.',
    `size` bigint(20) NOT NULL DEFAULT 0 COMMENT '文件大小',
    `action` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '操作：A（增加），D（删除），U（重命名），R（移动）',
    `create_time` datetime(3) NOT NULL COMMENT '创建时间',
    `update_time` datetime(3) NOT NULL COMMENT '修改时间',
    PRIMARY KEY (`id`) USING BTREE,
    KEY `user_id_Index` (`user_id`) USING BTREE
    ) ENGINE=InnoDB DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;


    CREATE TABLE IF NOT EXISTS  supernotedb.`f_file_convert` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'PK',
    `file_type` varchar(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '文件格式',
    `convert_type` varchar(2) NOT NULL COMMENT '转换类型(1:note转pdf;2：pdf加mark转pdf;3.note转png)',
    `file_id` bigint(20) NOT NULL COMMENT '文件id',
    `origin_inner_name` varchar(255) NOT NULL COMMENT '原文件名',
    `user_id` bigint(20) NOT NULL COMMENT '用户id',
    `page_no` int(11) DEFAULT NULL COMMENT '页码',
    `inner_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '内部文件名',
    `create_time` datetime NOT NULL COMMENT '创建时间',
    `update_time` datetime NOT NULL COMMENT '更新时间',
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE KEY `inner_name` (`inner_name`),
    UNIQUE KEY `inner_name_Index` (`inner_name`),
    KEY `file_id_Index` (`file_id`) USING BTREE,
    KEY `user_id_Index` (`user_id`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=239 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci ROW_FORMAT=DYNAMIC;

    CREATE TABLE IF NOT EXISTS  supernotedb.`f_file_his_sync` (
    `id` bigint(20) unsigned NOT NULL COMMENT 'id',
    `file_id` bigint(20) NOT NULL COMMENT '文件id',
    `user_id` bigint(20) NOT NULL COMMENT '用户id',
    `equipment_number` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '' COMMENT '设备号',
    `directory_id` bigint(20) NOT NULL COMMENT '目录id',
    `file_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '文件名称',
    `inner_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '内部文件名',
    `size` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '大小',
    `md5` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'MD5',
    `is_folder` varchar(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '' COMMENT '是否是文件夹',
    `create_time` datetime NOT NULL COMMENT '创建时间',
    `sync_time` datetime(3) NOT NULL COMMENT '同步时间',
    `terminal_file_edit_time` bigint(20) NOT NULL DEFAULT 0 COMMENT '终端文件编辑时间',
    PRIMARY KEY (`id`) USING BTREE,
    KEY `equipment_user_Index` (`equipment_number`,`user_id`) USING BTREE
    ) ENGINE=InnoDB DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;


    CREATE TABLE IF NOT EXISTS  supernotedb.`f_file_server_change` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
    `equipment_number` varchar(30) NOT NULL DEFAULT '' COMMENT '设备号',
    `user_id` bigint(20) NOT NULL COMMENT '用户id',
    `old_file_server` varchar(2) NOT NULL COMMENT '旧服务器',
    `new_file_server` varchar(2) NOT NULL COMMENT '新服务器',
    `change_time` datetime(3) NOT NULL COMMENT '迁移时间',
    `create_time` datetime(3) NOT NULL COMMENT '创建时间',
    PRIMARY KEY (`id`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=242 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;

    -- ----------------------------
    -- Table structure for f_recycle_file
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS  supernotedb.`f_recycle_file` (
    `file_id` bigint(20) unsigned NOT NULL COMMENT '文件id',
    `user_id` bigint(20) NOT NULL COMMENT '用户id',
    `file_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '文件名',
    `size` bigint(20) NOT NULL COMMENT '文件大小',
    `is_folder` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '是否是文件夹',
    `create_time` datetime NOT NULL COMMENT '最后修改时间',
    `update_time` datetime NOT NULL COMMENT '修改时间',
    PRIMARY KEY (`file_id`) USING BTREE,
    KEY `user_id_Index` (`user_id`) USING BTREE
    ) ENGINE=InnoDB DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;

    -- ----------------------------
    -- Table structure for f_share_record
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS  supernotedb.`f_share_record` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT,
    `user_id` bigint(20) NOT NULL COMMENT '分享人',
    `file_id` bigint(20) NOT NULL COMMENT '分享文件id',
    `share_way` varchar(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '分享方式',
    `create_time` datetime NOT NULL COMMENT '分享时间',
    PRIMARY KEY (`id`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;

    -- ----------------------------
    -- Table structure for f_sync_record
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS  supernotedb.`f_sync_record` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
    `success_count` bigint(20) NOT NULL COMMENT '总同步成功数',
    `fail_count` bigint(20) NOT NULL COMMENT '总同步失败数',
    `total_time` decimal(64,0) NOT NULL COMMENT '总时间',
    `create_time` datetime DEFAULT NULL COMMENT '创建时间',
    `update_time` datetime DEFAULT NULL COMMENT '更新时间',
    PRIMARY KEY (`id`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;

    -- ----------------------------
    -- Table structure for f_terminal_file_convert
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS  supernotedb.`f_terminal_file_convert` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'PK',
    `equipment_number` varchar(30) NOT NULL COMMENT '设备号',
    `file_type` varchar(2) NOT NULL COMMENT '文件格式（1：pdf；2：png）',
    `file_name` varchar(255) DEFAULT NULL COMMENT '文件名',
    `convert_type` varchar(2) NOT NULL COMMENT '转换类型(1:note转pdf;2：pdf加mark转pdf;3.note转png)',
    `share_id` bigint(20) NOT NULL COMMENT '分享id',
    `page_no` int(11) DEFAULT NULL COMMENT '页码',
    `url` text NOT NULL COMMENT '文件下载地址',
    `create_time` datetime NOT NULL COMMENT '创建时间',
    `update_time` datetime NOT NULL COMMENT '更新时间',
    PRIMARY KEY (`id`) USING BTREE,
    KEY `share_id_Index` (`share_id`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=6035 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;

    -- ----------------------------
    -- Table structure for f_terminal_share_file
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS  supernotedb.`f_terminal_share_file` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'PK',
    `equipment_number` varchar(30) NOT NULL COMMENT '设备号',
    `inner_name` varchar(50) NOT NULL COMMENT '文件内部名称',
    `file_name` varchar(255) NOT NULL COMMENT '文件名称',
    `create_time` datetime NOT NULL COMMENT '创建时间',
    `update_time` datetime NOT NULL COMMENT '更新时间',
    PRIMARY KEY (`id`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=1895 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;

    -- ----------------------------
    -- Table structure for f_user_file
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS  supernotedb.`f_user_file` (
    `id` bigint(20) unsigned NOT NULL COMMENT '主键',
    `user_id` bigint(20) NOT NULL COMMENT '用户id',
    `directory_id` bigint(20) NOT NULL COMMENT '所在目录编号',
    `file_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '文件名称',
    `inner_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'ufile上存储名称',
    `size` bigint(20) NOT NULL DEFAULT 0 COMMENT '文件大小',
    `md5` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'md5',
    `is_active` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Y' COMMENT '文件状态，Y 正常，N 已删除',
    `is_folder` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Y' COMMENT '是否是文件夹;Y--是；N--不是.',
    `create_time` datetime NOT NULL COMMENT '创建时间',
    `update_time` datetime NOT NULL COMMENT '修改时间',
    `terminal_file_edit_time` bigint(20) NOT NULL DEFAULT 0 COMMENT '终端文件编辑时间',
    PRIMARY KEY (`id`) USING BTREE,
    KEY `user_id_Index` (`user_id`) USING BTREE,
    KEY `directory_id_Index` (`directory_id`) USING BTREE,
    KEY `file_name_Index` (`file_name`(191)) USING BTREE
    ) ENGINE=InnoDB DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;

    -- ----------------------------
    -- Table structure for t_schedule_recur_task
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS  supernotedb.`t_schedule_recur_task` (
    `task_id` varchar(255) NOT NULL COMMENT '子事件任务列表Id',
    `recurrence_id` varchar(255) DEFAULT NULL COMMENT '根任务的Id(ScheduleTask)',
    `task_list_id` varchar(255) DEFAULT NULL COMMENT '任务组Id',
    `user_id` bigint(20) NOT NULL COMMENT '用户id',
    `last_modified` bigint(20) NOT NULL COMMENT '任务最后修改时间(UTC时间戳)',
    `due_time` bigint(20) DEFAULT NULL COMMENT '任务过期时间(UTC时间戳)',
    `completed_time` bigint(20) DEFAULT NULL COMMENT '任务完成时间(UTC时间戳)',
    `status` varchar(255) DEFAULT NULL COMMENT '任务状态，可以是"needsAction"或"completed"',
    `is_deleted` char(2) NOT NULL DEFAULT 'N' COMMENT '是否已经删除，Y=是，N=否，默认''N''',
    `sort` int(11) DEFAULT NULL COMMENT '在自定义组或者收集箱中未完成的编号',
    `sort_completed` int(11) DEFAULT NULL COMMENT '在自定义组或者收集箱中已完成的编号',
    `planer_sort` int(11) DEFAULT NULL COMMENT '在计划中未完成的编号',
    `all_sort` int(11) DEFAULT NULL COMMENT '在all中未完成的编号',
    `all_sort_completed` int(11) DEFAULT NULL COMMENT '在all中已完成的编号',
    `sort_time` bigint(20) DEFAULT NULL COMMENT '改变编号的时间',
    `planer_sort_time` bigint(20) DEFAULT NULL COMMENT '改变编号的时间',
    `all_sort_time` bigint(20) DEFAULT NULL COMMENT '改变编号的时间',
    PRIMARY KEY (`task_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

    -- ----------------------------
    -- Table structure for t_schedule_sort
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS  supernotedb.`t_schedule_sort` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
    `user_id` bigint(20) NOT NULL COMMENT '用户id',
    `task_list_id` varchar(255) DEFAULT NULL COMMENT '任务组id',
    `title` varchar(255) DEFAULT NULL COMMENT '任务组名称',
    `last_modify` bigint(20) DEFAULT NULL,
    `content` text NOT NULL COMMENT '排序内容',
    PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

    -- ----------------------------
    -- Table structure for t_schedule_task
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS  supernotedb.`t_schedule_task` (
    `task_id` varchar(255) NOT NULL COMMENT '任务Id',
    `task_list_id` varchar(255) DEFAULT NULL COMMENT '任务组Id',
    `user_id` bigint(20) NOT NULL COMMENT '用户id',
    `title` varchar(600) DEFAULT NULL COMMENT '标题',
    `detail` varchar(255) DEFAULT '' COMMENT '任务的详情',
    `last_modified` bigint(20) DEFAULT NULL COMMENT '任务最后修改时间(UTC时间戳)',
    `recurrence` varchar(255) DEFAULT '' COMMENT '任务的重复规则遵循RFC5545重复规则标准',
    `is_reminder_on` char(2) NOT NULL DEFAULT 'N' COMMENT '是否需要提醒，Y=需要，N=不需要',
    `status` varchar(255) DEFAULT '' COMMENT '任务的状态，可以是"needsAction"或"completed"',
    `importance` varchar(255) DEFAULT '' COMMENT '任务的重要等级',
    `due_time` bigint(20) NOT NULL COMMENT '任务过期时间(UTC时间戳)',
    `completed_time` bigint(20) DEFAULT NULL COMMENT '任务完成时间(UTC时间戳)',
    `links` varchar(5000) DEFAULT NULL COMMENT '任务的链接属性',
    `is_deleted` char(2) NOT NULL DEFAULT 'N' COMMENT '是否已经删除，Y=是，N=否，默认''N''',
    `sort` int(11) DEFAULT NULL COMMENT '在自定义组或者收集箱中未完成的编号',
    `sort_completed` int(11) DEFAULT NULL COMMENT '在自定义组或者收集箱中已完成的编号',
    `planer_sort` int(11) DEFAULT NULL COMMENT '在计划中未完成的编号',
    `all_sort` int(11) DEFAULT NULL COMMENT '在all中未完成的编号',
    `all_sort_completed` int(11) DEFAULT NULL COMMENT '在all中已完成的编号',
    `sort_time` bigint(20) DEFAULT NULL COMMENT '改变编号的时间',
    `planer_sort_time` bigint(20) DEFAULT NULL COMMENT '改变编号的时间',
    `all_sort_time` bigint(20) DEFAULT NULL COMMENT '改变编号的时间',
    PRIMARY KEY (`task_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

    -- ----------------------------
    -- Table structure for t_schedule_task_group
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS  supernotedb.`t_schedule_task_group` (
    `task_list_id` varchar(255) NOT NULL COMMENT '任务组Id',
    `user_id` bigint(20) NOT NULL COMMENT '用户Id',
    `title` varchar(255) NOT NULL COMMENT '任务组名称',
    `last_modified` bigint(20) NOT NULL COMMENT '任务组的最后修改时间，仅随title 变动',
    `is_deleted` char(2) NOT NULL DEFAULT 'N' COMMENT '是否已经删除，Y=是，N=否，默认''N''',
    `create_time` bigint(20) DEFAULT NULL COMMENT '任务列表的创建时间',
    PRIMARY KEY (`task_list_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

    -- ----------------------------
    -- Table structure for t_summary
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS  supernotedb.`t_summary` (
    `id` bigint(20) unsigned NOT NULL COMMENT '主键ID',
    `file_id` bigint(20) DEFAULT NULL COMMENT '文件ID',
    `name` varchar(255) DEFAULT NULL COMMENT '摘要库名称',
    `user_id` bigint(20) unsigned NOT NULL COMMENT '关联用户ID',
    `author` varchar(200) DEFAULT NULL COMMENT '作者',
    `unique_identifier` char(50) DEFAULT NULL COMMENT '唯一标识（UUID）',
    `parent_unique_identifier` char(50) DEFAULT NULL COMMENT '父级唯一标识',
    `content` text DEFAULT NULL COMMENT '知识点内容',
    `source_path` varchar(1000) DEFAULT NULL COMMENT '来源路径',
    `data_source` varchar(100) DEFAULT NULL COMMENT '数据来源',
    `source_type` int(11) DEFAULT NULL COMMENT '来源类型',
    `is_summary_group` char(2) NOT NULL DEFAULT 'N' COMMENT '是否摘要组库:Y=是，N=否',
    `description` varchar(255) DEFAULT NULL COMMENT '知识库描述',
    `tags` varchar(255) DEFAULT NULL COMMENT '标签：多个标签使用逗号分割',
    `md5_hash` char(32) NOT NULL COMMENT '数据MD5校验值',
    `metadata` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '元数据（JSON格式）',
    `comment_str` varchar(2000) DEFAULT NULL COMMENT '注释-文字',
    `comment_handwrite_name` varchar(100) DEFAULT NULL COMMENT '注释-手写文件的名称，保存在终端本地的名称',
    `handwrite_inner_name` varchar(100) DEFAULT NULL COMMENT '手写文件的innerName，用于直接方便下载文件',
    `creation_time` bigint(20) NOT NULL COMMENT '摘要创建时间（毫秒级时间戳）',
    `last_modified_time` bigint(20) NOT NULL COMMENT '摘要最后修改时间（毫秒级时间戳）',
    `is_deleted` char(1) NOT NULL DEFAULT 'N' COMMENT '是否已经被删除:Y=是，N=否',
    `create_time` datetime NOT NULL COMMENT '创建时间',
    `update_time` datetime NOT NULL COMMENT '修改时间',
    `handwrite_md5` char(32) DEFAULT NULL COMMENT '手写文件MD5',
    PRIMARY KEY (`id`),
    KEY `idx_user` (`user_id`),
    KEY `idx_name` (`name`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='摘要信息表';

    -- ----------------------------
    -- Table structure for t_summary_tag
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS  supernotedb.`t_summary_tag` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '自增主键，唯一标识每一条记录',
    `name` varchar(255) NOT NULL COMMENT '标签的名字，不允许为空',
    `user_id` bigint(20) NOT NULL COMMENT '与该标签相关联的用户ID，指向用户表中的记录',
    `created_at` datetime NOT NULL COMMENT '记录创建的时间，默认值为当前时间戳',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='存储标签信息的表';

    -- ----------------------------
    -- Table structure for u_commonly_area
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS  supernotedb.`u_commonly_area` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT 'PK',
    `user_id` bigint(20) unsigned NOT NULL COMMENT '用户ID',
    `country_code` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '国家编号',
    `area_code` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '行政编号',
    `count` int(11) NOT NULL DEFAULT 1 COMMENT '登录次数',
    `create_time` datetime NOT NULL COMMENT '创建时间',
    `update_time` datetime NOT NULL COMMENT '修改时间',
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE KEY `unique_uid_acode` (`user_id`,`area_code`) USING BTREE COMMENT '组合唯一约束（用户id和城市编码）',
    KEY `user_id_Index` (`user_id`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=1909 DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;

    -- ----------------------------
    -- Table structure for u_commonly_equipment
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS  supernotedb.`u_commonly_equipment` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT 'PK',
    `user_id` bigint(20) unsigned NOT NULL COMMENT '用户ID',
    `equipment_number` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '常用设备',
    `create_time` datetime NOT NULL COMMENT '创建时间',
    `update_time` datetime NOT NULL COMMENT '修改时间',
    PRIMARY KEY (`id`) USING BTREE,
    KEY `user_id_Index` (`user_id`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;

    -- ----------------------------
    -- Table structure for u_data_migration_record
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS  supernotedb.`u_data_migration_record` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
    `user_id` bigint(20) DEFAULT NULL COMMENT '用户ID',
    `equipment_number` varchar(30) NOT NULL COMMENT '设备号',
    `country_code` varchar(5) DEFAULT NULL COMMENT '国家码',
    `telephone` varchar(20) DEFAULT NULL COMMENT '手机号',
    `email` varchar(30) DEFAULT NULL COMMENT '电子邮箱',
    `count` int(2) NOT NULL COMMENT '迁移次数',
    `state` char(2) NOT NULL COMMENT '迁移状态（0：迁移中；1：迁移成功；2：迁移失败）',
    `create_time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT '第一次迁移时间',
    `update_time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT '最后一次迁移时间',
    PRIMARY KEY (`id`)
    ) ENGINE=InnoDB AUTO_INCREMENT=69 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

    -- ----------------------------
    -- Table structure for u_email_config
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS  supernotedb.`u_email_config` (
    `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
    `smtp_server` varchar(70) NOT NULL COMMENT '服务器地址',
    `port` varchar(10) NOT NULL COMMENT '端口',
    `user_name` varchar(70) NOT NULL COMMENT '服务器邮箱',
    `password` varchar(255) NOT NULL COMMENT '服务器密码',
    `encryption` varchar(15) NOT NULL DEFAULT '' COMMENT '加密方式 SSL、TLS',
    `flag` char(2) NOT NULL DEFAULT 'Y' COMMENT 'Y：正常，N：不可用',
    `test_email` varchar(70) DEFAULT '' COMMENT '测试接收邮箱',
    `update_time` datetime DEFAULT NULL ON UPDATE current_timestamp() COMMENT '修改时间',
    PRIMARY KEY (`id`)
    ) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

    -- ----------------------------
    -- Table structure for u_login_record
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS  supernotedb.`u_login_record` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT,
    `user_id` bigint(20) NOT NULL COMMENT '用户id',
    `login_method` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '2' COMMENT '登录方式（1手机号，2邮箱，3微信）',
    `ip` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'ip地址',
    `browser` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '浏览器名称',
    `equipment` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '1' COMMENT '设备（1 网页端云盘；2 APP; 3 主账户；4终端）',
    `create_time` datetime NOT NULL COMMENT '创建时间',
    `update_time` datetime NOT NULL COMMENT '修改时间',
    PRIMARY KEY (`id`) USING BTREE,
    KEY `user_id_Index` (`user_id`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=20716 DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;

    -- ----------------------------
    -- Table structure for u_sensitive_record
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS  supernotedb.`u_sensitive_record` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT 'id',
    `user_id` bigint(20) NOT NULL COMMENT '用户id',
    `operate_record` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '操作记录(01：找回密码，02：修改密码，03：修改手机号，04：修改邮箱，05锁定设备，06解锁设备，07异地登录)',
    `ip` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'ip',
    `create_time` datetime NOT NULL DEFAULT '1970-01-01 00:00:00' ON UPDATE current_timestamp() COMMENT '创建时间',
    `update_time` datetime NOT NULL DEFAULT '1970-01-01 00:00:00' ON UPDATE current_timestamp() COMMENT '修改时间',
    PRIMARY KEY (`id`) USING BTREE,
    KEY `user_id_Index` (`user_id`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=1547648583513014673 DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;

    -- ----------------------------
    -- Table structure for u_user
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS  supernotedb.`u_user` (
    `user_id` bigint(20) unsigned NOT NULL DEFAULT 0 COMMENT 'id',
    `user_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '昵称',
    `email` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '电子邮箱',
    `sex` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '1' COMMENT '性别；1：男。2：女',
    `birthday` varchar(24) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '' COMMENT '生日',
    `personal_sign` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '个性签名',
    `hobby` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '兴趣爱好',
    `education` varchar(24) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '教育程度',
    `job` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '职业',
    `avatars_url` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '头像URL',
    `address` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '地址',
    `password` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '密码',
    `create_time` datetime NOT NULL COMMENT '创建时间',
    `update_time` datetime NOT NULL COMMENT '最后修改时间',
    `is_normal` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Y' COMMENT '用户状态，Y 正常，N 冻结',
    `file_server` char(2) DEFAULT '' COMMENT '文件服务器标识：0 ufile；1 aws;2US 3；欧洲',
    `avatars_position` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '头像位置',
    `account_status` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'N' COMMENT '账号同步状态，N：未同步，Y：已同步',
    PRIMARY KEY (`user_id`) USING BTREE,
    UNIQUE KEY `email_Index` (`email`) USING BTREE
    ) ENGINE=InnoDB DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;

    -- ----------------------------
    -- Table structure for u_user_history
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS supernotedb.`u_user_history` (
    `user_id` bigint(20) unsigned NOT NULL DEFAULT 0 COMMENT 'id',
    `user_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '昵称',
    `country_code` varchar(5) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '86' COMMENT '国家码',
    `telephone` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '手机号',
    `email` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '' COMMENT '电子邮箱',
    `wechat_no` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '微信号',
    `sex` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '1' COMMENT '性别；1：男。2：女',
    `birthday` varchar(24) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '' COMMENT '生日',
    `personal_sign` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '个性签名',
    `hobby` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '兴趣爱好',
    `education` varchar(24) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '教育程度',
    `job` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '职业',
    `avatars_url` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '头像URL',
    `avatars_position` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '头像位置',
    `address` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '地址',
    `password` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '密码',
    `create_time` datetime NOT NULL COMMENT '创建时间',
    `update_time` datetime NOT NULL COMMENT '最后修改时间',
    `is_normal` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Y' COMMENT '用户状态，Y 正常，N 冻结',
    `file_server` char(2) DEFAULT NULL COMMENT '文件服务器标识：0 ufile；1 aws',
    PRIMARY KEY (`user_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci;

    -- ----------------------------
    -- Table structure for u_user_sold_out
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS  supernotedb.`u_user_sold_out` (
    `user_id` bigint(20) unsigned NOT NULL DEFAULT 0 COMMENT 'id',
    `country_code` varchar(5) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '86' COMMENT '国家码',
    `telephone` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '手机号',
    `email` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '电子邮箱',
    `wechat_no` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '微信号',
    `create_time` datetime NOT NULL COMMENT '创建时间'
    ) ENGINE=InnoDB DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;

    -- ----------------------------
    -- Table structure for t_machine_id
    -- ----------------------------
    CREATE TABLE IF NOT EXISTS  supernotedb.`t_machine_id` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `unique_machine_id` varchar(255) NOT NULL COMMENT '唯一机器码',
    PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=gbk COLLATE=gbk_chinese_ci ROW_FORMAT=DYNAMIC;


    -- ----------------------------
    -- 添加基础参数
    -- ----------------------------
    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('01', 'MAX_ERR_COUNTS', '6', '错6次锁定用户', 'hqq', '2018-05-08 15:06:33', '0');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('01', 'UPLOAD_MAX', '500', '单次允许最大上传的文件个数', 'lvmi', '2021-06-04 12:34:26', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('01', 'COPY_MAX', '1000', '单次允许最大复制的文件个数', 'lvmi', '2021-06-04 12:34:23', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('01', 'FILE_TYPE', 'jpg', 'image/jpeg', 'lvmi', '2022-06-24 14:40:37', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('02', 'FILE_TYPE', 'png', 'image/png', 'lvmi', '2022-06-24 14:40:46', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('03', 'FILE_TYPE', 'gif', 'image/gif', 'lvmi', '2022-06-24 14:40:52', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('04', 'FILE_TYPE', 'bmp', 'image/bmp', 'lvmi', '2022-06-24 14:41:02', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('05', 'FILE_TYPE', 'jpeg', 'image/jpeg', 'lvmi', '2022-06-24 14:46:52', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('06', 'FILE_TYPE', 'psd', 'application/octet-stream', 'lvmi', '2022-06-24 14:46:57', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('07', 'FILE_TYPE', 'tga', 'application/octet-stream', 'lvmi', '2022-06-24 14:40:57', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('08', 'FILE_TYPE', 'tif', 'image/tiff', 'lvmi', '2022-06-24 14:47:02', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('09', 'FILE_TYPE', 'ppt', 'application/octet-stream', 'lvmi', '2022-06-24 14:47:14', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('10', 'FILE_TYPE', 'doc', 'application/octet-stream', 'lvmi', '2022-06-24 14:47:32', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('11', 'FILE_TYPE', 'txt', 'text/plain', 'lvmi', '2021-06-04 12:33:29', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('12', 'FILE_TYPE', 'xls', 'application/octet-stream', 'lvmi', '2021-06-04 12:33:26', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('13', 'FILE_TYPE', 'pdf', 'application/pdf', 'lvmi', '2022-06-24 14:47:09', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('14', 'FILE_TYPE', 'chm', 'application/octet-stream', 'lvmi', '2021-06-04 12:33:10', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('15', 'FILE_TYPE', 'rtf', 'application/octet-stream', 'lvmi', '2021-06-04 12:33:06', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('16', 'FILE_TYPE', 'pptx', 'application/octet-stream', 'lvmi', '2021-06-04 12:33:02', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('17', 'FILE_TYPE', 'docx', 'application/octet-stream', 'lvmi', '2021-06-04 12:32:57', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('18', 'FILE_TYPE', 'xlsx', 'application/octet-stream', 'lvmi', '2021-06-04 12:32:54', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('01', 'FILE_MAX', '1073741824', '上传文件最大1G', 'hqq', '2018-09-22 22:24:11', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('19', 'FILE_TYPE', 'zip', 'application/x-zip-compressed', 'lvmi', '2021-06-04 12:32:50', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('20', 'FILE_TYPE', 'rar', 'application/octet-stream', 'lvmi', '2021-06-04 12:32:47', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('21', 'FILE_TYPE', 'apk', 'application/vnd.android.package-archive', 'lvmi', '2021-06-04 12:32:40', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('22', 'FILE_TYPE', 'gz', 'application/x-gzip', 'lvmi', '2021-06-04 12:32:44', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('23', 'FILE_TYPE', 'tar.gz', 'application/octet-stream', 'lvmi', '2021-06-04 12:31:30', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('24', 'FILE_TYPE', 'zz', 'application/octet-stream', 'lvmi', '2021-06-04 12:32:31', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('25', 'FILE_TYPE', 'epub', 'application/epub+zip', 'lvmi', '2021-06-04 12:31:48', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('26', 'FILE_TYPE', 'read', 'application/octet-stream', 'lvmi', '2021-06-04 12:31:44', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('27', 'FILE_TYPE', 'note', 'application/octet-stream', 'lvmi', '2021-06-04 12:31:40', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('28', 'FILE_TYPE', 'mark', 'application/octet-stream', 'lvmi', '2021-06-04 12:30:07', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('01', 'DOWNLOAD_MAX_NUMBER', '50', '下载最大条数', 'lvmi', '2021-06-04 12:30:04', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('29', 'FILE_TYPE', 'ttf', 'application/octet-stream', 'lvmi', '2021-03-03 17:37:58', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('30', 'FILE_TYPE', 'otf', 'application/octet-stream', 'lvmi', '2021-03-03 17:37:53', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('31', 'FILE_TYPE', 'ttc', 'application/octet-stream', 'lvmi', '2021-03-03 17:37:49', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('32', 'FILE_TYPE', 'eot', 'application/octet-stream', 'lvmi', '2021-03-03 17:37:37', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('33', 'FILE_TYPE', 'woff', 'application/octet-stream', 'lvmi', '2021-03-03 17:37:42', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('34', 'FILE_TYPE', 'dfont', 'application/octet-stream', 'lvmi', '2021-03-03 17:37:46', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('35', 'FILE_TYPE', 'xps', 'application/octet-stream', 'jiangqilin', '2024-02-28 14:16:23', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('36', 'FILE_TYPE', 'fb2', 'application/octet-stream', 'jiangqilin', '2024-02-28 14:15:42', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('37', 'FILE_TYPE', 'cbz', 'application/octet-stream', 'jiangqilin', '2024-02-28 14:16:47', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('38', 'FILE_TYPE', 'spd', 'application/octet-stream', 'lvmi', '2022-06-24 14:39:54', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('39', 'FILE_TYPE', 'webp', 'image/webp', 'page', '2023-07-06 16:21:21', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('41', 'FILE_TYPE', 'snbak', 'application/octet-stream', 'admin', '2024-05-21 15:57:40', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('42', 'FILE_TYPE', 'snstk', 'application/octet-stream', 'admin', '2025-04-01 09:42:49', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('1', 'EMAIL_CODE_TIME', '5', '5', 'admin', '2025-06-24 16:38:18', '1');

    INSERT IGNORE INTO supernotedb.`b_reference` (`serial`, `name`, `value`, `value_cn`, `op_user`, `op_time`, `remark`
    )VALUES ('01', 'EMAIL_CODE_TIME', '5', '5', 'admin', '2025-06-24 16:38:18', '1');

    -- ----------------------------
    -- 删除回收站文件数据
    -- ----------------------------
    TRUNCATE TABLE supernotedb.f_recycle_file;
    DELETE FROM supernotedb.f_user_file WHERE is_active='N';

    -- ----------------------------
    -- 删除转换表文件数据
    -- ----------------------------
    TRUNCATE TABLE supernotedb.f_file_convert;


EOSQL

    bashio::log.info "Database initialized successfully"
else
    bashio::log.info "Database already exists, skipping initialization"
fi
