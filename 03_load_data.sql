-- =====================================================
-- MySQL版本 - 数据导入脚本
-- 文件: 03_load_data.sql
-- 功能: 从TBL文件导入数据到TPC-H表中
-- =====================================================

USE TPC_H;

-- =====================================================
-- 数据文件路径配置
-- =====================================================
-- 数据文件路径已固定为: D:/data/

-- 设置MySQL参数以优化数据导入
SET SESSION sql_mode = '';
SET SESSION foreign_key_checks = 0;
SET SESSION unique_checks = 0;
SET SESSION autocommit = 0;

-- 数据导入说明:
-- MySQL使用LOAD DATA INFILE替代SQL Server的BULK INSERT
-- 数据文件已固定为: D:/data/目录下的.tbl文件
-- 文件必须放置在MySQL可访问的目录中

-- =====================================================
-- 数据导入操作 - 使用固定路径
-- =====================================================

-- 开始事务
START TRANSACTION;

-- 导入REGION表
LOAD DATA INFILE 'D:/data/region.tbl'
INTO TABLE REGION
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\n'
(R_REGIONKEY, R_NAME, R_COMMENT, @dummy);

-- 导入NATION表
LOAD DATA INFILE 'D:/data/nation.tbl'
INTO TABLE NATION
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\n'
(N_NATIONKEY, N_NAME, N_REGIONKEY, N_COMMENT, @dummy);

-- 导入PART表
LOAD DATA INFILE 'D:/data/part.tbl'
INTO TABLE PART
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\n'
(P_PARTKEY, P_NAME, P_MFGR, P_BRAND, P_TYPE, P_SIZE, P_CONTAINER, P_RETAILPRICE, P_COMMENT, @dummy);

-- 导入SUPPLIER表
LOAD DATA INFILE 'D:/data/supplier.tbl'
INTO TABLE SUPPLIER
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\n'
(S_SUPPKEY, S_NAME, S_ADDRESS, S_NATIONKEY, S_PHONE, S_ACCTBAL, S_COMMENT, @dummy);

-- 导入PARTSUPP表
LOAD DATA INFILE 'D:/data/partsupp.tbl'
INTO TABLE PARTSUPP
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\n'
(PS_PARTKEY, PS_SUPPKEY, PS_AVAILQTY, PS_SUPPLYCOST, PS_COMMENT, @dummy);

-- 导入CUSTOMER表
LOAD DATA INFILE 'D:/data/customer.tbl'
INTO TABLE CUSTOMER
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\n'
(C_CUSTKEY, C_NAME, C_ADDRESS, C_NATIONKEY, C_PHONE, C_ACCTBAL, C_MKTSEGMENT, C_COMMENT, @dummy);

-- 导入ORDERS表
LOAD DATA INFILE 'D:/data/orders.tbl'
INTO TABLE ORDERS
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\n'
(O_ORDERKEY, O_CUSTKEY, O_ORDERSTATUS, O_TOTALPRICE, O_ORDERDATE, O_ORDERPRIORITY, O_CLERK, O_SHIPPRIORITY, O_COMMENT, @dummy);

-- 导入LINEITEM表
LOAD DATA INFILE 'D:/data/lineitem.tbl'
INTO TABLE LINEITEM
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\n'
(L_ORDERKEY, L_PARTKEY, L_SUPPKEY, L_LINENUMBER, L_QUANTITY, L_EXTENDEDPRICE, L_DISCOUNT, L_TAX, L_RETURNFLAG, L_LINESTATUS, L_SHIPDATE, L_COMMITDATE, L_RECEIPTDATE, L_SHIPINSTRUCT, L_SHIPMODE, L_COMMENT, @dummy);

-- 提交事务
COMMIT;

-- 恢复MySQL参数
SET SESSION foreign_key_checks = 1;
SET SESSION unique_checks = 1;
SET SESSION autocommit = 1;
