/*
  Goal: Analyze total net revenue across store, catalog, and web channels for California stores in 2001, 
  focusing on high‑discount transactions, overnight shipments, and damage‑related returns. The query 
  samples store_sales, aggregates per store, applies a second‑level aggregation with window functions, 
  and excludes stores located in Texas via an anti‑semi‑join.
*/
WITH base AS (
    SELECT
        st.s_store_id,
        d.d_year,
        ss.ss_net_paid,
        cs.cs_net_paid,
        ws.ws_net_paid,
        ss.ss_ext_discount_amt,
        cs.cs_sales_price,
        ws.ws_quantity,
        sm.sm_type,
        r.r_reason_desc,
        st.s_state,
        ca.ca_state
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)  -- sample 10% of store_sales rows
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND st.s_state = 'CA'
      AND sm.sm_type = 'OVERNIGHT'
      AND r.r_reason_desc LIKE '%damage%'
      AND ss.ss_ext_discount_amt > 100
      AND cs.cs_sales_price > 50
      AND ws.ws_net_paid > 0
),
aggregated AS (
    SELECT
        s_store_id,
        d_year,
        SUM(ss_net_paid) AS sum_store_net,
        SUM(cs_net_paid) AS sum_catalog_net,
        SUM(ws_net_paid) AS sum_web_net,
        COUNT(*) AS txn_cnt
    FROM base
    GROUP BY s_store_id, d_year
)
SELECT
    s_store_id,
    d_year,
    sum_store_net,
    sum_catalog_net,
    sum_web_net,
    total_net,
    LAG(total_net) OVER (PARTITION BY d_year ORDER BY total_net) AS prev_total_net,
    SUM(total_net) OVER (PARTITION BY d_year ORDER BY total_net ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM (
    SELECT
        s_store_id,
        d_year,
        sum_store_net,
        sum_catalog_net,
        sum_web_net,
        (sum_store_net + sum_catalog_net + sum_web_net) AS total_net
    FROM aggregated
) t
WHERE s_store_id NOT IN (
    SELECT s_store_id FROM store WHERE s_state = 'TX'
)
AND (sum_store_net + sum_catalog_net + sum_web_net) > 1000
ORDER BY total_net DESC
LIMIT 100
