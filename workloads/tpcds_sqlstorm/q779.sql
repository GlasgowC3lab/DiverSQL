WITH
date_filter AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year = 2002
),
store_sales_agg AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_orders
    FROM store_sales ss
    JOIN date_filter df ON ss.ss_sold_date_sk = df.d_date_sk
    LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY ss.ss_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag
),
catalog_sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN date_filter df ON cs.cs_sold_date_sk = df.d_date_sk
    LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    GROUP BY cs.cs_bill_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag
),
web_sales_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    JOIN date_filter df ON ws.ws_sold_date_sk = df.d_date_sk
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY ws.ws_bill_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag
),
common_customers AS (
    SELECT customer_sk FROM store_sales_agg
    INTERSECT
    SELECT customer_sk FROM web_sales_agg
),
combined_sales AS (
    SELECT customer_sk, c_first_name, c_last_name, c_preferred_cust_flag, total_profit, total_quantity, avg_discount, distinct_orders, 'Store' AS channel
    FROM store_sales_agg
    UNION ALL
    SELECT customer_sk, c_first_name, c_last_name, c_preferred_cust_flag, total_profit, total_quantity, avg_discount, distinct_orders, 'Catalog' AS channel
    FROM catalog_sales_agg
    UNION ALL
    SELECT customer_sk, c_first_name, c_last_name, c_preferred_cust_flag, total_profit, total_quantity, avg_discount, distinct_orders, 'Web' AS channel
    FROM web_sales_agg
),
ranked_sales AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_profit DESC) AS rn_channel,
        ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS rn_overall,
        COALESCE(total_profit / NULLIF(total_quantity, 0), 0) AS profit_per_item,
        CASE WHEN total_quantity > 200 THEN 'HighVolume' ELSE 'LowVolume' END AS volume_category,
        CASE WHEN c_preferred_cust_flag IS NULL THEN 'N' ELSE c_preferred_cust_flag END AS pref_flag_normalized
    FROM combined_sales
),
customer_with_demo AS (
    SELECT
        rs.*,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM ranked_sales rs
    LEFT JOIN customer c ON rs.customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
final AS (
    SELECT
        cwd.customer_sk,
        CONCAT(COALESCE(cwd.c_first_name, ''), ' ', COALESCE(cwd.c_last_name, '')) AS customer_name,
        cwd.channel,
        cwd.total_profit,
        cwd.total_quantity,
        ROUND(cwd.avg_discount, 2) AS avg_discount,
        cwd.distinct_orders,
        cwd.rn_channel,
        cwd.rn_overall,
        cwd.profit_per_item,
        cwd.volume_category,
        cwd.pref_flag_normalized,
        cwd.cd_gender,
        cwd.cd_marital_status,
        cwd.cd_education_status,
        cwd.cd_credit_rating,
        (SELECT AVG(cs2.total_profit)
         FROM combined_sales cs2
         JOIN customer c2 ON cs2.customer_sk = c2.c_customer_sk
         LEFT JOIN customer_demographics cd2 ON c2.c_current_cdemo_sk = cd2.cd_demo_sk
         WHERE cd2.cd_gender = cwd.cd_gender
           AND cs2.channel = cwd.channel) AS gender_channel_avg_profit,
        ((SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = cwd.customer_sk) +
         (SELECT COUNT(*) FROM catalog_sales cs WHERE cs.cs_bill_customer_sk = cwd.customer_sk) +
         (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_bill_customer_sk = cwd.customer_sk)) AS total_transactions,
        CASE
            WHEN (SELECT SUM(ss2.ss_net_profit) FROM store_sales ss2 WHERE ss2.ss_customer_sk = cwd.customer_sk) >
                 (SELECT SUM(ws2.ws_net_profit) FROM web_sales ws2 WHERE ws2.ws_bill_customer_sk = cwd.customer_sk)
            THEN 'StoreFav'
            ELSE 'WebFav'
        END AS profit_preference_flag
    FROM customer_with_demo cwd
    WHERE cwd.rn_channel <= 5
)
SELECT *
FROM final
ORDER BY channel, total_profit DESC
