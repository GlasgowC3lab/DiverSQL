WITH
  store_agg AS (
    SELECT
      d.d_date AS sale_date,
      c.c_customer_id,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      ARRAY[p.p_channel_dmail, p.p_channel_email, p.p_channel_tv] AS promo_channels
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY d.d_date, c.c_customer_id, p.p_channel_dmail, p.p_channel_email, p.p_channel_tv
  ),
  store_expanded AS (
    SELECT
      s.sale_date,
      s.c_customer_id,
      s.total_sales,
      ch.channel
    FROM store_agg s
    CROSS JOIN UNNEST(s.promo_channels) AS ch(channel)
  ),
  web_agg AS (
    SELECT
      d.d_date AS sale_date,
      c.c_customer_id,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      ARRAY[p.p_channel_dmail, p.p_channel_email, p.p_channel_tv] AS promo_channels
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY d.d_date, c.c_customer_id, p.p_channel_dmail, p.p_channel_email, p.p_channel_tv
  ),
  web_expanded AS (
    SELECT
      w.sale_date,
      w.c_customer_id,
      w.total_sales,
      ch.channel
    FROM web_agg w
    CROSS JOIN UNNEST(w.promo_channels) AS ch(channel)
  ),
  union_sales AS (
    SELECT
      sale_date,
      c_customer_id,
      total_sales,
      channel,
      'store' AS source
    FROM store_expanded
    UNION ALL
    SELECT
      sale_date,
      c_customer_id,
      total_sales,
      channel,
      'web' AS source
    FROM web_expanded
  ),
  full_joined AS (
    SELECT
      d.d_date AS calendar_date,
      u.c_customer_id,
      u.total_sales,
      u.channel,
      u.source
    FROM union_sales u
    FULL OUTER JOIN date_dim d ON u.sale_date = d.d_date
  )
SELECT
  calendar_date,
  c_customer_id,
  total_sales,
  channel,
  source
FROM full_joined
WHERE calendar_date >= DATE '2001-01-01'
ORDER BY calendar_date DESC, c_customer_id
LIMIT 100
