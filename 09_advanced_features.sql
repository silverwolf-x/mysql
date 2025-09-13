-- =====================================================
-- MySQL版本 - 高级功能和分析
-- 文件: 09_advanced_features.sql
-- 功能: 窗口函数、CTE、存储过程等高级功能
-- =====================================================

USE TPC_H;

-- =====================================================
-- 窗口函数示例
-- =====================================================

-- 排名函数示例
-- 按销售额对客户进行排名
SELECT 
    C_CUSTKEY,
    C_NAME,
    total_sales,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) as row_num,
    RANK() OVER (ORDER BY total_sales DESC) as rank_val,
    DENSE_RANK() OVER (ORDER BY total_sales DESC) as dense_rank_val
FROM (
    SELECT 
        C_CUSTKEY,
        C_NAME,
        SUM(O_TOTALPRICE) as total_sales
    FROM CUSTOMER C
    JOIN ORDERS O ON C.C_CUSTKEY = O.O_CUSTKEY
    GROUP BY C_CUSTKEY, C_NAME
) customer_sales
ORDER BY total_sales DESC
LIMIT 20;

-- 分区窗口函数
-- 每个地区内客户按销售额排名
SELECT 
    R_NAME,
    N_NAME,
    C_NAME,
    total_sales,
    region_rank
FROM (
    SELECT 
        R_NAME,
        N_NAME,
        C_NAME,
        total_sales,
        ROW_NUMBER() OVER (PARTITION BY R_NAME ORDER BY total_sales DESC) as region_rank
    FROM (
        SELECT 
            R_NAME,
            N_NAME,
            C_NAME,
            SUM(O_TOTALPRICE) as total_sales
        FROM CUSTOMER C
        JOIN ORDERS O ON C.C_CUSTKEY = O.O_CUSTKEY
        JOIN NATION N ON C.C_NATIONKEY = N.N_NATIONKEY
        JOIN REGION R ON N.N_REGIONKEY = R.R_REGIONKEY
        GROUP BY R_NAME, N_NAME, C_NAME
    ) regional_sales
) ranked_sales
WHERE region_rank <= 5
ORDER BY R_NAME, region_rank;

-- 累计求和和移动平均
-- 按月累计销售额
SELECT 
    order_month,
    monthly_sales,
    SUM(monthly_sales) OVER (ORDER BY order_month) as cumulative_sales,
    AVG(monthly_sales) OVER (ORDER BY order_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as moving_avg_3months
FROM (
    SELECT 
        DATE_FORMAT(O_ORDERDATE, '%Y-%m') as order_month,
        SUM(O_TOTALPRICE) as monthly_sales
    FROM ORDERS
    GROUP BY DATE_FORMAT(O_ORDERDATE, '%Y-%m')
) monthly_data
ORDER BY order_month;

-- LEAD和LAG函数
-- 计算月度销售额同比增长
WITH monthly_sales AS (
    SELECT 
        YEAR(O_ORDERDATE) as order_year,
        MONTH(O_ORDERDATE) as order_month,
        SUM(O_TOTALPRICE) as monthly_total
    FROM ORDERS
    GROUP BY YEAR(O_ORDERDATE), MONTH(O_ORDERDATE)
)
SELECT 
    order_year,
    order_month,
    monthly_total,
    LAG(monthly_total, 12) OVER (ORDER BY order_year, order_month) as prev_year_sales,
    CASE 
        WHEN LAG(monthly_total, 12) OVER (ORDER BY order_year, order_month) IS NOT NULL
        THEN ROUND(((monthly_total - LAG(monthly_total, 12) OVER (ORDER BY order_year, order_month)) 
                   / LAG(monthly_total, 12) OVER (ORDER BY order_year, order_month) * 100), 2)
        ELSE NULL 
    END as yoy_growth_pct
FROM monthly_sales
ORDER BY order_year, order_month;

-- =====================================================
-- 公用表表达式 (CTE) 示例
-- =====================================================

-- MySQL递归CTE数据类型注意事项：
-- 1. MySQL会根据第一个SELECT（锚点查询）来推断列的数据类型
-- 2. 如果递归部分产生的数据长度超过锚点查询推断的长度，会出现"Data too long"错误
-- 3. 解决方案：在锚点和递归部分都使用CAST显式指定足够的数据类型长度
-- 4. 常用的字符串类型：CHAR(n), VARCHAR(n), TEXT

-- 递归CTE示例：组织层次结构（以地区-国家为例）
-- 注意：此示例展示了MySQL递归CTE中数据类型推断的重要性
WITH RECURSIVE region_hierarchy AS (
    -- 基础情况：地区作为根节点
    SELECT 
        R_REGIONKEY as id,
        R_NAME as name,
        CAST(NULL AS SIGNED) as parent_id,
        0 as level,
        -- 关键修改1：显式指定path列的数据类型为CHAR(500)
        -- 原因：MySQL在递归CTE中会根据第一个SELECT的列类型来推断整个结果集的数据类型
        -- 如果不指定足够的长度，后续的路径拼接可能会被截断
        CAST(R_NAME AS CHAR(500)) as path
    FROM REGION
    
    UNION ALL
    
    -- 递归情况：国家作为地区的子节点
    SELECT 
        N_NATIONKEY + 1000 as id,  -- 避免与地区ID冲突
        N_NAME as name,
        N_REGIONKEY as parent_id,
        1 as level,
        -- 关键修改2：在递归部分也使用CAST确保数据类型一致
        -- 原因：CONCAT函数返回的字符串长度可能超过基础情况中推断的长度
        -- 使用CAST(... AS CHAR(500))确保有足够空间存储完整路径
        CAST(CONCAT(rh.path, ' -> ', N_NAME) AS CHAR(500)) as path
    FROM NATION N
    JOIN region_hierarchy rh ON N.N_REGIONKEY = rh.id
    WHERE rh.level = 0  -- 只处理第一层递归，避免无限递归
)
SELECT * FROM region_hierarchy
ORDER BY level, name;

-- 复杂CTE：客户分类分析
WITH customer_metrics AS (
    SELECT 
        C_CUSTKEY,
        C_NAME,
        C_MKTSEGMENT,
        COUNT(O_ORDERKEY) as order_count,
        SUM(O_TOTALPRICE) as total_spent,
        AVG(O_TOTALPRICE) as avg_order_value,
        MIN(O_ORDERDATE) as first_order,
        MAX(O_ORDERDATE) as last_order
    FROM CUSTOMER C
    LEFT JOIN ORDERS O ON C.C_CUSTKEY = O.O_CUSTKEY
    GROUP BY C_CUSTKEY, C_NAME, C_MKTSEGMENT
),
customer_segments AS (
    SELECT 
        *,
        CASE 
            WHEN total_spent > 500000 THEN 'High Value'
            WHEN total_spent > 200000 THEN 'Medium Value'
            WHEN total_spent > 0 THEN 'Low Value'
            ELSE 'No Orders'
        END as customer_segment,
        CASE 
            WHEN order_count > 20 THEN 'Frequent'
            WHEN order_count > 5 THEN 'Regular'
            WHEN order_count > 0 THEN 'Occasional'
            ELSE 'Never'
        END as frequency_segment
    FROM customer_metrics
)
SELECT 
    customer_segment,
    frequency_segment,
    COUNT(*) as customer_count,
    AVG(total_spent) as avg_total_spent,
    AVG(order_count) as avg_order_count
FROM customer_segments
GROUP BY customer_segment, frequency_segment
ORDER BY customer_segment, frequency_segment;

-- =====================================================
-- 数据透视表示例
-- =====================================================

-- 按年份和地区的销售数据透视
SELECT 
    YEAR(O_ORDERDATE) as order_year,
    SUM(CASE WHEN R_NAME = 'AFRICA' THEN O_TOTALPRICE ELSE 0 END) as AFRICA,
    SUM(CASE WHEN R_NAME = 'AMERICA' THEN O_TOTALPRICE ELSE 0 END) as AMERICA,
    SUM(CASE WHEN R_NAME = 'ASIA' THEN O_TOTALPRICE ELSE 0 END) as ASIA,
    SUM(CASE WHEN R_NAME = 'EUROPE' THEN O_TOTALPRICE ELSE 0 END) as EUROPE,
    SUM(CASE WHEN R_NAME = 'MIDDLE EAST' THEN O_TOTALPRICE ELSE 0 END) as MIDDLE_EAST,
    SUM(O_TOTALPRICE) as TOTAL
FROM ORDERS O
JOIN CUSTOMER C ON O.O_CUSTKEY = C.C_CUSTKEY
JOIN NATION N ON C.C_NATIONKEY = N.N_NATIONKEY
JOIN REGION R ON N.N_REGIONKEY = R.R_REGIONKEY
GROUP BY YEAR(O_ORDERDATE)
ORDER BY order_year;

-- 按优先级和状态的订单数据透视
SELECT 
    O_ORDERPRIORITY,
    COUNT(CASE WHEN O_ORDERSTATUS = 'O' THEN 1 END) as OPEN_ORDERS,
    COUNT(CASE WHEN O_ORDERSTATUS = 'F' THEN 1 END) as FINISHED_ORDERS,
    COUNT(CASE WHEN O_ORDERSTATUS = 'P' THEN 1 END) as PARTIAL_ORDERS,
    COUNT(*) as TOTAL_ORDERS
FROM ORDERS
GROUP BY O_ORDERPRIORITY
ORDER BY O_ORDERPRIORITY;

-- =====================================================
-- 存储过程示例
-- =====================================================

DELIMITER //

-- 创建客户销售报告存储过程
CREATE PROCEDURE GetCustomerSalesReport(
    IN region_name VARCHAR(25),
    IN start_date DATE,
    IN end_date DATE
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    SELECT 
        C.C_CUSTKEY,
        C.C_NAME,
        N.N_NAME as country,
        COUNT(O.O_ORDERKEY) as order_count,
        SUM(O.O_TOTALPRICE) as total_sales,
        AVG(O.O_TOTALPRICE) as avg_order_value,
        MIN(O.O_ORDERDATE) as first_order,
        MAX(O.O_ORDERDATE) as last_order
    FROM CUSTOMER C
    JOIN NATION N ON C.C_NATIONKEY = N.N_NATIONKEY
    JOIN REGION R ON N.N_REGIONKEY = R.R_REGIONKEY
    LEFT JOIN ORDERS O ON C.C_CUSTKEY = O.O_CUSTKEY 
        AND O.O_ORDERDATE BETWEEN start_date AND end_date
    WHERE R.R_NAME = region_name
    GROUP BY C.C_CUSTKEY, C.C_NAME, N.N_NAME
    HAVING total_sales IS NOT NULL
    ORDER BY total_sales DESC;
END //

-- 创建销售趋势分析存储过程
CREATE PROCEDURE GetSalesTrend(
    IN analysis_year INT
)
BEGIN
    SELECT 
        MONTH(O_ORDERDATE) as month_num,
        MONTHNAME(O_ORDERDATE) as month_name,
        COUNT(O_ORDERKEY) as order_count,
        SUM(O_TOTALPRICE) as monthly_sales,
        AVG(O_TOTALPRICE) as avg_order_value,
        SUM(SUM(O_TOTALPRICE)) OVER (ORDER BY MONTH(O_ORDERDATE)) as cumulative_sales
    FROM ORDERS O
    WHERE YEAR(O_ORDERDATE) = analysis_year
    GROUP BY MONTH(O_ORDERDATE), MONTHNAME(O_ORDERDATE)
    ORDER BY MONTH(O_ORDERDATE);
END //

DELIMITER ;

-- 使用存储过程示例
CALL GetCustomerSalesReport('ASIA', '1995-01-01', '1995-12-31');
CALL GetSalesTrend(1995);

-- =====================================================
-- 自定义函数示例
-- =====================================================

DELIMITER //

-- 创建计算订单利润率的函数
CREATE FUNCTION CalculateOrderProfit(
    order_key INT
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE total_revenue DECIMAL(10,2) DEFAULT 0;
    DECLARE total_cost DECIMAL(10,2) DEFAULT 0;
    DECLARE profit_margin DECIMAL(10,2) DEFAULT 0;
    
    SELECT 
        SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT)),
        SUM(PS_SUPPLYCOST * L_QUANTITY)
    INTO total_revenue, total_cost
    FROM LINEITEM L
    JOIN PARTSUPP PS ON L.L_PARTKEY = PS.PS_PARTKEY AND L.L_SUPPKEY = PS.PS_SUPPKEY
    WHERE L.L_ORDERKEY = order_key;
    
    IF total_revenue > 0 THEN
        SET profit_margin = ((total_revenue - total_cost) / total_revenue) * 100;
    END IF;
    
    RETURN profit_margin;
END //

DELIMITER ;

-- 使用自定义函数
SELECT 
    O_ORDERKEY,
    O_TOTALPRICE,
    CalculateOrderProfit(O_ORDERKEY) as profit_margin_pct
FROM ORDERS 
WHERE O_ORDERDATE >= '1995-01-01' 
  AND O_ORDERDATE < '1995-02-01'
ORDER BY profit_margin_pct DESC
LIMIT 10;

-- =====================================================
-- 数据分析示例
-- =====================================================

-- 帕累托分析：80/20规则分析客户
WITH customer_sales AS (
    SELECT 
        C_CUSTKEY,
        C_NAME,
        SUM(O_TOTALPRICE) as total_sales
    FROM CUSTOMER C
    JOIN ORDERS O ON C.C_CUSTKEY = O.O_CUSTKEY
    GROUP BY C_CUSTKEY, C_NAME
),
ranked_customers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) as rank_num,
        SUM(total_sales) OVER (ORDER BY total_sales DESC) as cumulative_sales,
        SUM(total_sales) OVER () as grand_total
    FROM customer_sales
)
SELECT 
    rank_num,
    C_NAME,
    total_sales,
    cumulative_sales,
    ROUND((cumulative_sales / grand_total) * 100, 2) as cumulative_pct,
    CASE 
        WHEN (cumulative_sales / grand_total) <= 0.80 THEN 'Top 80%'
        ELSE 'Bottom 20%'
    END as pareto_category
FROM ranked_customers
ORDER BY rank_num
LIMIT 30;

-- 清理存储过程和函数
DROP PROCEDURE IF EXISTS GetCustomerSalesReport;
DROP PROCEDURE IF EXISTS GetSalesTrend;
DROP FUNCTION IF EXISTS CalculateOrderProfit;
