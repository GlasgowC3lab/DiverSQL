WITH
store_sales_agg AS (
    SELECT ss_customer_sk AS customer_sk,
           SUM(ss_net_profit) AS store_net_profit,
           COUNT(*) AS store_txn_count,
           MAX(ss_sold_date_sk) AS last_store_sale_date_sk
    FROM store_sales
    GROUP BY ss_customer_sk
),
catalog_sales_agg AS (
    SELECT cs_bill_customer_sk AS customer_sk,
           SUM(cs_net_profit) AS catalog_net_profit,
           COUNT(*) AS catalog_txn_count,
           MAX(cs_sold_date_sk) AS last_catalog_sale_date_sk
    FROM catalog_sales
    GROUP BY cs_bill_customer_sk
),
web_sales_agg AS (
    SELECT ws_bill_customer_sk AS customer_sk,
           SUM(ws_net_profit) AS web_net_profit,
           COUNT(*) AS web_txn_count,
           MAX(ws_sold_date_sk) AS last_web_sale_date_sk
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
combined_sales AS (
    SELECT COALESCE(s.customer_sk, c.customer_sk, w.customer_sk) AS customer_sk,
           COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0) AS total_net_profit,
           COALESCE(s.store_txn_count, 0) + COALESCE(c.catalog_txn_count, 0) + COALESCE(w.web_txn_count, 0) AS total_txn_count,
           GREATEST(COALESCE(s.last_store_sale_date_sk, 0), COALESCE(c.last_catalog_sale_date_sk, 0), COALESCE(w.last_web_sale_date_sk, 0)) AS last_sale_date_sk
    FROM store_sales_agg s
    FULL OUTER JOIN catalog_sales_agg c ON s.customer_sk = c.customer_sk
    FULL OUTER JOIN web_sales_agg w ON COALESCE(s.customer_sk, c.customer_sk) = w.customer_sk
),
returns_raw AS (
    SELECT sr_customer_sk AS customer_sk, sr_net_loss AS net_loss, sr_returned_date_sk AS date_sk
    FROM store_returns
    UNION ALL
    SELECT cr_returning_customer_sk, cr_net_loss, cr_returned_date_sk
    FROM catalog_returns
    UNION ALL
    SELECT wr_refunded_customer_sk, wr_net_loss, wr_returned_date_sk
    FROM web_returns
),
returns_agg AS (
    SELECT customer_sk,
           SUM(net_loss) AS total_return_loss,
           COUNT(*) AS total_return_cnt,
           MAX(date_sk) AS last_return_date_sk
    FROM returns_raw
    GROUP BY customer_sk
),
sales_returns_combined AS (
    SELECT COALESCE(cs.customer_sk, r.customer_sk) AS customer_sk,
           COALESCE(cs.total_net_profit, 0) - COALESCE(r.total_return_loss, 0) AS net_profit_adjusted,
           COALESCE(cs.total_txn_count, 0) AS total_txn_count,
           GREATEST(COALESCE(cs.last_sale_date_sk, 0), COALESCE(r.last_return_date_sk, 0)) AS most_recent_date_sk
    FROM combined_sales cs
    FULL OUTER JOIN returns_agg r ON cs.customer_sk = r.customer_sk
),
customer_details AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        TRIM(CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, ''))) AS full_name,
        d.cd_gender,
        d.cd_education_status,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        COALESCE(a.ca_gmt_offset, 0) AS gmt_offset
    FROM customer c
    LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
),
ranked_customers AS (
    SELECT
        cd.c_customer_sk,
        cd.c_customer_id,
        cd.full_name,
        cd.cd_gender,
        cd.cd_education_status,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        sr.net_profit_adjusted,
        sr.total_txn_count,
        sr.most_recent_date_sk,
        d.d_date AS most_recent_date,
        ROW_NUMBER() OVER (ORDER BY sr.net_profit_adjusted DESC) AS profit_rank
    FROM sales_returns_combined sr
    JOIN customer_details cd ON sr.customer_sk = cd.c_customer_sk
    LEFT JOIN date_dim d ON sr.most_recent_date_sk = d.d_date_sk
)
SELECT
    rc.profit_rank,
    rc.c_customer_id,
    rc.full_name,
    rc.cd_gender,
    rc.cd_education_status,
    rc.ca_city,
    rc.ca_state,
    rc.ca_country,
    rc.net_profit_adjusted,
    rc.total_txn_count,
    rc.most_recent_date,
    CASE
        WHEN rc.total_txn_count > 100 THEN 'HIGH_ACTIVITY'
        WHEN rc.total_txn_count BETWEEN 50 AND 100 THEN 'MEDIUM_ACTIVITY'
        ELSE 'LOW_ACTIVITY'
    END AS activity_level,
    COALESCE(NULLIF(rc.net_profit_adjusted / NULLIF(rc.total_txn_count, 0), 0), 0) AS avg_profit_per_txn,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = rc.c_customer_sk AND ss.ss_sold_date_sk = rc.most_recent_date_sk) AS store_txns_on_last_day,
    (SELECT COUNT(*) FROM catalog_sales cs WHERE cs.cs_bill_customer_sk = rc.c_customer_sk AND cs.cs_sold_date_sk = rc.most_recent_date_sk) AS catalog_txns_on_last_day,
    (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_bill_customer_sk = rc.c_customer_sk AND ws.ws_sold_date_sk = rc.most_recent_date_sk) AS web_txns_on_last_day
FROM ranked_customers rc
WHERE rc.profit_rank <= 100
ORDER BY rc.profit_rank
