WITH
date_range AS (
    SELECT d.d_date_sk,
           d.d_year AS year,
           d.d_moy AS month
    FROM date_dim d
    WHERE d.d_date >= DATE '1998-01-01' AND d.d_date <= DATE '2003-12-31'
),
catalog_agg AS (
    SELECT dr.year,
           dr.month,
           cc.cc_state AS state,
           i.i_category AS category,
           i.i_item_id AS item_id,
           SUM(cs.cs_quantity) AS qty_sold,
           SUM(cs.cs_net_paid) AS net_paid,
           SUM(cs.cs_net_profit) AS net_profit,
           AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    JOIN date_range dr ON cs.cs_sold_date_sk = dr.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY dr.year, dr.month, cc.cc_state, i.i_category, i.i_item_id
),
store_agg AS (
    SELECT dr.year,
           dr.month,
           s.s_state AS state,
           i.i_category AS category,
           i.i_item_id AS item_id,
           SUM(ss.ss_quantity) AS qty_sold,
           SUM(ss.ss_net_paid) AS net_paid,
           SUM(ss.ss_net_profit) AS net_profit,
           AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss
    JOIN date_range dr ON ss.ss_sold_date_sk = dr.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY dr.year, dr.month, s.s_state, i.i_category, i.i_item_id
),
web_agg AS (
    SELECT dr.year,
           dr.month,
           ws_site.web_state AS state,
           i.i_category AS category,
           i.i_item_id AS item_id,
           SUM(ws.ws_quantity) AS qty_sold,
           SUM(ws.ws_net_paid) AS net_paid,
           SUM(ws.ws_net_profit) AS net_profit,
           AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN date_range dr ON ws.ws_sold_date_sk = dr.d_date_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY dr.year, dr.month, ws_site.web_state, i.i_category, i.i_item_id
),
combined AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
),
state_monthly AS (
    SELECT year,
           month,
           state,
           SUM(qty_sold) AS total_qty,
           SUM(net_paid) AS total_net_paid,
           SUM(net_profit) AS total_net_profit,
           AVG(avg_discount) AS avg_discount_over_items
    FROM combined
    GROUP BY year, month, state
),
top_items AS (
    SELECT year,
           month,
           state,
           category,
           item_id,
           net_profit,
           ROW_NUMBER() OVER (PARTITION BY year, month, state ORDER BY net_profit DESC) AS rn
    FROM combined
)
SELECT sm.year,
       sm.month,
       sm.state,
       sm.total_qty,
       sm.total_net_paid,
       sm.total_net_profit,
       sm.avg_discount_over_items,
       ti.category,
       ti.item_id,
       ti.net_profit
FROM state_monthly sm
LEFT JOIN (
    SELECT year, month, state, category, item_id, net_profit
    FROM top_items
    WHERE rn <= 5
) ti
  ON ti.year = sm.year AND ti.month = sm.month AND ti.state = sm.state
ORDER BY sm.year, sm.month, sm.state, ti.net_profit DESC
