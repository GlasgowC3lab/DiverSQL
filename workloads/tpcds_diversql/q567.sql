WITH sampled_sales AS (
    SELECT
        ss_sold_date_sk,
        ss_store_sk,
        ss_addr_sk,
        ss_cdemo_sk,
        ss_ext_sales_price,
        ss_net_profit
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
joined AS (
    SELECT
        s.s_store_name,
        s.s_state,
        s.s_tax_percentage,
        ca.ca_city,
        ca.ca_state AS ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_employed_count,
        ss.ss_ext_sales_price,
        ss.ss_net_profit
    FROM sampled_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND ca.ca_state = 'CA'
        AND s.s_state = 'TX'
        AND ss.ss_ext_sales_price > 1000
        AND s.s_tax_percentage BETWEEN 0.05 AND 0.08
        AND cd.cd_dep_employed_count >= 3
),
agg AS (
    SELECT
        s_store_name,
        s_state,
        ca_city,
        cd_gender,
        COUNT(*) AS txn_cnt,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_ext_sales_price) AS avg_sales,
        MIN(ss_ext_sales_price) AS min_sales,
        MAX(ss_ext_sales_price) AS max_sales,
        SUM(ss_net_profit) AS total_profit
    FROM joined
    GROUP BY s_store_name, s_state, ca_city, cd_gender
    HAVING SUM(ss_ext_sales_price) > 5000
)
SELECT
    s_store_name,
    s_state,
    ca_city,
    cd_gender,
    txn_cnt,
    total_sales,
    avg_sales,
    min_sales,
    max_sales,
    total_profit,
    LAG(total_sales, 1) OVER (PARTITION BY s_store_name ORDER BY total_sales DESC) AS prev_store_sales
FROM agg
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
