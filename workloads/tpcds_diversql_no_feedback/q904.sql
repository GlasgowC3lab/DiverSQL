WITH joined AS (
  SELECT
    s.s_store_name,
    d.d_date,
    i.i_category,
    p.p_promo_name,
    wp.wp_url,
    ss.ss_net_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    AND cs.cs_sold_date_sk = d.d_date_sk
    AND cs.cs_sold_time_sk = t.t_time_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
    AND inv.inv_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
  WHERE d.d_year = 2001
    AND i.i_category = 'Electronics'
    AND s.s_state = 'CA'
    AND p.p_channel_tv = 'Y'
    AND cc.cc_open_date_sk = (
        SELECT d2.d_date_sk
        FROM date_dim d2
        WHERE d2.d_date = DATE '2000-01-01'
        LIMIT 1
    )
    AND wp.wp_type = 'Home'
    AND inv.inv_quantity_on_hand > 500
),
agg AS (
  SELECT
    s_store_name,
    d_date,
    i_category,
    p_promo_name,
    wp_url,
    SUM(ss_net_profit) AS total_store_profit
  FROM joined
  GROUP BY s_store_name, d_date, i_category, p_promo_name, wp_url
)
SELECT
  s_store_name,
  d_date,
  i_category,
  p_promo_name,
  wp_url,
  total_store_profit,
  profit_rank
FROM (
  SELECT
    s_store_name,
    d_date,
    i_category,
    p_promo_name,
    wp_url,
    total_store_profit,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_store_profit DESC) AS profit_rank
  FROM agg
) ranked
WHERE profit_rank <= 5
ORDER BY s_store_name, profit_rank
LIMIT 100
