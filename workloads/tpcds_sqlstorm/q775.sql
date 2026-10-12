WITH
store_sales_agg AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_net_paid) AS store_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
        MAX(d.d_year) AS last_store_year,
        AVG(ss.ss_ext_discount_amt / NULLIF(ss.ss_ext_sales_price, 0)) AS store_avg_discount_rate
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_customer_sk
),
catalog_sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        MAX(d.d_year) AS last_catalog_year,
        AVG(cs.cs_ext_discount_amt / NULLIF(cs.cs_ext_sales_price, 0)) AS catalog_avg_discount_rate
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_bill_customer_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_net_paid) AS web_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        MAX(d.d_year) AS last_web_year,
        AVG(ws.ws_ext_discount_amt / NULLIF(ws.ws_ext_sales_price, 0)) AS web_avg_discount_rate
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_bill_customer_sk
),
customer_base AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_preferred_cust_flag,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_buy_potential,
        ib.ib_upper_bound - ib.ib_lower_bound AS income_range,
        COALESCE(cc.cc_manager, 'UNKNOWN') AS call_center_manager
    FROM customer c
    LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    LEFT JOIN call_center cc ON FALSE
),
combined_sales AS (
    SELECT
        cb.c_customer_sk,
        cb.full_name,
        COALESCE(ss.store_net_profit, 0) AS store_net_profit,
        COALESCE(cs.catalog_net_profit, 0) AS catalog_net_profit,
        COALESCE(ws.web_net_profit, 0) AS web_net_profit,
        COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0) AS total_net_profit,
        COALESCE(ss.store_net_paid, 0) + COALESCE(cs.catalog_net_paid, 0) + COALESCE(ws.web_net_paid, 0) AS total_net_paid,
        COALESCE(ss.store_orders, 0) AS store_orders,
        COALESCE(cs.catalog_orders, 0) AS catalog_orders,
        COALESCE(ws.web_orders, 0) AS web_orders,
        GREATEST(COALESCE(ss.last_store_year, 0), COALESCE(cs.last_catalog_year, 0), COALESCE(ws.last_web_year, 0)) AS last_purchase_year,
        COALESCE(ss.store_avg_discount_rate, 0) AS store_avg_discount,
        COALESCE(cs.catalog_avg_discount_rate, 0) AS catalog_avg_discount,
        COALESCE(ws.web_avg_discount_rate, 0) AS web_avg_discount,
        cb.c_preferred_cust_flag,
        cb.cd_gender,
        cb.cd_marital_status,
        cb.hd_buy_potential,
        cb.income_range,
        cb.call_center_manager
    FROM customer_base cb
    LEFT JOIN store_sales_agg ss ON ss.customer_sk = cb.c_customer_sk
    LEFT JOIN catalog_sales_agg cs ON cs.customer_sk = cb.c_customer_sk
    LEFT JOIN web_sales_agg ws ON ws.customer_sk = cb.c_customer_sk
),
customer_returns_flag AS (
    SELECT
        c.c_customer_sk,
        CASE
            WHEN EXISTS (SELECT 1 FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk AND sr.sr_return_quantity > 0)
              OR EXISTS (SELECT 1 FROM catalog_returns cr WHERE cr.cr_returning_customer_sk = c.c_customer_sk AND cr.cr_return_quantity > 0)
              OR EXISTS (SELECT 1 FROM web_returns wr WHERE wr.wr_refunded_customer_sk = c.c_customer_sk AND wr.wr_return_quantity > 0)
            THEN 'Y' ELSE 'N'
        END AS has_return
    FROM combined_sales c
),
customer_ranking AS (
    SELECT
        c.*,
        ROW_NUMBER() OVER (ORDER BY c.total_net_profit DESC) AS profit_rank
    FROM combined_sales c
    WHERE c.total_net_profit > 0
),
final_set AS (
    SELECT
        cr.profit_rank,
        cr.full_name,
        cr.total_net_profit,
        cr.total_net_paid,
        cr.last_purchase_year,
        cr.store_avg_discount,
        cr.catalog_avg_discount,
        cr.web_avg_discount,
        cr.c_preferred_cust_flag,
        cr.cd_gender,
        cr.cd_marital_status,
        cr.hd_buy_potential,
        cr.income_range,
        cr.call_center_manager,
        rf.has_return,
        CASE
            WHEN cr.store_net_profit = GREATEST(cr.store_net_profit, cr.catalog_net_profit, cr.web_net_profit) THEN 'STORE'
            WHEN cr.catalog_net_profit = GREATEST(cr.store_net_profit, cr.catalog_net_profit, cr.web_net_profit) THEN 'CATALOG'
            WHEN cr.web_net_profit = GREATEST(cr.store_net_profit, cr.catalog_net_profit, cr.web_net_profit) THEN 'WEB'
            ELSE 'NONE'
        END AS top_channel
    FROM customer_ranking cr
    LEFT JOIN customer_returns_flag rf ON rf.c_customer_sk = cr.c_customer_sk
)
SELECT *
FROM final_set
WHERE profit_rank <= 200
UNION ALL
SELECT
    NULL AS profit_rank,
    full_name,
    total_net_profit,
    total_net_paid,
    last_purchase_year,
    store_avg_discount,
    catalog_avg_discount,
    web_avg_discount,
    c_preferred_cust_flag,
    cd_gender,
    cd_marital_status,
    hd_buy_potential,
    income_range,
    call_center_manager,
    has_return,
    top_channel
FROM final_set
WHERE has_return = 'Y' AND profit_rank > 200 AND profit_rank <= 300
ORDER BY profit_rank NULLS LAST, total_net_profit DESC
