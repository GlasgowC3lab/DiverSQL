WITH returns AS (
  SELECT
    cr_item_sk AS item_sk,
    cr_ship_mode_sk AS ship_mode_sk,
    cr_return_amt_inc_tax AS return_amt_inc_tax,
    cr_fee AS fee,
    'Catalog' AS source
  FROM catalog_returns
  WHERE cr_returned_date_sk BETWEEN 2450000 AND 2459999
    AND cr_return_amt_inc_tax > 100
  UNION ALL
  SELECT
    wr_item_sk AS item_sk,
    NULL AS ship_mode_sk,
    wr_return_amt_inc_tax AS return_amt_inc_tax,
    wr_fee AS fee,
    'Web' AS source
  FROM web_returns
  WHERE wr_returned_date_sk BETWEEN 2450000 AND 2459999
    AND wr_return_amt_inc_tax > 100
),
joined AS (
  SELECT
    p.p_promo_name AS promo_name,
    i.i_category AS category,
    COALESCE(sm.sm_type, 'Web') AS ship_mode_type,
    r.return_amt_inc_tax,
    r.fee
  FROM returns r
  JOIN item i ON r.item_sk = i.i_item_sk
  JOIN promotion p ON i.i_item_sk = p.p_item_sk
  LEFT JOIN ship_mode sm ON r.ship_mode_sk = sm.sm_ship_mode_sk
  WHERE p.p_start_date_sk <= 2455000
    AND p.p_end_date_sk >= 2455000
),
agg AS (
  SELECT
    promo_name,
    category,
    ship_mode_type,
    SUM(return_amt_inc_tax) AS total_return_amount,
    COUNT(*) AS return_cnt,
    AVG(return_amt_inc_tax) AS avg_return_amount,
    SUM(fee) AS total_fee
  FROM joined
  GROUP BY promo_name, category, ship_mode_type
  HAVING SUM(return_amt_inc_tax) > 500
)
SELECT
  promo_name,
  category,
  ship_mode_type,
  total_return_amount,
  return_cnt,
  avg_return_amount,
  total_fee,
  ROW_NUMBER() OVER (PARTITION BY promo_name ORDER BY total_return_amount DESC) AS rank_by_total
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
