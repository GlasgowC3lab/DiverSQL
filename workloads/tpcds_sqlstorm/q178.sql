WITH
store_sales_agg AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        d.d_year AS year,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_quantity) AS quantity,
        'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_customer_sk, d.d_year
),
catalog_sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        d.d_year AS year,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_quantity) AS quantity,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_bill_customer_sk, d.d_year
),
web_sales_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        d.d_year AS year,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_quantity) AS quantity,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_bill_customer_sk, d.d_year
),
sales_by_customer_year AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
customer_sales_agg AS (
    SELECT
        customer_sk,
        year,
        SUM(net_profit) AS total_net_profit,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT channel) AS channel_count
    FROM sales_by_customer_year
    GROUP BY customer_sk, year
),
customer_info AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        lower(c.c_email_address) AS email_address,
        CASE
            WHEN lower(c.c_email_address) LIKE '%@example.com' THEN 'Example.com'
            ELSE 'Other'
        END AS email_domain,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_state,
        ca.ca_city,
        substr(c.c_first_name, 1, 1) || substr(c.c_last_name, 1, 1) AS initials
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ranked_customers AS (
    SELECT
        cs.customer_sk,
        cs.year,
        cs.total_net_profit,
        cs.total_quantity,
        cs.channel_count,
        ci.full_name,
        ci.email_address,
        ci.email_domain,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.ca_state,
        ci.ca_city,
        ci.initials,
        substr(ci.email_address, 1, 5) || '_' || CAST(cs.year AS VARCHAR) AS customer_key,
        ROW_NUMBER() OVER (PARTITION BY cs.year ORDER BY cs.total_net_profit DESC) AS rank_year,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS global_rank,
        SUM(cs.total_net_profit) OVER (PARTITION BY cs.year ORDER BY cs.total_net_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_profit,
        CASE
            WHEN cs.total_quantity > 0 THEN ROUND(cs.total_net_profit / NULLIF(cs.total_quantity, 0), 2)
            ELSE NULL
        END AS profit_per_item,
        (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = cs.customer_sk) AS store_return_cnt,
        (SELECT COALESCE(SUM(sr.sr_net_loss), 0) FROM store_returns sr WHERE sr.sr_customer_sk = cs.customer_sk) AS store_return_loss,
        (SELECT COUNT(*) FROM catalog_returns cr WHERE cr.cr_returning_customer_sk = cs.customer_sk) AS catalog_return_cnt,
        (SELECT COALESCE(SUM(cr.cr_net_loss), 0) FROM catalog_returns cr WHERE cr.cr_returning_customer_sk = cs.customer_sk) AS catalog_return_loss,
        (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_returning_customer_sk = cs.customer_sk) AS web_return_cnt,
        (SELECT COALESCE(SUM(wr.wr_net_loss), 0) FROM web_returns wr WHERE wr.wr_returning_customer_sk = cs.customer_sk) AS web_return_loss
    FROM customer_sales_agg cs
    LEFT JOIN customer_info ci ON cs.customer_sk = ci.customer_sk
),
call_center_year_agg AS (
    SELECT
        d.d_year AS year,
        SUM(cs.cs_net_profit) AS call_center_year_profit,
        COUNT(DISTINCT cs.cs_order_number) AS call_center_year_orders
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
combined AS (
    SELECT
        rc.year,
        rc.customer_sk,
        rc.full_name,
        rc.email_address,
        rc.email_domain,
        rc.ca_state,
        rc.ca_city,
        rc.total_net_profit,
        rc.total_quantity,
        rc.channel_count,
        rc.rank_year,
        rc.global_rank,
        rc.running_total_profit,
        rc.profit_per_item,
        rc.store_return_cnt,
        rc.store_return_loss,
        rc.catalog_return_cnt,
        rc.catalog_return_loss,
        rc.web_return_cnt,
        rc.web_return_loss,
        rc.initials,
        rc.customer_key,
        NULL AS call_center_year_profit,
        NULL AS call_center_year_orders,
        'CUSTOMER' AS record_type
    FROM ranked_customers rc
    WHERE rc.rank_year <= 5
    UNION ALL
    SELECT
        ccy.year,
        NULL AS customer_sk,
        NULL AS full_name,
        NULL AS email_address,
        NULL AS email_domain,
        NULL AS ca_state,
        NULL AS ca_city,
        ccy.call_center_year_profit AS total_net_profit,
        NULL AS total_quantity,
        NULL AS channel_count,
        NULL AS rank_year,
        NULL AS global_rank,
        NULL AS running_total_profit,
        NULL AS profit_per_item,
        NULL AS store_return_cnt,
        NULL AS store_return_loss,
        NULL AS catalog_return_cnt,
        NULL AS catalog_return_loss,
        NULL AS web_return_cnt,
        NULL AS web_return_loss,
        NULL AS initials,
        NULL AS customer_key,
        ccy.call_center_year_profit,
        ccy.call_center_year_orders,
        'CALL_CENTER_SUMMARY' AS record_type
    FROM call_center_year_agg ccy
)
SELECT
    year,
    record_type,
    customer_sk,
    full_name,
    email_address,
    email_domain,
    ca_state,
    ca_city,
    initials,
    customer_key,
    total_net_profit,
    total_quantity,
    channel_count,
    rank_year,
    global_rank,
    running_total_profit,
    profit_per_item,
    store_return_cnt,
    store_return_loss,
    catalog_return_cnt,
    catalog_return_loss,
    web_return_cnt,
    web_return_loss,
    call_center_year_profit,
    call_center_year_orders
FROM combined
ORDER BY year, record_type, total_net_profit DESC
FETCH FIRST 100 ROWS WITH TIES
