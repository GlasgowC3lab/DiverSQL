WITH
c_sales AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        SUM(cs.cs_net_paid_inc_tax) AS catalog_revenue,
        SUM(cs.cs_net_profit) AS catalog_profit,
        MAX(d.d_date) AS catalog_latest_date,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
    FROM catalog_sales cs
    LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451200
    GROUP BY cs.cs_bill_customer_sk
),
s_sales AS (
    SELECT
        ss.ss_customer_sk AS cust_sk,
        SUM(ss.ss_net_paid_inc_tax) AS store_revenue,
        SUM(ss.ss_net_profit) AS store_profit,
        MAX(d.d_date) AS store_latest_date,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM store_sales ss
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_customer_sk
),
w_sales AS (
    SELECT
        ws.ws_bill_customer_sk AS cust_sk,
        SUM(ws.ws_net_paid_inc_tax) AS web_revenue,
        SUM(ws.ws_net_profit) AS web_profit,
        MAX(d.d_date) AS web_latest_date,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM web_sales ws
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_bill_customer_sk
),
combined AS (
    SELECT
        COALESCE(c.cust_sk, s.cust_sk, w.cust_sk) AS cust_sk,
        COALESCE(c.catalog_revenue, 0) + COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0) AS total_revenue,
        COALESCE(c.catalog_profit, 0) + COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0) AS total_profit,
        GREATEST(
            COALESCE(c.catalog_latest_date, DATE '1900-01-01'),
            COALESCE(s.store_latest_date, DATE '1900-01-01'),
            COALESCE(w.web_latest_date, DATE '1900-01-01')
        ) AS latest_order_date,
        COALESCE(c.catalog_orders, 0) + COALESCE(s.store_orders, 0) + COALESCE(w.web_orders, 0) AS total_orders,
        CASE
            WHEN COALESCE(c.catalog_profit, 0) > 0 AND COALESCE(s.store_profit, 0) > 0 AND COALESCE(w.web_profit, 0) > 0 THEN 'ALL_POS'
            WHEN COALESCE(c.catalog_profit, 0) < 0 OR COALESCE(s.store_profit, 0) < 0 OR COALESCE(w.web_profit, 0) < 0 THEN 'ANY_NEG'
            ELSE 'MIXED'
        END AS profit_flag
    FROM c_sales c
    FULL OUTER JOIN s_sales s ON c.cust_sk = s.cust_sk
    FULL OUTER JOIN w_sales w ON COALESCE(c.cust_sk, s.cust_sk) = w.cust_sk
),
customer_profile AS (
    SELECT
        cu.c_customer_sk,
        CONCAT(UPPER(TRIM(cu.c_first_name)), ' ', UPPER(TRIM(cu.c_last_name))) AS full_name,
        COALESCE(cu.c_birth_year, 1900) AS birth_year,
        CASE WHEN cu.c_preferred_cust_flag = 'Y' THEN true ELSE false END AS is_preferred,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hi.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE
            WHEN cd.cd_gender IS NULL THEN 'UNKNOWN_GENDER'
            ELSE cd.cd_gender
        END AS gender_coalesced
    FROM customer cu
    LEFT JOIN customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hi ON cu.c_current_hdemo_sk = hi.hd_demo_sk
    LEFT JOIN income_band ib ON hi.hd_income_band_sk = ib.ib_income_band_sk
),
ranked_customers AS (
    SELECT
        cp.c_customer_sk,
        cp.full_name,
        cp.birth_year,
        cp.is_preferred,
        cp.gender_coalesced,
        rc.total_revenue,
        rc.total_profit,
        rc.latest_order_date,
        rc.total_orders,
        rc.profit_flag,
        ROW_NUMBER() OVER (ORDER BY rc.total_profit DESC NULLS LAST) AS profit_rank,
        RANK() OVER (PARTITION BY rc.profit_flag ORDER BY rc.total_profit DESC) AS profit_rank_by_flag,
        SUM(rc.total_profit) OVER (PARTITION BY cp.is_preferred) AS profit_by_preference
    FROM combined rc
    JOIN customer_profile cp ON rc.cust_sk = cp.c_customer_sk
    WHERE rc.total_revenue > 0
      AND (cp.gender_coalesced = 'M' OR cp.gender_coalesced = 'F')
),
final_set AS (
    SELECT *
    FROM ranked_customers
    WHERE profit_rank <= 10
    UNION ALL
    SELECT *
    FROM ranked_customers
    WHERE profit_rank > 10 AND profit_rank <= 20 AND profit_flag = 'ANY_NEG'
)
SELECT
    fs.c_customer_sk,
    fs.full_name,
    REPLACE(fs.full_name, ' ', '_') AS username,
    REGEXP_REPLACE(fs.full_name, '[AEIOUaeiou]', '*') AS masked_name,
    fs.birth_year,
    IF(fs.is_preferred, 'YES', 'NO') AS preferred_flag,
    fs.gender_coalesced,
    fs.total_revenue,
    fs.total_profit,
    fs.total_profit / NULLIF(fs.total_revenue, 0) AS profit_margin,
    format_datetime(CAST(fs.latest_order_date AS timestamp), 'yyyy-MM-dd') AS latest_order_date_str,
    fs.total_orders,
    CASE WHEN fs.total_orders = 0 THEN 'NO_ORDERS' ELSE CAST(fs.total_orders AS varchar) END AS order_count_str,
    fs.profit_flag,
    fs.profit_rank,
    fs.profit_rank_by_flag,
    fs.profit_by_preference,
    GREATEST(
        COALESCE((SELECT MAX(d_ret.d_date) FROM catalog_returns cr_ret JOIN date_dim d_ret ON cr_ret.cr_returned_date_sk = d_ret.d_date_sk WHERE cr_ret.cr_refunded_customer_sk = fs.c_customer_sk), DATE '1900-01-01'),
        COALESCE((SELECT MAX(d_ret2.d_date) FROM store_returns sr_ret JOIN date_dim d_ret2 ON sr_ret.sr_returned_date_sk = d_ret2.d_date_sk WHERE sr_ret.sr_customer_sk = fs.c_customer_sk), DATE '1900-01-01'),
        COALESCE((SELECT MAX(d_ret3.d_date) FROM web_returns wr_ret JOIN date_dim d_ret3 ON wr_ret.wr_returned_date_sk = d_ret3.d_date_sk WHERE wr_ret.wr_refunded_customer_sk = fs.c_customer_sk), DATE '1900-01-01')
    ) AS latest_any_return_date,
    format_datetime(CAST(GREATEST(
        COALESCE((SELECT MAX(d_ret.d_date) FROM catalog_returns cr_ret JOIN date_dim d_ret ON cr_ret.cr_returned_date_sk = d_ret.d_date_sk WHERE cr_ret.cr_refunded_customer_sk = fs.c_customer_sk), DATE '1900-01-01'),
        COALESCE((SELECT MAX(d_ret2.d_date) FROM store_returns sr_ret JOIN date_dim d_ret2 ON sr_ret.sr_returned_date_sk = d_ret2.d_date_sk WHERE sr_ret.sr_customer_sk = fs.c_customer_sk), DATE '1900-01-01'),
        COALESCE((SELECT MAX(d_ret3.d_date) FROM web_returns wr_ret JOIN date_dim d_ret3 ON wr_ret.wr_returned_date_sk = d_ret3.d_date_sk WHERE wr_ret.wr_refunded_customer_sk = fs.c_customer_sk), DATE '1900-01-01')
    ) AS timestamp), 'yyyy-MM-dd') AS latest_any_return_date_str
FROM final_set fs
ORDER BY fs.profit_rank, fs.c_customer_sk
LIMIT 30
