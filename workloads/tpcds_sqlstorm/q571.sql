WITH sales_all AS (
  SELECT cs.cs_sold_date_sk AS date_sk,
         cs.cs_item_sk AS item_sk,
         cs.cs_order_number AS order_no,
         cs.cs_quantity AS quantity,
         cs.cs_ext_sales_price AS ext_sales,
         cs.cs_net_profit AS profit,
         cs.cs_call_center_sk AS channel_sk,
         'catalog' AS channel
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_sold_date_sk AS date_sk,
         ss.ss_item_sk AS item_sk,
         ss.ss_ticket_number AS order_no,
         ss.ss_quantity AS quantity,
         ss.ss_ext_sales_price AS ext_sales,
         ss.ss_net_profit AS profit,
         ss.ss_store_sk AS channel_sk,
         'store' AS channel
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_sold_date_sk AS date_sk,
         ws.ws_item_sk AS item_sk,
         ws.ws_order_number AS order_no,
         ws.ws_quantity AS quantity,
         ws.ws_ext_sales_price AS ext_sales,
         ws.ws_net_profit AS profit,
         ws.ws_web_page_sk AS channel_sk,
         'web' AS channel
  FROM web_sales ws
),
returns_all AS (
  SELECT cr.cr_item_sk AS item_sk,
         cr.cr_return_quantity AS return_qty,
         cr.cr_return_amount AS return_amt,
         'catalog' AS channel
  FROM catalog_returns cr
  UNION ALL
  SELECT sr.sr_item_sk AS item_sk,
         sr.sr_return_quantity AS return_qty,
         sr.sr_return_amt AS return_amt,
         'store' AS channel
  FROM store_returns sr
  UNION ALL
  SELECT wr.wr_item_sk AS item_sk,
         wr.wr_return_quantity AS return_qty,
         wr.wr_return_amt AS return_amt,
         'web' AS channel
  FROM web_returns wr
),
aggregated_sales AS (
  SELECT
    s.item_sk,
    i.i_product_name AS product_name,
    i.i_brand AS brand,
    i.i_category AS category,
    d.d_year AS sale_year,
    d.d_month_seq AS month_seq,
    s.channel,
    SUM(s.quantity) AS total_qty,
    SUM(s.ext_sales) AS total_sales,
    SUM(s.profit) AS total_profit,
    COALESCE(SUM(r.return_qty),0) AS total_return_qty,
    COALESCE(SUM(r.return_amt),0) AS total_return_amt,
    CASE WHEN SUM(s.ext_sales) = 0 THEN 0 ELSE 1 - COALESCE(SUM(r.return_amt),0)/SUM(s.ext_sales) END AS net_sales_ratio,
    CONCAT(i.i_brand,'_',i.i_category) AS brand_category_key,
    CASE WHEN i.i_color IS NULL THEN 'UNKNOWN' ELSE i.i_color END AS item_color,
    MAX(s.date_sk) AS max_date_sk
  FROM sales_all s
  LEFT JOIN returns_all r
    ON s.item_sk = r.item_sk
   AND s.channel = r.channel
  JOIN item i
    ON s.item_sk = i.i_item_sk
  JOIN date_dim d
    ON s.date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
    AND (i.i_brand LIKE 'B%' OR i.i_category LIKE '%ELECTRONICS%')
    AND COALESCE(i.i_color,'') <> ''
  GROUP BY
    s.item_sk,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    d.d_year,
    d.d_month_seq,
    s.channel,
    i.i_color
),
ranked_sales AS (
  SELECT
    a.*,
    ROW_NUMBER() OVER (PARTITION BY a.channel ORDER BY a.total_sales DESC) AS channel_rank,
    ROW_NUMBER() OVER (PARTITION BY a.channel ORDER BY a.total_profit DESC) AS profit_rank,
    PERCENT_RANK() OVER (PARTITION BY a.channel ORDER BY a.total_sales) AS sales_percentile,
    CASE WHEN a.total_return_qty > 0 THEN a.total_return_amt / a.total_return_qty ELSE NULL END AS avg_return_amount,
    (a.total_sales - a.total_return_amt) AS net_sales,
    a.net_sales_ratio * 100 AS net_sales_percent,
    (SELECT AVG(p.p_cost) FROM promotion p WHERE p.p_item_sk = a.item_sk) AS avg_promo_cost,
    EXISTS (
      SELECT 1
      FROM promotion p2
      WHERE p2.p_item_sk = a.item_sk
        AND p2.p_start_date_sk <= a.max_date_sk
        AND p2.p_end_date_sk >= a.max_date_sk
    ) AS promo_active
  FROM aggregated_sales a
),
selected_sales AS (
  SELECT *
  FROM ranked_sales
  WHERE channel_rank <= 10
)

SELECT
  s.channel,
  s.brand_category_key,
  s.item_color,
  s.product_name,
  s.brand,
  s.category,
  s.sale_year,
  s.month_seq,
  s.total_qty,
  s.total_sales,
  s.total_profit,
  s.total_return_qty,
  s.total_return_amt,
  s.net_sales,
  round(s.net_sales_percent,2) AS net_sales_percent,
  s.profit_rank,
  round(s.sales_percentile,4) AS sales_percentile,
  CASE WHEN s.avg_return_amount IS NULL THEN 'N/A' ELSE CAST(round(s.avg_return_amount,2) AS VARCHAR) END AS avg_return_amount_str,
  round(s.avg_promo_cost,2) AS avg_promo_cost,
  CASE WHEN s.promo_active THEN 'YES' ELSE 'NO' END AS promo_active_flag
FROM selected_sales s
LEFT JOIN (
  SELECT channel, MAX(total_sales) AS max_sales
  FROM aggregated_sales
  GROUP BY channel
) max_by_channel
  ON s.channel = max_by_channel.channel
WHERE s.total_sales > 0.1 * COALESCE(max_by_channel.max_sales,0)
ORDER BY s.channel, s.profit_rank
LIMIT 100
