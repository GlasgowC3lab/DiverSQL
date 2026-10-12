WITH base AS (
   SELECT
       i.i_item_sk,
       i.i_category,
       i.i_brand,
       i.i_color,
       i.i_size,
       ca.ca_state,
       ca.ca_zip,
       hd.hd_income_band_sk,
       p.p_discount_active,
       cs.cs_net_profit AS cs_net_profit,
       ss.ss_net_profit AS ss_net_profit,
       ws.ws_net_profit AS ws_net_profit,
       cr.cr_net_loss AS cr_net_loss,
       sr.sr_net_loss AS sr_net_loss,
       wr.wr_net_loss AS wr_net_loss
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = i.i_item_sk
   JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = i.i_item_sk
   JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
   JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = i.i_item_sk
   JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
   WHERE
       i.i_color IN ('Red', 'Blue')
       AND i.i_size = 'M'
       AND ca.ca_state = 'CA'
       AND substr(ca.ca_zip, 1, 1) = '9'
       AND hd.hd_income_band_sk > 5
       AND p.p_discount_active = 'Y'
),
profit_agg AS (
   SELECT i_category,
          SUM(cs_net_profit + ss_net_profit + ws_net_profit) AS metric
   FROM base
   GROUP BY i_category
),
loss_agg AS (
   SELECT i_category,
          SUM(cr_net_loss + sr_net_loss + wr_net_loss) AS metric
   FROM base
   GROUP BY i_category
),
union_data AS (
   SELECT i_category, metric, 'profit' AS metric_type FROM profit_agg
   UNION
   SELECT i_category, metric, 'loss'   AS metric_type FROM loss_agg
)
SELECT
   i_category,
   metric_type,
   metric,
   SUM(metric) OVER (PARTITION BY i_category) AS category_total,
   SUM(metric) OVER (ORDER BY i_category ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM union_data
ORDER BY i_category, metric_type
LIMIT 100
