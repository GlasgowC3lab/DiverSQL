WITH unified_sales AS (
  SELECT ss_sold_date_sk AS sold_date_sk,
         ss_item_sk AS item_sk,
         ss_quantity AS quantity,
         ss_net_paid AS net_paid,
         ss_net_profit AS net_profit,
         ss_ext_discount_amt AS discount_amt,
         'STORE' AS sales_channel,
         ss_promo_sk AS promo_sk
  FROM store_sales
  UNION ALL
  SELECT cs_sold_date_sk,
         cs_item_sk,
         cs_quantity,
         cs_net_paid,
         cs_net_profit,
         cs_ext_discount_amt,
         'CATALOG',
         cs_promo_sk
  FROM catalog_sales
  UNION ALL
  SELECT ws_sold_date_sk,
         ws_item_sk,
         ws_quantity,
         ws_net_paid,
         ws_net_profit,
         ws_ext_discount_amt,
         'WEB',
         ws_promo_sk
  FROM web_sales
),
sales_with_date AS (
  SELECT us.*,
         d.d_date,
         d.d_year,
         d.d_month_seq,
         d.d_week_seq,
         d.d_day_name,
         d.d_weekend,
         d.d_holiday
  FROM unified_sales us
  LEFT JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
),
sales_full AS (
  SELECT swd.*,
         i.i_item_id,
         i.i_brand,
         i.i_category,
         i.i_class,
         i.i_color,
         i.i_size,
         i.i_current_price
  FROM sales_with_date swd
  LEFT JOIN item i ON swd.item_sk = i.i_item_sk
),
daily_agg AS (
  SELECT sfd.d_date,
         sfd.sales_channel,
         sum(sfd.net_paid) AS total_net_paid,
         sum(sfd.net_profit) AS total_net_profit,
         sum(sfd.quantity) AS total_quantity,
         avg(sfd.discount_amt) AS avg_discount_amt,
         sum(sfd.net_profit) / nullif(sum(sfd.net_paid), 0) * 100 AS profit_margin_pct
  FROM sales_full sfd
  WHERE (sfd.d_weekend = 'Y' OR sfd.d_holiday = 'Y')
    AND sfd.net_profit > 0
  GROUP BY sfd.d_date, sfd.sales_channel
),
daily_agg_win AS (
  SELECT da.*,
         lag(total_net_profit) OVER (PARTITION BY sales_channel ORDER BY d_date) AS prev_day_net_profit,
         lead(total_net_profit) OVER (PARTITION BY sales_channel ORDER BY d_date) AS next_day_net_profit,
         row_number() OVER (PARTITION BY sales_channel ORDER BY total_net_profit DESC) AS profit_rank_overall
  FROM daily_agg da
),
item_sales AS (
  SELECT d_date,
         sales_channel,
         i_item_id,
         item_net_profit,
         item_net_paid,
         row_number() OVER (PARTITION BY d_date, sales_channel ORDER BY item_net_profit DESC) AS rn
  FROM (
    SELECT sfd.d_date,
           sfd.sales_channel,
           sfd.i_item_id,
           sum(sfd.net_profit) AS item_net_profit,
           sum(sfd.net_paid) AS item_net_paid
    FROM sales_full sfd
    GROUP BY sfd.d_date, sfd.sales_channel, sfd.i_item_id
  ) item_agg
),
top_items AS (
  SELECT d_date,
         sales_channel,
         max(CASE WHEN rn = 1 THEN i_item_id END) AS top_item_1,
         max(CASE WHEN rn = 2 THEN i_item_id END) AS top_item_2,
         max(CASE WHEN rn = 3 THEN i_item_id END) AS top_item_3
  FROM item_sales
  WHERE rn <= 3
  GROUP BY d_date, sales_channel
),
promo_counts AS (
  SELECT sfd.d_date,
         sfd.sales_channel,
         count(DISTINCT CASE WHEN p.p_discount_active = 'Y' THEN p.p_promo_name END) AS active_promo_cnt
  FROM sales_full sfd
  LEFT JOIN promotion p ON sfd.promo_sk = p.p_promo_sk
  GROUP BY sfd.d_date, sfd.sales_channel
)
SELECT da.d_date,
       da.sales_channel,
       da.total_net_paid,
       da.total_net_profit,
       da.profit_margin_pct,
       CASE WHEN da.profit_margin_pct > 20 THEN 'HIGH' ELSE 'LOW' END AS profit_margin_flag,
       da.total_quantity,
       da.avg_discount_amt,
       da.prev_day_net_profit,
       da.next_day_net_profit,
       (SELECT sum(sfd_corr.net_profit)
        FROM sales_full sfd_corr
        WHERE sfd_corr.sales_channel = da.sales_channel
          AND sfd_corr.d_date = date_add('day', -1, da.d_date)
       ) AS prev_day_profit_corr,
       da.profit_rank_overall,
       ti.top_item_1,
       ti.top_item_2,
       ti.top_item_3,
       COALESCE(pc.active_promo_cnt, 0) AS active_promo_cnt,
       CONCAT(da.sales_channel, '_', CAST(da.d_date AS VARCHAR)) AS channel_date_key
FROM daily_agg_win da
LEFT JOIN top_items ti ON da.d_date = ti.d_date AND da.sales_channel = ti.sales_channel
LEFT JOIN promo_counts pc ON da.d_date = pc.d_date AND da.sales_channel = pc.sales_channel
ORDER BY da.d_date DESC, da.sales_channel
