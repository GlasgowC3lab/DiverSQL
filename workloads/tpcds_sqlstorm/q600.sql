WITH
unified_sales AS (
   SELECT
      d.d_year,
      d.d_month_seq,
      i.i_category,
      i.i_brand,
      i.i_item_sk,
      'catalog' AS channel,
      cs.cs_order_number AS order_number,
      cs.cs_quantity AS quantity,
      cs.cs_net_paid AS net_paid,
      cs.cs_ext_discount_amt AS discount_amt,
      cs.cs_net_profit AS profit,
      p.p_promo_id,
      p.p_discount_active
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
   UNION ALL
   SELECT
      d.d_year,
      d.d_month_seq,
      i.i_category,
      i.i_brand,
      i.i_item_sk,
      'store' AS channel,
      ss.ss_ticket_number AS order_number,
      ss.ss_quantity AS quantity,
      ss.ss_net_paid AS net_paid,
      ss.ss_ext_discount_amt AS discount_amt,
      ss.ss_net_profit AS profit,
      p.p_promo_id,
      p.p_discount_active
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
   UNION ALL
   SELECT
      d.d_year,
      d.d_month_seq,
      i.i_category,
      i.i_brand,
      i.i_item_sk,
      'web' AS channel,
      ws.ws_order_number AS order_number,
      ws.ws_quantity AS quantity,
      ws.ws_net_paid AS net_paid,
      ws.ws_ext_discount_amt AS discount_amt,
      ws.ws_net_profit AS profit,
      p.p_promo_id,
      p.p_discount_active
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
),
unified_returns AS (
   SELECT
      d.d_year,
      d.d_month_seq,
      i.i_category,
      i.i_brand,
      i.i_item_sk,
      'catalog' AS channel,
      cr.cr_return_quantity AS return_quantity,
      cr.cr_net_loss AS net_loss
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
   UNION ALL
   SELECT
      d.d_year,
      d.d_month_seq,
      i.i_category,
      i.i_brand,
      i.i_item_sk,
      'store' AS channel,
      sr.sr_return_quantity AS return_quantity,
      sr.sr_net_loss AS net_loss
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
   UNION ALL
   SELECT
      d.d_year,
      d.d_month_seq,
      i.i_category,
      i.i_brand,
      i.i_item_sk,
      'web' AS channel,
      wr.wr_return_quantity AS return_quantity,
      wr.wr_net_loss AS net_loss
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
),
sales_agg AS (
   SELECT
      d_year,
      d_month_seq,
      i_category,
      i_brand,
      channel,
      SUM(quantity) AS total_quantity,
      SUM(net_paid) AS total_net_paid,
      SUM(discount_amt) AS total_discount,
      SUM(profit) AS total_profit
   FROM unified_sales
   GROUP BY d_year, d_month_seq, i_category, i_brand, channel
),
returns_agg AS (
   SELECT
      d_year,
      d_month_seq,
      i_category,
      i_brand,
      channel,
      SUM(return_quantity) AS total_return_quantity,
      SUM(net_loss) AS total_net_loss
   FROM unified_returns
   GROUP BY d_year, d_month_seq, i_category, i_brand, channel
),
combined AS (
   SELECT
      s.d_year,
      s.d_month_seq,
      s.i_category,
      s.i_brand,
      s.channel,
      s.total_quantity,
      s.total_net_paid,
      s.total_discount,
      s.total_profit,
      COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
      COALESCE(r.total_net_loss, 0) AS total_net_loss,
      s.total_net_paid - COALESCE(r.total_net_loss, 0) AS net_sales,
      s.total_profit - COALESCE(r.total_net_loss, 0) AS net_profit
   FROM sales_agg s
   LEFT JOIN returns_agg r
     ON s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
    AND s.i_category = r.i_category
    AND s.i_brand = r.i_brand
    AND s.channel = r.channel
),
ranked AS (
   SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY d_year, channel ORDER BY net_sales DESC) AS sales_rank,
      SUM(net_sales) OVER (PARTITION BY channel ORDER BY d_year, d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_sales
   FROM combined
)
SELECT
   d_year,
   d_month_seq,
   i_category,
   i_brand,
   channel,
   total_quantity,
   total_return_quantity,
   net_sales,
   net_profit,
   sales_rank,
   cumulative_net_sales
FROM ranked
WHERE sales_rank <= 5
ORDER BY d_year, d_month_seq, channel, sales_rank
