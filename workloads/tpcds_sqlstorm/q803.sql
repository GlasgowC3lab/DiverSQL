WITH sales_union AS (
  SELECT
    d.d_year,
    'store' AS channel,
    ss.ss_item_sk AS item_sk,
    i.i_product_name AS product_name,
    i.i_category AS category,
    i.i_brand AS brand,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit,
    ss.ss_ext_discount_amt AS discount_amt,
    ss.ss_quantity AS quantity
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  UNION ALL
  SELECT
    d.d_year,
    'catalog' AS channel,
    cs.cs_item_sk AS item_sk,
    i.i_product_name AS product_name,
    i.i_category AS category,
    i.i_brand AS brand,
    cs.cs_net_paid AS net_paid,
    cs.cs_net_profit AS net_profit,
    cs.cs_ext_discount_amt AS discount_amt,
    cs.cs_quantity AS quantity
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  UNION ALL
  SELECT
    d.d_year,
    'web' AS channel,
    ws.ws_item_sk AS item_sk,
    i.i_product_name AS product_name,
    i.i_category AS category,
    i.i_brand AS brand,
    ws.ws_net_paid AS net_paid,
    ws.ws_net_profit AS net_profit,
    ws.ws_ext_discount_amt AS discount_amt,
    ws.ws_quantity AS quantity
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
returns_agg AS (
  SELECT
    d.d_year,
    r.item_sk,
    SUM(r.net_loss) AS total_return_loss
  FROM (
    SELECT sr_returned_date_sk AS returned_date_sk,
           sr_item_sk AS item_sk,
           sr_net_loss AS net_loss
    FROM store_returns
    UNION ALL
    SELECT cr_returned_date_sk,
           cr_item_sk,
           cr_net_loss
    FROM catalog_returns
    UNION ALL
    SELECT wr_returned_date_sk,
           wr_item_sk,
           wr_net_loss
    FROM web_returns
  ) r
  JOIN date_dim d ON r.returned_date_sk = d.d_date_sk
  GROUP BY d.d_year, r.item_sk
),
sales_totals AS (
  SELECT
    s.d_year,
    s.channel,
    s.item_sk,
    s.product_name,
    s.category,
    s.brand,
    SUM(s.net_paid) AS total_net_paid,
    SUM(s.net_profit) AS total_net_profit,
    SUM(s.discount_amt) AS total_discount,
    SUM(s.quantity) AS total_quantity
  FROM sales_union s
  GROUP BY s.d_year, s.channel, s.item_sk, s.product_name, s.category, s.brand
),
sales_agg AS (
  SELECT
    st.d_year,
    st.channel,
    st.item_sk,
    st.product_name,
    st.category,
    st.brand,
    st.total_net_paid,
    st.total_net_profit,
    st.total_discount,
    st.total_quantity,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    st.total_net_profit - COALESCE(r.total_return_loss, 0) AS adjusted_net_profit
  FROM sales_totals st
  LEFT JOIN returns_agg r
    ON st.d_year = r.d_year AND st.item_sk = r.item_sk
),
ranked_sales AS (
  SELECT
    a.*,
    ROW_NUMBER() OVER (PARTITION BY a.d_year, a.channel ORDER BY a.adjusted_net_profit DESC) AS profit_rank,
    LAG(a.adjusted_net_profit) OVER (PARTITION BY a.d_year, a.channel ORDER BY a.adjusted_net_profit DESC) AS prev_adjusted_profit,
    CASE
      WHEN LAG(a.adjusted_net_profit) OVER (PARTITION BY a.d_year, a.channel ORDER BY a.adjusted_net_profit DESC) = 0 THEN NULL
      ELSE (a.adjusted_net_profit - LAG(a.adjusted_net_profit) OVER (PARTITION BY a.d_year, a.channel ORDER BY a.adjusted_net_profit DESC))
           / LAG(a.adjusted_net_profit) OVER (PARTITION BY a.d_year, a.channel ORDER BY a.adjusted_net_profit DESC)
    END AS profit_change_ratio,
    (a.total_discount / NULLIF(a.total_net_paid, 0)) AS avg_discount_rate
  FROM sales_agg a
)
SELECT
  d_year,
  channel,
  profit_rank,
  item_sk,
  product_name,
  category,
  brand,
  total_net_paid,
  total_net_profit,
  adjusted_net_profit,
  total_return_loss,
  total_quantity,
  avg_discount_rate,
  prev_adjusted_profit,
  profit_change_ratio
FROM ranked_sales
WHERE profit_rank <= 5
ORDER BY d_year, channel, profit_rank
