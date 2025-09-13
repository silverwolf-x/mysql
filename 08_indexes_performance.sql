-- =====================================================
-- MySQL版本 - 索引和性能优化
-- 文件: 08_indexes_performance.sql
-- 功能: 创建索引、性能优化和存储引擎配置
-- =====================================================

USE TPC_H;

-- =====================================================
-- 创建性能优化索引
-- =====================================================

-- 为LINEITEM表创建常用查询索引
CREATE INDEX idx_lineitem_shipdate ON LINEITEM(L_SHIPDATE);
CREATE INDEX idx_lineitem_orderkey ON LINEITEM(L_ORDERKEY);
CREATE INDEX idx_lineitem_partkey ON LINEITEM(L_PARTKEY);
CREATE INDEX idx_lineitem_suppkey ON LINEITEM(L_SUPPKEY);
CREATE INDEX idx_lineitem_returnflag_linestatus ON LINEITEM(L_RETURNFLAG, L_LINESTATUS);
CREATE INDEX idx_lineitem_quantity ON LINEITEM(L_QUANTITY);
CREATE INDEX idx_lineitem_discount ON LINEITEM(L_DISCOUNT);

-- 为ORDERS表创建索引
CREATE INDEX idx_orders_custkey ON ORDERS(O_CUSTKEY);
CREATE INDEX idx_orders_orderdate ON ORDERS(O_ORDERDATE);
CREATE INDEX idx_orders_orderpriority ON ORDERS(O_ORDERPRIORITY);

-- 为CUSTOMER表创建索引
CREATE INDEX idx_customer_nationkey ON CUSTOMER(C_NATIONKEY);
CREATE INDEX idx_customer_mktsegment ON CUSTOMER(C_MKTSEGMENT);

-- 为SUPPLIER表创建索引
CREATE INDEX idx_supplier_nationkey ON SUPPLIER(S_NATIONKEY);
CREATE INDEX idx_supplier_name ON SUPPLIER(S_NAME);

-- 为PART表创建索引
CREATE INDEX idx_part_size ON PART(P_SIZE);
CREATE INDEX idx_part_type ON PART(P_TYPE);
CREATE INDEX idx_part_brand ON PART(P_BRAND);
CREATE INDEX idx_part_container ON PART(P_CONTAINER);

-- 为PARTSUPP表创建索引
CREATE INDEX idx_partsupp_partkey ON PARTSUPP(PS_PARTKEY);
CREATE INDEX idx_partsupp_suppkey ON PARTSUPP(PS_SUPPKEY);
CREATE INDEX idx_partsupp_supplycost ON PARTSUPP(PS_SUPPLYCOST);

-- 为NATION表创建索引
CREATE INDEX idx_nation_regionkey ON NATION(N_REGIONKEY);
CREATE INDEX idx_nation_name ON NATION(N_NAME);

-- 为REGION表创建索引
CREATE INDEX idx_region_name ON REGION(R_NAME);

-- =====================================================
-- 复合索引优化
-- =====================================================

-- 为TPC-H Query 1优化的复合索引
CREATE INDEX idx_lineitem_q1 ON LINEITEM(L_SHIPDATE, L_RETURNFLAG, L_LINESTATUS);

-- 为TPC-H Query 6优化的复合索引
CREATE INDEX idx_lineitem_q6 ON LINEITEM(L_SHIPDATE, L_DISCOUNT, L_QUANTITY);

-- 为JOIN操作优化的复合索引
CREATE INDEX idx_lineitem_joins ON LINEITEM(L_ORDERKEY, L_PARTKEY, L_SUPPKEY);

-- 为日期范围查询优化
CREATE INDEX idx_orders_date_priority ON ORDERS(O_ORDERDATE, O_ORDERPRIORITY);

-- =====================================================
-- 查看索引信息
-- =====================================================

-- 显示所有表的索引信息
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME,
    SEQ_IN_INDEX,
    INDEX_TYPE
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'TPC_H'
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

-- 显示索引大小统计
SELECT 
    TABLE_NAME,
    COUNT(*) as index_count,
    ROUND(SUM(stat.data_length)/1024/1024, 2) as 'Data Size (MB)',
    ROUND(SUM(stat.index_length)/1024/1024, 2) as 'Index Size (MB)'
FROM information_schema.TABLES stat
WHERE stat.TABLE_SCHEMA = 'TPC_H'
GROUP BY TABLE_NAME
ORDER BY index_count DESC;

-- =====================================================
-- 内存表示例（使用MEMORY引擎）
-- =====================================================

-- 创建内存版本的LINEITEM表（小数据集测试用）
DROP TABLE IF EXISTS LINEITEM_MEMORY;
CREATE TABLE LINEITEM_MEMORY (
    L_ORDERKEY INT NOT NULL,
    L_PARTKEY INT NOT NULL,
    L_SUPPKEY INT NOT NULL,
    L_LINENUMBER INT NOT NULL,
    L_QUANTITY DECIMAL(10,2) NOT NULL,
    L_EXTENDEDPRICE DECIMAL(10,2) NOT NULL,
    L_DISCOUNT FLOAT NOT NULL,
    L_TAX FLOAT NOT NULL,
    L_RETURNFLAG CHAR(1) NOT NULL,
    L_LINESTATUS CHAR(1) NOT NULL,
    L_SHIPDATE DATE NOT NULL,
    L_COMMITDATE DATE NOT NULL,
    L_RECEIPTDATE DATE NOT NULL,
    L_SHIPINSTRUCT CHAR(25) NOT NULL,
    L_SHIPMODE CHAR(10) NOT NULL,
    L_COMMENT VARCHAR(44) NOT NULL,
    PRIMARY KEY (L_ORDERKEY, L_LINENUMBER),
    INDEX idx_mem_shipdate (L_SHIPDATE),
    INDEX idx_mem_returnflag_linestatus (L_RETURNFLAG, L_LINESTATUS)
) ENGINE=MEMORY;

-- 插入部分数据到内存表进行测试
INSERT INTO LINEITEM_MEMORY 
SELECT * FROM LINEITEM 
WHERE L_SHIPDATE >= '1998-01-01'
LIMIT 10000;

-- =====================================================
-- 性能测试查询
-- =====================================================

-- 测试索引效果的查询
-- 查询1：使用索引的日期范围查询
EXPLAIN SELECT COUNT(*) 
FROM LINEITEM 
WHERE L_SHIPDATE BETWEEN '1995-01-01' AND '1995-12-31';

-- 查询2：使用复合索引的查询
EXPLAIN SELECT 
    L_RETURNFLAG,
    L_LINESTATUS,
    COUNT(*)
FROM LINEITEM 
WHERE L_SHIPDATE <= '1998-09-01'
GROUP BY L_RETURNFLAG, L_LINESTATUS;

-- 查询3：JOIN查询索引使用
EXPLAIN SELECT COUNT(*)
FROM ORDERS o
JOIN LINEITEM l ON o.O_ORDERKEY = l.L_ORDERKEY
WHERE o.O_ORDERDATE >= '1995-01-01';

-- =====================================================
-- 性能优化配置
-- =====================================================

-- 显示当前MySQL配置（只读查询）
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';
SHOW VARIABLES LIKE 'query_cache%';
SHOW VARIABLES LIKE 'tmp_table_size';
SHOW VARIABLES LIKE 'max_heap_table_size';

-- 显示MySQL状态信息
SHOW STATUS LIKE 'Innodb_buffer_pool%';
SHOW STATUS LIKE 'Qcache%';

-- =====================================================
-- 表分析和优化
-- =====================================================

-- 分析表以更新统计信息
ANALYZE TABLE REGION;
ANALYZE TABLE NATION;
ANALYZE TABLE PART;
ANALYZE TABLE SUPPLIER;
ANALYZE TABLE PARTSUPP;
ANALYZE TABLE CUSTOMER;
ANALYZE TABLE ORDERS;
ANALYZE TABLE LINEITEM;

-- 优化表（重建索引）
OPTIMIZE TABLE REGION;
OPTIMIZE TABLE NATION;
OPTIMIZE TABLE PART;
OPTIMIZE TABLE SUPPLIER;
OPTIMIZE TABLE PARTSUPP;
OPTIMIZE TABLE CUSTOMER;
OPTIMIZE TABLE ORDERS;
OPTIMIZE TABLE LINEITEM;

-- =====================================================
-- 查询性能对比
-- =====================================================

-- 性能测试：磁盘表 vs 内存表
SELECT '=== Disk Table Performance Test ===' as test_info;

SELECT SQL_NO_CACHE
    L_RETURNFLAG,
    L_LINESTATUS,
    SUM(L_QUANTITY) AS sum_qty,
    AVG(L_EXTENDEDPRICE) AS avg_price,
    COUNT(*) AS count_order
FROM LINEITEM
WHERE L_SHIPDATE <= '1998-12-01'
GROUP BY L_RETURNFLAG, L_LINESTATUS;

SELECT '=== Memory Table Performance Test ===' as test_info;

SELECT SQL_NO_CACHE
    L_RETURNFLAG,
    L_LINESTATUS,
    SUM(L_QUANTITY) AS sum_qty,
    AVG(L_EXTENDEDPRICE) AS avg_price,
    COUNT(*) AS count_order
FROM LINEITEM_MEMORY
WHERE L_SHIPDATE <= '1998-12-01'
GROUP BY L_RETURNFLAG, L_LINESTATUS;

-- =====================================================
-- 清理和维护
-- =====================================================

-- 显示索引使用情况统计
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    INDEX_NAME,
    CARDINALITY
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'TPC_H'
  AND CARDINALITY > 0
ORDER BY CARDINALITY DESC;

-- 检查表空间使用情况
SELECT 
    TABLE_NAME,
    ROUND(DATA_LENGTH/1024/1024, 2) as 'Data Size (MB)',
    ROUND(INDEX_LENGTH/1024/1024, 2) as 'Index Size (MB)',
    ROUND((DATA_LENGTH + INDEX_LENGTH)/1024/1024, 2) as 'Total Size (MB)',
    TABLE_ROWS
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'TPC_H'
ORDER BY (DATA_LENGTH + INDEX_LENGTH) DESC;
