WITH sales AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    'store' AS channel,
    ss.ss_customer_sk AS customer_sk,
    ss.ss_item_sk AS item_sk,
    ss.ss_ticket_number AS order_number,
    ss.ss_net_profit AS net_profit,
    ss.ss_quantity AS quantity,
    ss.ss_sold_date_sk AS sold_date_sk
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    'catalog' AS channel,
    cs.cs_bill_customer_sk AS customer_sk,
    cs.cs_item_sk AS item_sk,
    cs.cs_order_number AS order_number,
    cs.cs_net_profit AS net_profit,
    cs.cs_quantity AS quantity,
    cs.cs_sold_date_sk AS sold_date_sk
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    'web' AS channel,
    ws.ws_bill_customer_sk AS customer_sk,
    ws.ws_item_sk AS item_sk,
    ws.ws_order_number AS order_number,
    ws.ws_net_profit AS net_profit,
    ws.ws_quantity AS quantity,
    ws.ws_sold_date_sk AS sold_date_sk
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
returns_raw AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    'store' AS channel,
    sr.sr_customer_sk AS customer_sk,
    sr.sr_item_sk AS item_sk,
    sr.sr_ticket_number AS order_number,
    sr.sr_net_loss AS net_loss,
    sr.sr_return_quantity AS quantity
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    'catalog' AS channel,
    cr.cr_returning_customer_sk AS customer_sk,
    cr.cr_item_sk AS item_sk,
    cr.cr_order_number AS order_number,
    cr.cr_net_loss AS net_loss,
    cr.cr_return_quantity AS quantity
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  UNION ALL
  SELECT
    d.d_year,
    d.d_month_seq,
    'web' AS channel,
    wr.wr_refunded_customer_sk AS customer_sk,
    wr.wr_item_sk AS item_sk,
    wr.wr_order_number AS order_number,
    wr.wr_net_loss AS net_loss,
    wr.wr_return_quantity AS quantity
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
),
returns AS (
  SELECT
    d_year,
    d_month_seq,
    channel,
    customer_sk,
    item_sk,
    order_number,
    SUM(net_loss) AS total_net_loss,
    SUM(quantity) AS total_return_quantity
  FROM returns_raw
  GROUP BY
    d_year,
    d_month_seq,
    channel,
    customer_sk,
    item_sk,
    order_number
),
agg AS (
  SELECT
    s.d_year,
    s.d_month_seq,
    s.channel,
    c.c_customer_id AS customer_id,
    c.c_first_name,
    c.c_last_name,
    i.i_category,
    i.i_brand,
    SUM(s.net_profit) AS total_net_profit,
    SUM(s.quantity) AS total_quantity,
    COUNT(DISTINCT s.item_sk) AS distinct_items_sold,
    COALESCE(SUM(r.total_net_loss), 0) AS total_return_loss,
    COALESCE(SUM(r.total_return_quantity), 0) AS total_return_quantity
  FROM sales s
  LEFT JOIN returns r
    ON s.channel = r.channel
    AND s.order_number = r.order_number
    AND s.customer_sk = r.customer_sk
    AND s.item_sk = r.item_sk
  JOIN customer c ON s.customer_sk = c.c_customer_sk
  JOIN item i ON s.item_sk = i.i_item_sk
  GROUP BY
    s.d_year,
    s.d_month_seq,
    s.channel,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    i.i_category,
    i.i_brand
),
ranked AS (
  SELECT
    a.*,
    ROW_NUMBER() OVER (PARTITION BY a.d_year, a.channel ORDER BY a.total_net_profit DESC) AS profit_rank,
    PERCENT_RANK() OVER (PARTITION BY a.d_year, a.channel ORDER BY a.total_net_profit) AS profit_percentile
  FROM agg a
)
SELECT
  r.d_year,
  r.d_month_seq,
  r.channel,
  r.customer_id,
  r.c_first_name,
  r.c_last_name,
  r.i_category,
  r.i_brand,
  r.total_net_profit,
  r.total_quantity,
  r.distinct_items_sold,
  r.total_return_loss,
  r.total_return_quantity,
  r.profit_rank,
  r.profit_percentile
FROM ranked r
WHERE r.profit_rank <= 10
ORDER BY r.d_year, r.channel, r.profit_rank
