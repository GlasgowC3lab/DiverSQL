WITH catalog_sales_agg AS (
  SELECT
    d.d_year AS year,
    d.d_quarter_seq AS quarter_seq,
    i.i_category AS category,
    SUM(cs.cs_ext_sales_price) AS sales_amount,
    SUM(cs.cs_quantity) AS sales_qty,
    SUM(cs.cs_net_profit) AS net_profit,
    SUM(cs.cs_ext_discount_amt) AS discount_amount,
    MAX(CASE WHEN p.p_promo_id IS NOT NULL THEN 1 ELSE 0 END) AS has_promo
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, d.d_quarter_seq, i.i_category
),
store_sales_agg AS (
  SELECT
    d.d_year AS year,
    d.d_quarter_seq AS quarter_seq,
    i.i_category AS category,
    SUM(ss.ss_ext_sales_price) AS sales_amount,
    SUM(ss.ss_quantity) AS sales_qty,
    SUM(ss.ss_net_profit) AS net_profit,
    SUM(ss.ss_ext_discount_amt) AS discount_amount,
    MAX(CASE WHEN p.p_promo_id IS NOT NULL THEN 1 ELSE 0 END) AS has_promo
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, d.d_quarter_seq, i.i_category
),
web_sales_agg AS (
  SELECT
    d.d_year AS year,
    d.d_quarter_seq AS quarter_seq,
    i.i_category AS category,
    SUM(ws.ws_ext_sales_price) AS sales_amount,
    SUM(ws.ws_quantity) AS sales_qty,
    SUM(ws.ws_net_profit) AS net_profit,
    SUM(ws.ws_ext_discount_amt) AS discount_amount,
    MAX(CASE WHEN p.p_promo_id IS NOT NULL THEN 1 ELSE 0 END) AS has_promo
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, d.d_quarter_seq, i.i_category
),
sales_combined AS (
  SELECT * FROM catalog_sales_agg
  UNION ALL
  SELECT * FROM store_sales_agg
  UNION ALL
  SELECT * FROM web_sales_agg
),
sales_agg AS (
  SELECT
    year,
    quarter_seq,
    category,
    SUM(sales_amount) AS total_sales_amount,
    SUM(sales_qty) AS total_sales_qty,
    SUM(net_profit) AS total_net_profit,
    SUM(discount_amount) AS total_discount_amount,
    SUM(CASE WHEN has_promo = 1 THEN sales_amount ELSE 0 END) AS promo_sales_amount,
    SUM(CASE WHEN has_promo = 1 THEN net_profit ELSE 0 END) AS promo_net_profit,
    MAX(has_promo) AS has_promotion
  FROM sales_combined
  GROUP BY year, quarter_seq, category
),
returns_agg AS (
  SELECT
    d.d_year AS year,
    d.d_quarter_seq AS quarter_seq,
    i.i_category AS category,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(cr.cr_net_loss) AS total_return_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, d.d_quarter_seq, i.i_category

  UNION ALL

  SELECT
    d.d_year AS year,
    d.d_quarter_seq AS quarter_seq,
    i.i_category AS category,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    SUM(sr.sr_net_loss) AS total_return_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, d.d_quarter_seq, i.i_category

  UNION ALL

  SELECT
    d.d_year AS year,
    d.d_quarter_seq AS quarter_seq,
    i.i_category AS category,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    SUM(wr.wr_net_loss) AS total_return_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, d.d_quarter_seq, i.i_category
),
final_metrics AS (
  SELECT
    s.year,
    s.quarter_seq,
    s.category,
    s.total_sales_amount,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_sales_amount - COALESCE(r.total_return_amount, 0) AS net_sales_amount,
    s.total_sales_qty,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    s.total_sales_qty - COALESCE(r.total_return_qty, 0) AS net_quantity,
    s.total_net_profit - COALESCE(r.total_return_loss, 0) AS net_profit,
    s.total_discount_amount AS total_discount,
    s.promo_sales_amount,
    s.promo_net_profit,
    s.has_promotion,
    ROW_NUMBER() OVER (PARTITION BY s.year, s.quarter_seq ORDER BY s.total_net_profit - COALESCE(r.total_return_loss, 0) DESC) AS category_rank_in_quarter,
    SUM(s.total_net_profit - COALESCE(r.total_return_loss, 0)) OVER (PARTITION BY s.category ORDER BY s.year, s.quarter_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit_by_category
  FROM sales_agg s
  LEFT JOIN (
    SELECT
      year,
      quarter_seq,
      category,
      SUM(total_return_amount) AS total_return_amount,
      SUM(total_return_qty) AS total_return_qty,
      SUM(total_return_loss) AS total_return_loss
    FROM returns_agg
    GROUP BY year, quarter_seq, category
  ) r
    ON s.year = r.year AND s.quarter_seq = r.quarter_seq AND s.category = r.category
)
SELECT
  year,
  quarter_seq,
  category,
  net_sales_amount,
  net_quantity,
  net_profit,
  total_discount,
  promo_sales_amount,
  promo_net_profit,
  has_promotion,
  category_rank_in_quarter,
  cumulative_profit_by_category
FROM final_metrics
WHERE net_profit > 0
ORDER BY year, quarter_seq, net_profit DESC
