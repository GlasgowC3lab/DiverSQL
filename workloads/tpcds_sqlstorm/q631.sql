WITH date_range AS (
   SELECT d_date_sk, d_year, d_month_seq, d_moy, d_date
   FROM date_dim
   WHERE d_year BETWEEN 2000 AND 2002
),
sales_combined AS (
   SELECT
     ss.ss_sold_date_sk AS date_sk,
     ss.ss_store_sk AS store_sk,
     NULL AS call_center_sk,
     NULL AS web_page_sk,
     ss.ss_item_sk AS item_sk,
     ss.ss_customer_sk AS customer_sk,
     ss.ss_promo_sk AS promo_sk,
     ss.ss_quantity AS quantity,
     ss.ss_net_paid AS net_paid,
     ss.ss_net_profit AS net_profit,
     'store' AS channel
   FROM store_sales ss
   JOIN date_range dr ON ss.ss_sold_date_sk = dr.d_date_sk
   UNION ALL
   SELECT
     cs.cs_sold_date_sk AS date_sk,
     NULL AS store_sk,
     cs.cs_call_center_sk AS call_center_sk,
     NULL AS web_page_sk,
     cs.cs_item_sk AS item_sk,
     cs.cs_bill_customer_sk AS customer_sk,
     cs.cs_promo_sk AS promo_sk,
     cs.cs_quantity AS quantity,
     cs.cs_net_paid AS net_paid,
     cs.cs_net_profit AS net_profit,
     'catalog' AS channel
   FROM catalog_sales cs
   JOIN date_range dr ON cs.cs_sold_date_sk = dr.d_date_sk
   UNION ALL
   SELECT
     ws.ws_sold_date_sk AS date_sk,
     NULL AS store_sk,
     NULL AS call_center_sk,
     ws.ws_web_page_sk AS web_page_sk,
     ws.ws_item_sk AS item_sk,
     ws.ws_bill_customer_sk AS customer_sk,
     ws.ws_promo_sk AS promo_sk,
     ws.ws_quantity AS quantity,
     ws.ws_net_paid AS net_paid,
     ws.ws_net_profit AS net_profit,
     'web' AS channel
   FROM web_sales ws
   JOIN date_range dr ON ws.ws_sold_date_sk = dr.d_date_sk
),
returns_combined AS (
   SELECT
     sr.sr_returned_date_sk AS date_sk,
     sr.sr_store_sk AS store_sk,
     NULL AS call_center_sk,
     NULL AS web_page_sk,
     sr.sr_item_sk AS item_sk,
     sr.sr_customer_sk AS customer_sk,
     NULL AS promo_sk,
     -sr.sr_return_quantity AS quantity,
     -sr.sr_return_amt AS net_paid,
     -sr.sr_net_loss AS net_profit,
     'store' AS channel
   FROM store_returns sr
   JOIN date_range dr ON sr.sr_returned_date_sk = dr.d_date_sk
   UNION ALL
   SELECT
     cr.cr_returned_date_sk AS date_sk,
     NULL AS store_sk,
     cr.cr_call_center_sk AS call_center_sk,
     NULL AS web_page_sk,
     cr.cr_item_sk AS item_sk,
     cr.cr_refunded_customer_sk AS customer_sk,
     NULL AS promo_sk,
     -cr.cr_return_quantity AS quantity,
     -cr.cr_return_amount AS net_paid,
     -cr.cr_net_loss AS net_profit,
     'catalog' AS channel
   FROM catalog_returns cr
   JOIN date_range dr ON cr.cr_returned_date_sk = dr.d_date_sk
   UNION ALL
   SELECT
     wr.wr_returned_date_sk AS date_sk,
     NULL AS store_sk,
     NULL AS call_center_sk,
     wr.wr_web_page_sk AS web_page_sk,
     wr.wr_item_sk AS item_sk,
     wr.wr_refunded_customer_sk AS customer_sk,
     NULL AS promo_sk,
     -wr.wr_return_quantity AS quantity,
     -wr.wr_return_amt AS net_paid,
     -wr.wr_net_loss AS net_profit,
     'web' AS channel
   FROM web_returns wr
   JOIN date_range dr ON wr.wr_returned_date_sk = dr.d_date_sk
),
combined AS (
   SELECT * FROM sales_combined
   UNION ALL
   SELECT * FROM returns_combined
),
sales_aggregated AS (
   SELECT
     COALESCE(s.store_sk, s.call_center_sk, s.web_page_sk) AS entity_sk,
     CASE
       WHEN s.store_sk IS NOT NULL THEN 'store'
       WHEN s.call_center_sk IS NOT NULL THEN 'call_center'
       ELSE 'web_page'
     END AS entity_type,
     d.d_year,
     d.d_month_seq,
     i.i_item_sk,
     i.i_item_id,
     i.i_category,
     i.i_brand,
     SUM(s.quantity) AS total_quantity,
     SUM(s.net_paid) AS total_net_paid,
     SUM(s.net_profit) AS total_net_profit,
     SUM(CASE WHEN s.promo_sk IS NOT NULL THEN s.net_paid ELSE 0 END) AS promo_net_paid,
     COUNT(DISTINCT s.customer_sk) AS distinct_customers
   FROM combined s
   JOIN date_dim d ON s.date_sk = d.d_date_sk
   JOIN item i ON s.item_sk = i.i_item_sk
   GROUP BY
     COALESCE(s.store_sk, s.call_center_sk, s.web_page_sk),
     CASE
       WHEN s.store_sk IS NOT NULL THEN 'store'
       WHEN s.call_center_sk IS NOT NULL THEN 'call_center'
       ELSE 'web_page'
     END,
     d.d_year,
     d.d_month_seq,
     i.i_item_sk,
     i.i_item_id,
     i.i_category,
     i.i_brand
),
item_rank AS (
   SELECT
     entity_sk,
     entity_type,
     d_year,
     d_month_seq,
     i_item_id,
     i_category,
     i_brand,
     total_net_profit,
     ROW_NUMBER() OVER (PARTITION BY entity_sk, d_year, d_month_seq ORDER BY total_net_profit DESC) AS rn
   FROM sales_aggregated
),
top_items AS (
   SELECT
     entity_sk,
     entity_type,
     d_year,
     d_month_seq,
     ARRAY_AGG(i_item_id ORDER BY total_net_profit DESC) FILTER (WHERE rn <= 5) AS top_5_items,
     ARRAY_AGG(total_net_profit ORDER BY total_net_profit DESC) FILTER (WHERE rn <= 5) AS top_5_profits
   FROM item_rank
   GROUP BY entity_sk, entity_type, d_year, d_month_seq
),
final AS (
   SELECT
     sa.entity_sk,
     sa.entity_type,
     sa.d_year,
     sa.d_month_seq,
     SUM(sa.total_quantity) AS sum_quantity,
     SUM(sa.total_net_paid) AS sum_net_paid,
     SUM(sa.total_net_profit) AS sum_net_profit,
     SUM(sa.promo_net_paid) AS sum_promo_net_paid,
     SUM(sa.distinct_customers) AS sum_distinct_customers,
     ti.top_5_items,
     ti.top_5_profits,
     CASE WHEN SUM(sa.total_net_paid) = 0 THEN 0 ELSE SUM(sa.promo_net_paid) / SUM(sa.total_net_paid) END AS promo_share
   FROM sales_aggregated sa
   LEFT JOIN top_items ti
     ON sa.entity_sk = ti.entity_sk
        AND sa.entity_type = ti.entity_type
        AND sa.d_year = ti.d_year
        AND sa.d_month_seq = ti.d_month_seq
   GROUP BY
     sa.entity_sk,
     sa.entity_type,
     sa.d_year,
     sa.d_month_seq,
     ti.top_5_items,
     ti.top_5_profits
)
SELECT
  f.entity_type,
  CASE
    WHEN f.entity_type = 'store' THEN st.s_store_name
    WHEN f.entity_type = 'call_center' THEN cc.cc_name
    ELSE wp.wp_url
  END AS entity_name,
  f.d_year,
  f.d_month_seq,
  f.sum_quantity,
  f.sum_net_paid,
  f.sum_net_profit,
  f.promo_share,
  f.top_5_items,
  f.top_5_profits
FROM final f
LEFT JOIN store st ON f.entity_type = 'store' AND f.entity_sk = st.s_store_sk
LEFT JOIN call_center cc ON f.entity_type = 'call_center' AND f.entity_sk = cc.cc_call_center_sk
LEFT JOIN web_page wp ON f.entity_type = 'web_page' AND f.entity_sk = wp.wp_web_page_sk
ORDER BY f.entity_type, f.d_year, f.d_month_seq
LIMIT 100
