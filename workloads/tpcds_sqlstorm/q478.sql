WITH combined_sales AS (
    SELECT 
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS cust_sk,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit AS profit,
        'store' AS channel
    FROM store_sales ss

    UNION ALL

    SELECT 
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        'catalog' AS channel
    FROM catalog_sales cs

    UNION ALL

    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        'web' AS channel
    FROM web_sales ws
),

sales_with_date AS (
    SELECT
        cs.date_sk,
        cs.item_sk,
        cs.cust_sk,
        cs.sales_amount,
        cs.profit,
        cs.channel,
        d.d_year,
        d.d_month_seq,
        d.d_date AS sales_date
    FROM combined_sales cs
    LEFT JOIN date_dim d ON cs.date_sk = d.d_date_sk
),

ranked_sales AS (
    SELECT
        swd.*,
        ROW_NUMBER() OVER (PARTITION BY swd.d_year ORDER BY swd.sales_amount DESC NULLS LAST) AS rn_year,
        RANK() OVER (PARTITION BY swd.channel ORDER BY swd.sales_amount DESC) AS channel_rank,
        SUM(swd.sales_amount) OVER (PARTITION BY swd.d_year, swd.channel) AS total_sales_year_channel,
        COUNT(*) OVER (PARTITION BY swd.d_year) AS cnt_sales_year
    FROM sales_with_date swd
    WHERE swd.sales_amount IS NOT NULL
),

customer_demo AS (
    SELECT 
        c.c_customer_sk AS cust_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CASE 
            WHEN REGEXP_LIKE(c.c_first_name, '^[A-Z]') THEN 'CAPITAL_FIRST' 
            ELSE 'LOWER_CASE' 
        END AS name_style
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),

address_match AS (
    SELECT 
        c.c_customer_sk AS cust_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CASE 
            WHEN ca.ca_city IS NULL THEN NULL
            WHEN POSITION(LOWER(c.c_last_name) IN LOWER(ca.ca_city)) > 0 THEN TRUE
            ELSE FALSE
        END AS city_has_lastname
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),

filtered_ranked AS (
    SELECT
        rs.*,
        cd.cd_gender,
        cd.cd_marital_status,
        am.city_has_lastname,
        COALESCE(am.city_has_lastname, FALSE) AS city_lastname_flag
    FROM ranked_sales rs
    LEFT JOIN customer_demo cd ON rs.cust_sk IS NOT DISTINCT FROM cd.cust_sk
    LEFT JOIN address_match am ON rs.cust_sk = am.cust_sk
    WHERE (rs.rn_year <= 5 OR rs.channel_rank <= 10)
      AND (cd.name_style = 'CAPITAL_FIRST' OR cd.name_style IS NULL)
),

item_profit AS (
    SELECT 
        ipc.item_sk,
        ipc.channel,
        CAST(AVG(ipc.profit) AS DECIMAL(7,2)) AS avg_profit_per_item
    FROM (
        SELECT 
            cs.item_sk,
            cs.channel,
            cs.profit
        FROM combined_sales cs
    ) ipc
    GROUP BY ipc.item_sk, ipc.channel
),

sales_stats AS (
    SELECT
        fr.channel,
        d.d_year,
        SUM(fr.sales_amount) AS sum_sales,
        AVG(fr.profit) AS avg_profit,
        COUNT(*) AS cnt_sales
    FROM filtered_ranked fr
    LEFT JOIN date_dim d ON fr.date_sk = d.d_date_sk
    GROUP BY GROUPING SETS ((fr.channel, d.d_year), (fr.channel), (d.d_year), ())
),

enriched_sales AS (
    SELECT
        fr.date_sk,
        fr.cust_sk,
        fr.item_sk,
        fr.sales_amount,
        fr.profit,
        CONCAT('CUST_', CAST(fr.cust_sk AS VARCHAR)) AS cust_key,
        fr.channel,
        fr.d_year AS sales_year,
        fr.d_month_seq AS sales_month_seq,
        fr.sales_date,
        fr.rn_year,
        fr.channel_rank,
        CAST(fr.total_sales_year_channel AS DECIMAL(7,2)) AS total_sales_year_channel,
        fr.cnt_sales_year,
        fr.cd_gender,
        fr.cd_marital_status,
        fr.city_has_lastname,
        fr.city_lastname_flag,
        ip.avg_profit_per_item,
        CASE 
            WHEN fr.profit > ip.avg_profit_per_item THEN 'ABOVE_AVG'
            WHEN fr.profit < ip.avg_profit_per_item THEN 'BELOW_AVG'
            ELSE 'EQUAL'
        END AS profit_vs_item_avg,
        EXISTS (
            SELECT 1 
            FROM promotion p
            WHERE p.p_item_sk = fr.item_sk
              AND p.p_discount_active = 'Y'
              AND p.p_start_date_sk <= fr.date_sk
              AND p.p_end_date_sk >= fr.date_sk
        ) AS promotion_active_flag,
        CASE 
            WHEN fr.sales_amount >= 10000 THEN 'HIGH'
            WHEN fr.sales_amount BETWEEN 5000 AND 9999.99 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS sales_tier,
        (SELECT COUNT(*) FROM filtered_ranked f2 WHERE f2.channel = fr.channel AND f2.sales_amount > fr.sales_amount) + 1 AS alt_channel_rank,
        (SELECT MAX(d2.d_year) FROM date_dim d2 WHERE d2.d_year < fr.d_year) AS prev_year
    FROM filtered_ranked fr
    LEFT JOIN item_profit ip ON fr.item_sk = ip.item_sk AND fr.channel = ip.channel
),

unioned_sales AS (
    SELECT
        date_sk,
        cust_sk,
        item_sk,
        sales_amount,
        profit,
        cust_key,
        channel,
        sales_year,
        sales_month_seq,
        sales_date,
        rn_year,
        channel_rank,
        total_sales_year_channel,
        cnt_sales_year,
        cd_gender,
        cd_marital_status,
        city_has_lastname,
        city_lastname_flag,
        avg_profit_per_item,
        profit_vs_item_avg,
        promotion_active_flag,
        sales_tier,
        alt_channel_rank,
        prev_year
    FROM enriched_sales
    UNION ALL
    SELECT
        CAST(NULL AS INTEGER),
        CAST(NULL AS INTEGER),
        CAST(NULL AS INTEGER),
        CAST(NULL AS DECIMAL(7,2)),
        CAST(NULL AS DECIMAL(7,2)),
        CAST(NULL AS VARCHAR),
        CAST(NULL AS VARCHAR),
        CAST(NULL AS INTEGER),
        CAST(NULL AS INTEGER),
        CAST(NULL AS DATE),
        CAST(NULL AS INTEGER),
        CAST(NULL AS INTEGER),
        CAST(NULL AS DECIMAL(7,2)),
        CAST(NULL AS INTEGER),
        CAST(NULL AS VARCHAR),
        CAST(NULL AS VARCHAR),
        CAST(NULL AS BOOLEAN),
        CAST(NULL AS BOOLEAN),
        CAST(NULL AS DECIMAL(7,2)),
        CAST(NULL AS VARCHAR),
        CAST(NULL AS BOOLEAN),
        CAST(NULL AS VARCHAR),
        CAST(NULL AS INTEGER),
        CAST(NULL AS INTEGER)
    WHERE FALSE
),

final_ranked AS (
    SELECT 
        u.*,
        ROW_NUMBER() OVER (ORDER BY sales_amount DESC NULLS LAST) AS overall_rank
    FROM unioned_sales u
)

SELECT *
FROM final_ranked
WHERE (sales_tier = 'HIGH' AND city_has_lastname = TRUE)
   OR (sales_tier = 'LOW' AND profit_vs_item_avg = 'BELOW_AVG')
ORDER BY overall_rank
LIMIT 100
