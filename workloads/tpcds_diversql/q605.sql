/* Goal: Analyze 2001 store‑sales profitability and transaction counts, linking to web sales, catalog activity, promotions and demographics while demonstrating advanced Trino features (CTEs, TABLESAMPLE, set operations, FULL OUTER JOIN, EXISTS). */
WITH sampled_store_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)   -- sample 10 % of rows
),
common_orders AS (
    SELECT cs_order_number AS order_num FROM catalog_sales
    INTERSECT
    SELECT ss_ticket_number FROM sampled_store_sales
),
store_only_orders AS (
    SELECT ss_ticket_number FROM sampled_store_sales
    EXCEPT
    SELECT cs_order_number FROM catalog_sales
),
store_sales_joined AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_promo_sk,
        ss.ss_net_profit,
        d.d_year,
        t.t_hour,
        i.i_category,
        hd.hd_income_band_sk,
        ca.ca_state,
        p.p_promo_name
    FROM sampled_store_sales ss
    JOIN date_dim d      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t      ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i          ON ss.ss_item_sk      = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca       ON ss.ss_addr_sk  = ca.ca_address_sk
    JOIN promotion p               ON ss.ss_promo_sk = p.p_promo_sk
)
SELECT
    ssj.d_year,
    ssj.t_hour,
    ssj.i_category,
    COUNT(DISTINCT ssj.ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT ws.ws_order_number)   AS web_transactions,
    COUNT(DISTINCT cr.cr_order_number)   AS catalog_returns_cnt,
    SUM(ssj.ss_net_profit)               AS total_net_profit
FROM store_sales_joined ssj
FULL OUTER JOIN web_sales ws
    ON ws.ws_sold_date_sk = ssj.ss_sold_date_sk
   AND ws.ws_item_sk      = ssj.ss_item_sk
LEFT JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = ssj.ss_sold_date_sk
   AND cs.cs_item_sk      = ssj.ss_item_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ssj.ss_ticket_number
LEFT JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN promotion p2
    ON cs.cs_promo_sk = p2.p_promo_sk
LEFT JOIN customer_address ca2
    ON cs.cs_bill_addr_sk = ca2.ca_address_sk
LEFT JOIN household_demographics hd2
    ON cs.cs_bill_hdemo_sk = hd2.hd_demo_sk
LEFT JOIN store_only_orders soo
    ON ssj.ss_ticket_number = soo.ss_ticket_number
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs_sub
    WHERE cs_sub.cs_item_sk      = ssj.ss_item_sk
      AND cs_sub.cs_sold_date_sk = ssj.ss_sold_date_sk
      AND cs_sub.cs_quantity    > 0
)
  AND ssj.d_year = 2001
  AND ssj.ss_ticket_number IN (SELECT order_num FROM common_orders)
  AND soo.ss_ticket_number IS NULL
GROUP BY ssj.d_year, ssj.t_hour, ssj.i_category
HAVING SUM(ssj.ss_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
