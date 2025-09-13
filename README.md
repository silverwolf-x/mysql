# TPC-H for MySQL — 精简说明

将 TPC-H 的 SQL Server 脚本移植为 MySQL 脚本，供教学与性能测试使用（学习/测试用途，非生产）。

关键文件：
   - `01_database_setup.sql` 数据库与基础配置
   - `02_create_tables.sql` 表结构
   - `03_load_data.sql` 数据导入（可直接编辑路径）
   - `04`-`09` 系列：查询示例与性能优化
   - `data/` 包含 .tbl 数据文件（region,nation,part,supplier,partsupp,customer,orders,lineitem）

快速开始
1. 确认 MySQL ≥ 8.0；并配置 `my.ini` 的设置 `secure_file_priv=''` 以允许导入`03_load_data.sql`
2. 将 `data\*.tbl` 文件放入 `D` 盘中，或者在`03_load_data.sql` 数据导入修改绝对路径
3. 依次执行：`01_database_setup.sql` → `02_create_tables.sql` → `03_load_data.sql`

更多细节请参见各 SQL 文件头部注释。