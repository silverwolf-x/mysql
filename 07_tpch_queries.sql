-- =====================================================
-- MySQL版本 - TPC-H标准查询
-- 文件: 07_tpch_queries.sql
-- 功能: TPC-H基准测试标准查询（Q1, Q2, Q6等）
-- =====================================================

USE TPC_H;

-- =====================================================
-- TPC-H Query 1 - 价格汇总报告查询
-- =====================================================
-- 功能：根据发货日期过滤，按退货状态和行状态分组统计

SELECT
    L_RETURNFLAG,
    L_LINESTATUS,
    SUM(L_QUANTITY) AS sum_qty,
    SUM(L_EXTENDEDPRICE) AS sum_base_price,
    SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
    SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
    AVG(L_QUANTITY) AS avg_qty,
    AVG(L_EXTENDEDPRICE) AS avg_price,
    AVG(L_DISCOUNT) AS avg_disc,
    COUNT(*) AS count_order
FROM LINEITEM
WHERE L_SHIPDATE <= DATE_SUB('1998-12-01', INTERVAL 90 DAY)
GROUP BY L_RETURNFLAG, L_LINESTATUS
ORDER BY L_RETURNFLAG, L_LINESTATUS;

-- =====================================================
-- TPC-H Query 6 - 预测收入变化查询
-- =====================================================
-- 功能：计算在特定条件下的潜在收入

SELECT SUM(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM LINEITEM
WHERE L_SHIPDATE >= '1994-01-01'
  AND L_SHIPDATE < DATE_ADD('1994-01-01', INTERVAL 1 YEAR)
  AND L_DISCOUNT BETWEEN 0.05 AND 0.07
  AND L_QUANTITY < 24;

-- =====================================================
-- TPC-H Query 2 - 最小成本供应商查询
-- =====================================================
-- 功能：找到能以最低成本供应特定零件的供应商

SELECT 
    S_ACCTBAL,
    S_NAME,
    N_NAME,
    P_PARTKEY,
    P_MFGR,
    S_ADDRESS,
    S_PHONE,
    S_COMMENT
FROM PART, SUPPLIER, PARTSUPP, NATION, REGION
WHERE P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 15
  AND P_TYPE LIKE '%BRASS'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'EUROPE'
  AND PS_SUPPLYCOST = (
      SELECT MIN(PS_SUPPLYCOST)
      FROM PARTSUPP, SUPPLIER, NATION, REGION
      WHERE P_PARTKEY = PS_PARTKEY
        AND S_SUPPKEY = PS_SUPPKEY
        AND S_NATIONKEY = N_NATIONKEY
        AND N_REGIONKEY = R_REGIONKEY
        AND R_NAME = 'EUROPE'
  )
ORDER BY S_ACCTBAL DESC, N_NAME, S_NAME, P_PARTKEY
LIMIT 100;

-- =====================================================
-- TPC-H Query 3 - 运输优先级查询
-- =====================================================
-- 功能：获取满足特定条件的订单的收入

SELECT 
    L_ORDERKEY,
    SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
    O_ORDERDATE,
    O_SHIPPRIORITY
FROM CUSTOMER, ORDERS, LINEITEM
WHERE C_MKTSEGMENT = 'BUILDING'
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-15'
  AND L_SHIPDATE > '1995-03-15'
GROUP BY L_ORDERKEY, O_ORDERDATE, O_SHIPPRIORITY
ORDER BY revenue DESC, O_ORDERDATE
LIMIT 10;

-- =====================================================
-- TPC-H Query 4 - 订单优先级检查查询
-- =====================================================
-- 功能：统计特定时期内各优先级订单的数量

SELECT 
    O_ORDERPRIORITY,
    COUNT(*) AS order_count
FROM ORDERS
WHERE O_ORDERDATE >= '1993-07-01'
  AND O_ORDERDATE < DATE_ADD('1993-07-01', INTERVAL 3 MONTH)
  AND EXISTS (
      SELECT 1
      FROM LINEITEM
      WHERE L_ORDERKEY = O_ORDERKEY
        AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY O_ORDERPRIORITY
ORDER BY O_ORDERPRIORITY;

-- =====================================================
-- TPC-H Query 5 - 本地供应商收入查询
-- =====================================================
-- 功能：计算特定地区内本地供应商的收入

SELECT 
    N_NAME,
    SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM CUSTOMER, ORDERS, LINEITEM, SUPPLIER, NATION, REGION
WHERE C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'ASIA'
  AND O_ORDERDATE >= '1994-01-01'
  AND O_ORDERDATE < DATE_ADD('1994-01-01', INTERVAL 1 YEAR)
GROUP BY N_NAME
ORDER BY revenue DESC;

-- =====================================================
-- TPC-H Query 10 - 退货订单查询
-- =====================================================
-- 功能：识别在特定时期内有退货的客户

SELECT 
    C_CUSTKEY,
    C_NAME,
    SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
    C_ACCTBAL,
    N_NAME,
    C_ADDRESS,
    C_PHONE,
    C_COMMENT
FROM CUSTOMER, ORDERS, LINEITEM, NATION
WHERE C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE >= '1993-10-01'
  AND O_ORDERDATE < DATE_ADD('1993-10-01', INTERVAL 3 MONTH)
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY C_CUSTKEY, C_NAME, C_ACCTBAL, C_PHONE, N_NAME, C_ADDRESS, C_COMMENT
ORDER BY revenue DESC
LIMIT 20;

-- =====================================================
-- TPC-H Query 12 - 运输模式和订单优先级查询
-- =====================================================
-- 功能：分析特定运输模式与订单优先级的关系

SELECT 
    L_SHIPMODE,
    SUM(CASE 
        WHEN O_ORDERPRIORITY = '1-URGENT' OR O_ORDERPRIORITY = '2-HIGH'
        THEN 1 ELSE 0 
    END) AS high_line_count,
    SUM(CASE 
        WHEN O_ORDERPRIORITY <> '1-URGENT' AND O_ORDERPRIORITY <> '2-HIGH'
        THEN 1 ELSE 0 
    END) AS low_line_count
FROM ORDERS, LINEITEM
WHERE O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('MAIL', 'SHIP')
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
  AND L_RECEIPTDATE >= '1994-01-01'
  AND L_RECEIPTDATE < DATE_ADD('1994-01-01', INTERVAL 1 YEAR)
GROUP BY L_SHIPMODE
ORDER BY L_SHIPMODE;

-- =====================================================
-- TPC-H Query 14 - 促销效果查询
-- =====================================================
-- 功能：计算促销收入百分比

SELECT 
    100.00 * SUM(CASE 
        WHEN P_TYPE LIKE 'PROMO%'
        THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT)
        ELSE 0 
    END) / SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM LINEITEM, PART
WHERE L_PARTKEY = P_PARTKEY
  AND L_SHIPDATE >= '1995-09-01'
  AND L_SHIPDATE < DATE_ADD('1995-09-01', INTERVAL 1 MONTH);

-- =====================================================
-- TPC-H Query 19 - 折扣收入查询
-- =====================================================
-- 功能：计算特定条件下的折扣收入

SELECT SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM LINEITEM, PART
WHERE (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#12'
    AND P_CONTAINER IN ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG')
    AND L_QUANTITY >= 1 AND L_QUANTITY <= 1 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
) OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#23'
    AND P_CONTAINER IN ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK')
    AND L_QUANTITY >= 10 AND L_QUANTITY <= 10 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
) OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#34'
    AND P_CONTAINER IN ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG')
    AND L_QUANTITY >= 20 AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
);

-- =====================================================
-- 查询性能分析
-- =====================================================

-- 显示查询执行时间
SELECT 'Query Performance Analysis' as Info;

-- 分析表大小和记录数
SELECT 
    TABLE_NAME,
    TABLE_ROWS,
    ROUND(DATA_LENGTH/1024/1024, 2) as 'Data Size (MB)',
    ROUND(INDEX_LENGTH/1024/1024, 2) as 'Index Size (MB)'
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'TPC_H'
ORDER BY TABLE_ROWS DESC;

-- 显示索引使用情况
SHOW INDEX FROM LINEITEM;
SHOW INDEX FROM ORDERS;
SHOW INDEX FROM CUSTOMER;
