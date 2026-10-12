WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
store_dates AS (
    SELECT s.s_store_sk,
           s.s_store_name,
           s.s_state,
           d.d_date_sk AS date_sk,
           d.d_year
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
),
call_center_dates AS (
    SELECT cc.cc_call_center_sk,
           cc.cc_name,
           cc.cc_state,
           d.d_date_sk AS date_sk,
           d.d_year
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
),
full_store_cc AS (
    SELECT COALESCE(sd.s_store_sk, ccd.cc_call_center_sk) AS entity_id,
           sd.s_store_name,
           sd.s_state AS store_state,
           ccd.cc_name,
           ccd.cc_state,
           COALESCE(sd.date_sk, ccd.date_sk) AS date_sk,
           COALESCE(sd.d_year, ccd.d_year) AS year
    FROM store_dates sd
    FULL OUTER JOIN call_center_dates ccd
        ON sd.date_sk = ccd.date_sk
),
base_data AS (
    SELECT cs.cs_order_number,
           cs.cs_sold_date_sk,
           cs.cs_item_sk,
           cs.cs_quantity,
           cs.cs_net_paid,
           cs.cs_net_profit,
           i.i_item_id,
           i.i_category,
           i.i_brand,
           i.i_units,
           d.d_date,
           d.d_year,
           cp.cp_catalog_page_id,
           sm.sm_type,
           p.p_promo_name,
           p.p_discount_active,
           inv.inv_quantity_on_hand,
           ws.ws_order_number,
           ws.ws_net_paid AS ws_net_paid,
           ws.ws_net_profit AS ws_net_profit,
           cr.cr_return_amount,
           CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status
    FROM sampled_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    WHERE d.d_date BETWEEN DATE '1999-01-01' AND DATE '1999-12-31'
      AND i.i_units = 'Pound'
      AND sm.sm_type = 'AIR'
      AND p.p_discount_active = 'Y'
      AND cs.cs_quantity > 5
      AND cs.cs_net_paid > 1000
)
SELECT bd.d_year,
       bd.i_category,
       bd.i_brand,
       bd.profit_status,
       SUM(bd.cs_net_paid) AS total_sales,
       AVG(bd.cs_quantity) AS avg_quantity,
       COUNT(DISTINCT bd.cs_order_number) AS distinct_orders,
       MIN(bd.cs_net_paid) AS min_sale,
       MAX(bd.cs_net_paid) AS max_sale,
       COUNT(*) FILTER (WHERE EXISTS (
           SELECT 1 FROM catalog_returns cr2
           WHERE cr2.cr_order_number = bd.cs_order_number
             AND cr2.cr_return_amount > 0
       )) AS orders_with_returns,
       CASE WHEN SUM(bd.cs_net_profit) > 0 THEN 'Overall Profitable' ELSE 'Overall Loss' END AS overall_profit_flag,
       fscc.store_state,
       fscc.cc_name
FROM base_data bd
LEFT JOIN full_store_cc fscc
    ON bd.cs_sold_date_sk = fscc.date_sk
GROUP BY bd.d_year,
         bd.i_category,
         bd.i_brand,
         bd.profit_status,
         fscc.store_state,
         fscc.cc_name
ORDER BY total_sales DESC
LIMIT 100
