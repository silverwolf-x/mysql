-- =====================================================
-- MySQL版本 - 数据库创建和基本设置
-- 文件: 01_database_setup.sql
-- 功能: 创建TPC-H相关数据库和基础配置
-- =====================================================

-- 设置MySQL参数以支持大数据导入
SET SESSION sql_mode = '';
SET SESSION foreign_key_checks = 0;
SET SESSION unique_checks = 0;
SET SESSION autocommit = 0;

-- 创建TPC-H数据库
DROP DATABASE IF EXISTS TPC_H;
CREATE DATABASE TPC_H CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE TPC_H;

-- 创建SSB数据库（Star Schema Benchmark）
-- DROP DATABASE IF EXISTS ssb;
-- CREATE DATABASE ssb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 创建TPCH_001数据库用于PowerBI应用
-- DROP DATABASE IF EXISTS TPCH_001;
-- CREATE DATABASE TPCH_001 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

COMMIT;
