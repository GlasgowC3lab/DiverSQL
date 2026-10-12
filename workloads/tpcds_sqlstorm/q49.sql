WITH sales_union AS (
    SELECT ss_sold_date_sk AS date_sk,
           ss_item_sk AS item_sk,
           ss_store_sk AS channel_sk,
           ss_net_profit AS net_profit,
           ss_net_paid AS net_paid,
           ss_quantity AS quantity,
           'store' AS sales_channel
    FROM store_sales
    UNION ALL
    SELECT cs_sold_date_sk,
           cs_item_sk,
           cs_call_center_sk,
           cs_net_profit,
           cs_net_paid,
           cs_quantity,
           'catalog' AS sales_channel
    FROM catalog_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_web_page_sk,
           ws_net_profit,
           ws_net_paid,
           ws_quantity,
           'web' AS sales_channel
    FROM web_sales
), returns_union AS (
    SELECT sr_returned_date_sk AS date_sk,
           sr_item_sk AS item_sk,
           sr_store_sk AS channel_sk,
           sr_net_loss AS net_loss,
           sr_return_quantity AS return_qty,
           'store' AS return_channel
    FROM store_returns
    UNION ALL
    SELECT cr_returned_date_sk,
           cr_item_sk,
           cr_call_center_sk,
           cr_net_loss,
           cr_return_quantity,
           'catalog' AS return_channel
    FROM catalog_returns
    UNION ALL
    SELECT wr_returned_date_sk,
           wr_item_sk,
           wr_web_page_sk,
           wr_net_loss,
           wr_return_quantity,
           'web' AS return_channel
    FROM web_returns
), returns_agg AS (
    SELECT date_sk,
           item_sk,
           channel_sk,
           SUM(net_loss) AS total_net_loss,
           SUM(return_qty) AS total_return_qty
    FROM returns_union
    GROUP BY date_sk, item_sk, channel_sk
), sales_agg AS (
    SELECT date_sk,
           item_sk,
           channel_sk,
           sales_channel,
           SUM(net_profit) AS total_net_profit,
           SUM(net_paid) AS total_net_paid,
           SUM(quantity) AS total_quantity
    FROM sales_union
    GROUP BY date_sk, item_sk, channel_sk, sales_channel
), sales_with_returns AS (
    SELECT s.date_sk,
           s.item_sk,
           s.channel_sk,
           s.sales_channel,
           s.total_net_profit,
           s.total_net_paid,
           s.total_quantity,
           COALESCE(r.total_net_loss, 0) AS total_net_loss,
           COALESCE(r.total_return_qty, 0) AS total_return_qty,
           s.total_net_profit - COALESCE(r.total_net_loss, 0) AS net_profit_after_returns
    FROM sales_agg s
    LEFT JOIN returns_agg r
      ON s.date_sk = r.date_sk
     AND s.item_sk = r.item_sk
     AND s.channel_sk = r.channel_sk
), ranked_sales AS (
    SELECT swr.*,
           d.d_date AS sale_date,
           d.d_year,
           d.d_month_seq,
           i.i_product_name,
           i.i_brand,
           CONCAT(i.i_brand, ' ', i.i_product_name) AS full_product_name,
           ROW_NUMBER() OVER (PARTITION BY d.d_date, swr.sales_channel ORDER BY swr.net_profit_after_returns DESC) AS rank_per_channel
    FROM sales_with_returns swr
    LEFT JOIN date_dim d
      ON swr.date_sk = d.d_date_sk
    LEFT JOIN item i
      ON swr.item_sk = i.i_item_sk
), top_sales AS (
    SELECT rs.sale_date,
           rs.sales_channel,
           rs.full_product_name,
           rs.i_brand,
           rs.i_product_name,
           rs.total_quantity,
           rs.total_net_paid,
           rs.net_profit_after_returns,
           CASE WHEN rs.total_net_paid = 0 THEN NULL ELSE rs.net_profit_after_returns / rs.total_net_paid END AS profit_margin,
           CASE
               WHEN rs.total_net_paid = 0 THEN 'ZeroRevenue'
               WHEN rs.net_profit_after_returns / NULLIF(rs.total_net_paid, 0) > 0.2 THEN 'High'
               WHEN rs.net_profit_after_returns / NULLIF(rs.total_net_paid, 0) > 0.1 THEN 'Medium'
               ELSE 'Low'
           END AS profit_margin_category,
           (SELECT AVG(swr2.net_profit_after_returns)
            FROM sales_with_returns swr2
            WHERE swr2.item_sk = rs.item_sk
              AND swr2.date_sk >= rs.date_sk - 30
              AND swr2.date_sk < rs.date_sk) AS avg_profit_last_30d,
           CASE WHEN EXISTS (
               SELECT 1 FROM promotion p
               WHERE p.p_item_sk = rs.item_sk
                 AND rs.date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
           ) THEN 1 ELSE 0 END AS is_promo_active,
           CASE WHEN rs.rank_per_channel <= 3 THEN 'Top3' ELSE '' END AS rank_tag,
           rs.rank_per_channel,
           rs.item_sk,
           rs.date_sk
    FROM ranked_sales rs
    WHERE rs.rank_per_channel <= 10
)
SELECT sale_date,
       sales_channel,
       full_product_name,
       i_brand,
       i_product_name,
       total_quantity,
       total_net_paid,
       net_profit_after_returns,
       profit_margin,
       profit_margin_category,
       avg_profit_last_30d,
       is_promo_active,
       rank_tag,
       rank_per_channel
FROM top_sales
ORDER BY sale_date, sales_channel, rank_per_channel
