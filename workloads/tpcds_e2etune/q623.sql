WITH promo_returns AS (
  SELECT
    p.p_promo_id,
    p.p_channel_email,
    p.p_channel_dmail,
    p.p_channel_tv,
    p.p_start_date_sk,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
    SUM(sr.sr_refunded_cash) AS total_refunded_cash,
    COUNT(*) AS return_cnt
  FROM promotion p
  JOIN store_returns sr
    ON p.p_item_sk = sr.sr_item_sk
  WHERE p.p_end_date_sk >= 2450000
    AND p.p_channel_email = 'N'
  GROUP BY
    p.p_promo_id,
    p.p_channel_email,
    p.p_channel_dmail,
    p.p_channel_tv,
    p.p_start_date_sk
),
web_activity AS (
  SELECT
    wp_access_date_sk,
    SUM(wp_link_count) AS total_links,
    AVG(wp_image_count) AS avg_images,
    COUNT(DISTINCT wp_customer_sk) AS distinct_customers
  FROM web_page
  WHERE wp_type = 'Content'
  GROUP BY wp_access_date_sk
),
air_ship_mode AS (
  SELECT
    sm_ship_mode_sk,
    sm_ship_mode_id,
    sm_carrier,
    sm_type
  FROM ship_mode
  WHERE sm_type = 'Air'
  LIMIT 1
)
SELECT
  pr.p_promo_id,
  pr.p_channel_email,
  pr.p_channel_dmail,
  pr.p_channel_tv,
  pr.total_return_amt,
  pr.total_refunded_cash,
  pr.return_cnt,
  wa.total_links,
  wa.avg_images,
  wa.distinct_customers,
  asm.sm_ship_mode_id,
  asm.sm_carrier,
  asm.sm_type
FROM promo_returns pr
LEFT JOIN web_activity wa
  ON pr.p_start_date_sk = wa.wp_access_date_sk
JOIN air_ship_mode asm
  ON true
WHERE pr.total_return_amt > 1000
ORDER BY pr.total_return_amt DESC
LIMIT 20
