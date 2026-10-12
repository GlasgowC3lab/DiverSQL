WITH
  sales AS (
    SELECT
      'store' AS channel,
      ss.ss_sold_date_sk AS date_sk,
      ss.ss_item_sk AS item_sk,
      ss.ss_store_sk AS store_sk,
      CAST(NULL AS integer) AS cc_sk,
      CAST(NULL AS integer) AS wp_sk,
      ss.ss_promo_sk AS promo_sk,
      ss.ss_quantity AS quantity,
      ss.ss_net_paid_inc_tax AS net_paid,
      ss.ss_net_profit AS profit,
      ss.ss_ticket_number AS ticket_number
    FROM store_sales ss
    UNION ALL
    SELECT
      'catalog' AS channel,
      cs.cs_sold_date_sk AS date_sk,
      cs.cs_item_sk AS item_sk,
      CAST(NULL AS integer) AS store_sk,
      cs.cs_call_center_sk AS cc_sk,
      CAST(NULL AS integer) AS wp_sk,
      cs.cs_promo_sk AS promo_sk,
      cs.cs_quantity AS quantity,
      cs.cs_net_paid_inc_tax AS net_paid,
      cs.cs_net_profit AS profit,
      cs.cs_order_number AS ticket_number
    FROM catalog_sales cs
    UNION ALL
    SELECT
      'web' AS channel,
      ws.ws_sold_date_sk AS date_sk,
      ws.ws_item_sk AS item_sk,
      CAST(NULL AS integer) AS store_sk,
      CAST(NULL AS integer) AS cc_sk,
      ws.ws_web_page_sk AS wp_sk,
      ws.ws_promo_sk AS promo_sk,
      ws.ws_quantity AS quantity,
      ws.ws_net_paid_inc_tax AS net_paid,
      ws.ws_net_profit AS profit,
      ws.ws_order_number AS ticket_number
    FROM web_sales ws
  ),
  returns AS (
    SELECT
      'store' AS channel,
      sr.sr_returned_date_sk AS date_sk,
      sr.sr_item_sk AS item_sk,
      sr.sr_store_sk AS store_sk,
      CAST(NULL AS integer) AS cc_sk,
      CAST(NULL AS integer) AS wp_sk,
      sr.sr_return_quantity AS quantity,
      sr.sr_return_amt_inc_tax AS net_amount,
      sr.sr_net_loss AS net_loss,
      sr.sr_ticket_number AS ticket_number
    FROM store_returns sr
    UNION ALL
    SELECT
      'catalog' AS channel,
      cr.cr_returned_date_sk AS date_sk,
      cr.cr_item_sk AS item_sk,
      CAST(NULL AS integer) AS store_sk,
      cr.cr_call_center_sk AS cc_sk,
      CAST(NULL AS integer) AS wp_sk,
      cr.cr_return_quantity AS quantity,
      cr.cr_return_amt_inc_tax AS net_amount,
      cr.cr_net_loss AS net_loss,
      cr.cr_order_number AS ticket_number
    FROM catalog_returns cr
    UNION ALL
    SELECT
      'web' AS channel,
      wr.wr_returned_date_sk AS date_sk,
      wr.wr_item_sk AS item_sk,
      CAST(NULL AS integer) AS store_sk,
      CAST(NULL AS integer) AS cc_sk,
      wr.wr_web_page_sk AS wp_sk,
      wr.wr_return_quantity AS quantity,
      wr.wr_return_amt_inc_tax AS net_amount,
      wr.wr_net_loss AS net_loss,
      wr.wr_order_number AS ticket_number
    FROM web_returns wr
  ),
  sales_agg AS (
    SELECT
      s.channel,
      d.d_year,
      d.d_moy AS month,
      i.i_category,
      i.i_class,
      i.i_brand,
      COALESCE(st.s_store_name, cc.cc_name, wp.wp_type) AS entity_name,
      SUM(s.quantity) AS total_quantity,
      SUM(s.net_paid) AS total_sales_amount,
      SUM(s.profit) AS total_profit
    FROM sales s
    LEFT JOIN date_dim d ON s.date_sk = d.d_date_sk
    LEFT JOIN item i ON s.item_sk = i.i_item_sk
    LEFT JOIN store st ON s.store_sk = st.s_store_sk
    LEFT JOIN call_center cc ON s.cc_sk = cc.cc_call_center_sk
    LEFT JOIN web_page wp ON s.wp_sk = wp.wp_web_page_sk
    GROUP BY
      s.channel,
      d.d_year,
      d.d_moy,
      i.i_category,
      i.i_class,
      i.i_brand,
      COALESCE(st.s_store_name, cc.cc_name, wp.wp_type)
  ),
  returns_agg AS (
    SELECT
      r.channel,
      d.d_year,
      d.d_moy AS month,
      i.i_category,
      i.i_class,
      i.i_brand,
      COALESCE(st.s_store_name, cc.cc_name, wp.wp_type) AS entity_name,
      SUM(r.quantity) AS total_return_quantity,
      SUM(r.net_amount) AS total_return_amount,
      SUM(r.net_loss) AS total_return_loss
    FROM returns r
    LEFT JOIN date_dim d ON r.date_sk = d.d_date_sk
    LEFT JOIN item i ON r.item_sk = i.i_item_sk
    LEFT JOIN store st ON r.store_sk = st.s_store_sk
    LEFT JOIN call_center cc ON r.cc_sk = cc.cc_call_center_sk
    LEFT JOIN web_page wp ON r.wp_sk = wp.wp_web_page_sk
    GROUP BY
      r.channel,
      d.d_year,
      d.d_moy,
      i.i_category,
      i.i_class,
      i.i_brand,
      COALESCE(st.s_store_name, cc.cc_name, wp.wp_type)
  )
SELECT
  COALESCE(s.channel, r.channel) AS channel,
  COALESCE(s.d_year, r.d_year) AS year,
  COALESCE(s.month, r.month) AS month,
  COALESCE(s.i_category, r.i_category) AS category,
  COALESCE(s.i_class, r.i_class) AS class,
  COALESCE(s.i_brand, r.i_brand) AS brand,
  COALESCE(s.entity_name, r.entity_name) AS entity_name,
  COALESCE(s.total_quantity, 0) AS total_quantity_sold,
  COALESCE(r.total_return_quantity, 0) AS total_quantity_returned,
  COALESCE(s.total_sales_amount, 0) AS total_sales_amount,
  COALESCE(r.total_return_amount, 0) AS total_return_amount,
  COALESCE(s.total_profit, 0) - COALESCE(r.total_return_loss, 0) AS net_profit_adjusted,
  (COALESCE(s.total_sales_amount, 0) - COALESCE(r.total_return_amount, 0)) AS net_sales_amount,
  SUM(COALESCE(s.total_sales_amount, 0) - COALESCE(r.total_return_amount, 0)) OVER (
    PARTITION BY COALESCE(s.channel, r.channel), COALESCE(s.entity_name, r.entity_name)
    ORDER BY COALESCE(s.d_year, r.d_year), COALESCE(s.month, r.month)
    ROWS UNBOUNDED PRECEDING
  ) AS running_net_sales
FROM sales_agg s
FULL OUTER JOIN returns_agg r
  ON s.channel = r.channel
  AND s.d_year = r.d_year
  AND s.month = r.month
  AND s.i_category = r.i_category
  AND s.i_class = r.i_class
  AND s.i_brand = r.i_brand
  AND s.entity_name = r.entity_name
WHERE COALESCE(s.d_year, r.d_year) BETWEEN 1999 AND 2002
ORDER BY channel, entity_name, year, month, net_sales_amount DESC
