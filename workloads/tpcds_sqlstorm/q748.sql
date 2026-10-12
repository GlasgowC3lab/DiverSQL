WITH date_2002 AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_year = 2002
),
web_agg AS (
    SELECT ws.ws_bill_customer_sk AS cust_sk,
           SUM(ws.ws_net_profit) AS web_profit,
           SUM(ws.ws_quantity) AS web_qty,
           AVG(ws.ws_ext_discount_amt) AS web_avg_disc,
           MAX(d.d_date) AS web_last_date,
           COUNT(DISTINCT ws.ws_item_sk) AS web_items,
           MIN(ws.ws_order_number) AS web_first_order,
           MAX(ws.ws_order_number) AS web_last_order
    FROM web_sales ws
    LEFT JOIN date_2002 d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY ws.ws_bill_customer_sk
),
store_agg AS (
    SELECT ss.ss_customer_sk AS cust_sk,
           SUM(ss.ss_net_profit) AS store_profit,
           SUM(ss.ss_quantity) AS store_qty,
           AVG(ss.ss_ext_discount_amt) AS store_avg_disc,
           MAX(d.d_date) AS store_last_date,
           COUNT(DISTINCT ss.ss_item_sk) AS store_items,
           MIN(ss.ss_ticket_number) AS store_first_ticket,
           MAX(ss.ss_ticket_number) AS store_last_ticket
    FROM store_sales ss
    LEFT JOIN date_2002 d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY ss.ss_customer_sk
),
catalog_agg AS (
    SELECT cs.cs_bill_customer_sk AS cust_sk,
           SUM(cs.cs_net_profit) AS catalog_profit,
           SUM(cs.cs_quantity) AS catalog_qty,
           AVG(cs.cs_ext_discount_amt) AS catalog_avg_disc,
           MAX(d.d_date) AS catalog_last_date,
           COUNT(DISTINCT cs.cs_item_sk) AS catalog_items,
           MIN(cs.cs_order_number) AS catalog_first_order,
           MAX(cs.cs_order_number) AS catalog_last_order
    FROM catalog_sales cs
    LEFT JOIN date_2002 d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY cs.cs_bill_customer_sk
),
returns_agg AS (
    SELECT cust_sk,
           SUM(ret_cnt) AS total_returns
    FROM (
        SELECT sr.sr_customer_sk AS cust_sk, COUNT(*) AS ret_cnt
        FROM store_returns sr
        GROUP BY sr.sr_customer_sk
        UNION ALL
        SELECT cr.cr_returning_customer_sk AS cust_sk, COUNT(*) AS ret_cnt
        FROM catalog_returns cr
        GROUP BY cr.cr_returning_customer_sk
        UNION ALL
        SELECT wr.wr_returning_customer_sk AS cust_sk, COUNT(*) AS ret_cnt
        FROM web_returns wr
        GROUP BY wr.wr_returning_customer_sk
    ) t
    GROUP BY cust_sk
),
customer_total AS (
    SELECT 
        COALESCE(w.cust_sk, s.cust_sk, c.cust_sk) AS cust_sk,
        COALESCE(w.web_profit, 0) + COALESCE(s.store_profit, 0) + COALESCE(c.catalog_profit, 0) AS total_profit,
        COALESCE(w.web_qty, 0) + COALESCE(s.store_qty, 0) + COALESCE(c.catalog_qty, 0) AS total_qty,
        GREATEST(
            COALESCE(w.web_last_date, DATE '1900-01-01'),
            COALESCE(s.store_last_date, DATE '1900-01-01'),
            COALESCE(c.catalog_last_date, DATE '1900-01-01')
        ) AS most_recent_sale,
        COALESCE(w.web_items, 0) + COALESCE(s.store_items, 0) + COALESCE(c.catalog_items, 0) AS total_items,
        CASE 
            WHEN (COALESCE(w.web_qty,0) + COALESCE(s.store_qty,0) + COALESCE(c.catalog_qty,0)) = 0 THEN NULL
            ELSE (COALESCE(w.web_avg_disc,0) * COALESCE(w.web_qty,0) + COALESCE(s.store_avg_disc,0) * COALESCE(s.store_qty,0) + COALESCE(c.catalog_avg_disc,0) * COALESCE(c.catalog_qty,0)) / CAST((COALESCE(w.web_qty,0) + COALESCE(s.store_qty,0) + COALESCE(c.catalog_qty,0)) AS double)
        END AS weighted_avg_discount
    FROM web_agg w
    FULL OUTER JOIN store_agg s ON w.cust_sk = s.cust_sk
    FULL OUTER JOIN catalog_agg c ON COALESCE(w.cust_sk, s.cust_sk) = c.cust_sk
),
customer_enriched AS (
    SELECT 
        ca.c_customer_sk,
        ca.c_first_name,
        ca.c_last_name,
        ca.c_email_address,
        ca.c_preferred_cust_flag,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ct.total_profit,
        ct.total_qty,
        ct.most_recent_sale,
        ct.total_items,
        ct.weighted_avg_discount,
        r.total_returns,
        caaddr.ca_state,
        cc.cc_name AS support_center_name,
        ROW_NUMBER() OVER (PARTITION BY ca.c_customer_sk ORDER BY ct.most_recent_sale DESC NULLS LAST) AS rn_recent
    FROM customer ca
    LEFT JOIN customer_demographics cd ON ca.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON ca.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN customer_total ct ON ca.c_customer_sk = ct.cust_sk
    LEFT JOIN returns_agg r ON ca.c_customer_sk = r.cust_sk
    LEFT JOIN customer_address caaddr ON ca.c_current_addr_sk = caaddr.ca_address_sk
    LEFT JOIN call_center cc ON caaddr.ca_state = cc.cc_state
    WHERE ca.c_customer_sk IS NOT NULL
)
SELECT 
    ce.c_customer_sk,
    CONCAT(ce.c_first_name, ' ', ce.c_last_name) AS full_name,
    CASE WHEN ce.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Regular' END AS customer_tier,
    ce.c_email_address,
    ce.cd_gender,
    ce.cd_marital_status,
    COALESCE(ce.ib_lower_bound, -1) AS income_lower,
    COALESCE(ce.ib_upper_bound, -1) AS income_upper,
    COALESCE(ce.support_center_name, 'Unassigned') AS support_center,
    ROUND(ce.total_profit, 2) AS total_profit,
    ce.total_qty,
    ce.total_items,
    ROUND(ce.weighted_avg_discount, 4) AS weighted_avg_discount,
    ce.total_returns,
    ce.most_recent_sale,
    CASE 
        WHEN ce.total_profit > 0 THEN 'PROFITABLE'
        WHEN ce.total_profit = 0 THEN 'NEUTRAL'
        ELSE 'LOSS' 
    END AS profit_status,
    (SELECT i.i_product_name
     FROM catalog_sales cs2
     JOIN item i ON cs2.cs_item_sk = i.i_item_sk
     WHERE cs2.cs_bill_customer_sk = ce.c_customer_sk
     ORDER BY cs2.cs_sold_date_sk DESC
     LIMIT 1) AS last_item_purchased,
    ROW_NUMBER() OVER (ORDER BY ce.total_profit DESC) AS profit_rank,
    CONCAT('Customer ', CAST(ce.c_customer_sk AS varchar), ': ', CONCAT(ce.c_first_name, ' ', ce.c_last_name), ' (', CASE WHEN ce.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Regular' END, ')') AS customer_summary
FROM customer_enriched ce
WHERE ce.total_profit IS NOT NULL
  AND (ce.total_returns IS NULL OR ce.total_returns < 5)
  AND (ce.c_email_address IS NOT NULL AND ce.c_email_address LIKE '%@%')
ORDER BY profit_rank
LIMIT 100
