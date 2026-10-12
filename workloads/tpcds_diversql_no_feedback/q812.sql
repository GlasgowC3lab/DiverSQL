WITH base AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_item_sk,
    ss.ss_customer_sk,
    ss.ss_store_sk,
    ss.ss_promo_sk,
    ss.ss_ticket_number,
    ss.ss_quantity,
    ss.ss_net_profit,
    i.i_item_id,
    i.i_category,
    i.i_brand,
    c.c_customer_id,
    c.c_preferred_cust_flag,
    s.s_store_id,
    s.s_state,
    p.p_promo_name,
    p.p_discount_active,
    cc.cc_name,
    cc.cc_country,
    cc.cc_hours,
    sm.sm_type,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    r_cr.r_reason_desc   AS cr_reason_desc,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    r_sr.r_reason_desc   AS sr_reason_desc,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    r_wr.r_reason_desc   AS wr_reason_desc,
    wp.wp_url
  FROM store_sales ss
  JOIN item i               ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c           ON ss.ss_customer_sk = c.c_customer_sk
  JOIN store s              ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p          ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN catalog_returns cr   ON cr.cr_item_sk = i.i_item_sk
                                AND cr.cr_refunded_customer_sk = c.c_customer_sk
  LEFT JOIN reason r_cr           ON cr.cr_reason_sk = r_cr.r_reason_sk
  LEFT JOIN call_center cc       ON cr.cr_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN ship_mode sm          ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN store_returns sr     ON sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN reason r_sr          ON sr.sr_reason_sk = r_sr.r_reason_sk
  LEFT JOIN web_returns wr       ON wr.wr_item_sk = i.i_item_sk
                                 AND wr.wr_refunded_customer_sk = c.c_customer_sk
  LEFT JOIN reason r_wr          ON wr.wr_reason_sk = r_wr.r_reason_sk
  LEFT JOIN web_page wp          ON wr.wr_web_page_sk = wp.wp_web_page_sk
),
agg AS (
  SELECT
    b.s_store_id,
    b.s_state,
    b.i_category,
    b.p_promo_name,
    hour_part,
    SUM(b.ss_quantity)                           AS total_quantity,
    SUM(b.ss_net_profit)                         AS total_net_profit,
    COUNT(DISTINCT b.c_customer_id)              AS distinct_customers,
    AVG(b.cr_return_amount) FILTER (WHERE b.cr_return_amount IS NOT NULL) AS avg_catalog_return_amount
  FROM base b
  CROSS JOIN UNNEST(split(b.cc_hours, ',')) AS t(hour_part)
  WHERE b.ss_sold_date_sk BETWEEN 2450815 AND 2450900
    AND b.i_category = 'Sports'
    AND b.p_discount_active = 'Y'
    AND b.s_state = 'CA'
    AND b.c_preferred_cust_flag = 'Y'
    AND b.cc_country = 'United States'
  GROUP BY CUBE(b.s_store_id, b.i_category, b.p_promo_name), b.s_state, hour_part
)
SELECT
  a.s_store_id,
  a.s_state,
  a.i_category,
  a.p_promo_name,
  a.hour_part,
  a.total_quantity,
  a.total_net_profit,
  a.distinct_customers,
  a.avg_catalog_return_amount,
  ROW_NUMBER() OVER (PARTITION BY a.s_store_id ORDER BY a.total_net_profit DESC) AS profit_rank_by_store
FROM agg a
ORDER BY a.total_net_profit DESC
LIMIT 100
