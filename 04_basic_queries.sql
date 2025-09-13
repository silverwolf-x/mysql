-- =====================================================
-- MySQL版本 - 基本查询操作
-- 文件: 04_basic_queries.sql
-- 功能: 基本SQL查询操作示例（投影、选择、聚集、排序）
-- =====================================================

USE TPC_H;

-- =====================================================
-- 投影操作（SELECT子句）
-- =====================================================

-- 【例4-11】查询PART表中全部的记录
SELECT * FROM PART LIMIT 10;

-- 查询指定列
-- 【例4-12】查询PART表中P_NAME、P_BRAND和P_CONTAINER列
SELECT P_BRAND, P_NAME, P_CONTAINER FROM PART LIMIT 10;

-- 查询表达式列
SELECT 
    L_COMMITDATE, 
    L_RECEIPTDATE, 
    'Interval Days:' as Receipting,
    DATEDIFF(L_RECEIPTDATE, L_COMMITDATE) as IntervalDay,
    L_EXTENDEDPRICE * (1 - L_DISCOUNT) as DiscountedPrice,
    L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX) as DiscountedTaxedPrice
FROM LINEITEM 
LIMIT 10;

-- 投影出列中不同的成员
-- 【例4-14】查出LINEITEM表中各订单项的L_SHIPMODE方式
SELECT L_SHIPMODE FROM LINEITEM ORDER BY L_SHIPMODE LIMIT 20;

-- 查询共有哪些L_SHIPMODE方式（去重）
SELECT DISTINCT L_SHIPMODE FROM LINEITEM;

SELECT DISTINCT L_SHIPMODE, L_RETURNFLAG FROM LINEITEM;

-- 统计记录数
SELECT COUNT(*) as total_lineitem FROM LINEITEM;
SELECT COUNT(L_ORDERKEY) as non_null_orderkey FROM LINEITEM;

-- 验证主键唯一性
SELECT PS_PARTKEY, PS_SUPPKEY, COUNT(*) as counter 
FROM PARTSUPP 
GROUP BY PS_PARTKEY, PS_SUPPKEY
HAVING COUNT(*) > 1;

-- =====================================================
-- 选择操作（WHERE子句）
-- =====================================================

-- 比较大小
-- 【例4-15】输出LINEITEM表中满足条件的记录
SELECT * FROM LINEITEM WHERE L_QUANTITY >= 45 LIMIT 10;

SELECT * FROM LINEITEM WHERE L_SHIPINSTRUCT = 'COLLECT COD' LIMIT 10;

SELECT * FROM LINEITEM WHERE L_COMMITDATE <= L_SHIPDATE LIMIT 10;

SELECT * FROM LINEITEM 
WHERE DATEDIFF(L_RECEIPTDATE, L_COMMITDATE) > 10 
LIMIT 10;

-- 范围判断
-- 【例4-16】输出LINEITEM表中指定范围之间的记录
SELECT * FROM LINEITEM 
WHERE L_COMMITDATE BETWEEN L_SHIPDATE AND L_RECEIPTDATE 
LIMIT 10;

SELECT * FROM LINEITEM 
WHERE L_COMMITDATE NOT BETWEEN '1996-01-01' AND '1997-12-31' 
LIMIT 10;

-- 日期函数示例
SELECT 
    L_SHIPDATE,
    DATE_ADD(L_SHIPDATE, INTERVAL 5 YEAR) as date_5Year_after,
    DATE_ADD(L_SHIPDATE, INTERVAL 5 QUARTER) as date_5Quarter_after,
    DATE_ADD(L_SHIPDATE, INTERVAL 5 WEEK) as date_5Week_after,
    DATE_ADD(L_SHIPDATE, INTERVAL -25 DAY) as date_25D_before,
    DATEDIFF(L_RECEIPTDATE, L_SHIPDATE) as daygap
FROM LINEITEM 
LIMIT 10;

-- 集合判断
-- 【例4-17】输出LINEITEM表中集合之内的记录
SELECT * FROM LINEITEM WHERE L_SHIPMODE IN ('MAIL', 'SHIP') LIMIT 10;

SELECT * FROM PART WHERE P_SIZE NOT IN (49,14,23,45,19,3,36,9) LIMIT 10;

-- 字符匹配
-- 【例4-18】输出模糊查询的结果
SELECT * FROM PART WHERE P_TYPE LIKE 'PROMO%' LIMIT 10;

SELECT * FROM SUPPLIER WHERE S_COMMENT LIKE '%Customer%Complaints%' LIMIT 10;

SELECT * FROM PART WHERE P_CONTAINER LIKE '% _AG' LIMIT 10;

-- MySQL中转义字符使用示例
SELECT * FROM LINEITEM 
WHERE L_COMMENT LIKE '%return rate __\\%for%' 
LIMIT 10;

-- 空值判断
-- 【例4-19】输出LINEITEM表中没有客户评价L_COMMENT的记录
SELECT * FROM LINEITEM WHERE L_COMMENT IS NULL LIMIT 10;

-- 复合条件表达式
-- 【例4-20】输出LINEITEM表中满足复合条件的记录
SELECT SUM(L_EXTENDEDPRICE * L_DISCOUNT) as revenue 
FROM LINEITEM
WHERE L_SHIPDATE BETWEEN '1996-01-01' AND '1996-12-31' 
  AND L_DISCOUNT BETWEEN 0.05 AND 0.07 
  AND L_QUANTITY > 24;

-- 复杂复合条件
SELECT * FROM LINEITEM 
WHERE L_SHIPMODE IN ('AIR', 'REG AIR') 
  AND L_SHIPINSTRUCT = 'DELIVER IN PERSON' 
  AND ((L_QUANTITY >= 10 AND L_QUANTITY <= 20) OR (L_QUANTITY >= 30 AND L_QUANTITY <= 40))
ORDER BY L_ORDERKEY, L_LINENUMBER
LIMIT 20;

-- =====================================================
-- 聚集操作（聚合函数）
-- =====================================================

-- 【例4-21】执行TPC-H查询Q1中聚集计算部分
SELECT
    SUM(L_QUANTITY) as sum_qty,
    SUM(L_EXTENDEDPRICE) as sum_base_price,
    SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) as sum_disc_price,
    SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) as sum_charge,
    AVG(L_QUANTITY) as avg_qty,
    AVG(L_EXTENDEDPRICE) as avg_price,
    AVG(L_DISCOUNT) as avg_disc,
    COUNT(*) as count_order
FROM LINEITEM;

-- 【例4-22】统计LINEITEM表中L_QUANTITY列的数据特征
SELECT 
    COUNT(L_QUANTITY) as CARD1,
    COUNT(DISTINCT L_QUANTITY) as CARD, 
    MAX(L_QUANTITY) as max_value, 
    MIN(L_QUANTITY) as min_value 
FROM LINEITEM;

-- 【例4-23】统计ORDERS表中高优先级与低优先级订单的数量
SELECT 
    SUM(CASE WHEN O_ORDERPRIORITY IN ('1-URGENT', '2-HIGH') THEN 1 ELSE 0 END) as high_line_count,
    SUM(CASE WHEN O_ORDERPRIORITY NOT IN ('1-URGENT', '2-HIGH') THEN 1 ELSE 0 END) as low_line_count
FROM ORDERS;

-- 按优先级统计销售额
SELECT O_ORDERPRIORITY, SUM(O_TOTALPRICE) as revenue 
FROM ORDERS 
GROUP BY O_ORDERPRIORITY;

-- 通过CASE语句计算按优先级的详细统计
SELECT 
    SUM(CASE WHEN O_ORDERPRIORITY = '1-URGENT' THEN O_TOTALPRICE ELSE 0 END) as 'URGENT',
    SUM(CASE WHEN O_ORDERPRIORITY = '2-HIGH' THEN O_TOTALPRICE ELSE 0 END) as 'HIGH',
    SUM(CASE WHEN O_ORDERPRIORITY = '3-MEDIUM' THEN O_TOTALPRICE ELSE 0 END) as 'MEDIUM',
    SUM(CASE WHEN O_ORDERPRIORITY = '4-NOT SPECIFIED' THEN O_TOTALPRICE ELSE 0 END) as 'NOT_SPECIFIED',
    SUM(CASE WHEN O_ORDERPRIORITY = '5-LOW' THEN O_TOTALPRICE ELSE 0 END) as 'LOW'
FROM ORDERS;

-- =====================================================
-- 分组和HAVING子句
-- =====================================================

-- 【例4-26】输出LINEITEM表订单中项目超过5项的订单号
SELECT L_ORDERKEY, COUNT(*) as order_counter
FROM LINEITEM 
GROUP BY L_ORDERKEY 
HAVING COUNT(*) >= 5
ORDER BY order_counter DESC
LIMIT 20;

-- 【例4-27】复杂HAVING条件
SELECT L_ORDERKEY, AVG(L_EXTENDEDPRICE) as avg_price
FROM LINEITEM 
GROUP BY L_ORDERKEY 
HAVING AVG(L_QUANTITY) BETWEEN 28 AND 30 AND COUNT(*) > 5;

-- =====================================================
-- 排序操作（ORDER BY子句）
-- =====================================================

-- 【例4-28】对LINEITEM表进行分组聚集计算，输出排序的查询结果
SELECT 
    L_RETURNFLAG,
    L_LINESTATUS,
    SUM(L_QUANTITY) as sum_quantity 
FROM LINEITEM 
GROUP BY L_RETURNFLAG, L_LINESTATUS
ORDER BY L_RETURNFLAG, L_LINESTATUS;

-- 按聚集结果排序
SELECT 
    L_RETURNFLAG,
    L_LINESTATUS,
    SUM(L_QUANTITY) as sum_quantity 
FROM LINEITEM 
GROUP BY L_RETURNFLAG, L_LINESTATUS
ORDER BY sum_quantity DESC;

-- 计算日销售额
SELECT O_ORDERDATE, SUM(O_TOTALPRICE) as dailysales
FROM ORDERS
GROUP BY O_ORDERDATE
ORDER BY O_ORDERDATE
LIMIT 30;
