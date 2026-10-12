WITH return_agg AS (
  SELECT
    ca_ref.ca_state AS state,
    i.i_category AS category,
    hd_ref.hd_buy_potential AS buy_potential,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_tax) AS total_return_tax,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
  JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  WHERE cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
  GROUP BY ca_ref.ca_state, i.i_category, hd_ref.hd_buy_potential
), sales_agg AS (
  SELECT
    ca_sales.ca_state AS state,
    i2.i_category AS category,
    hd_sales.hd_buy_potential AS buy_potential,
    SUM(ss.ss_quantity) AS total_sales_quantity,
    SUM(ss.ss_net_paid) AS total_sales_net_paid,
    SUM(ss.ss_net_profit) AS total_sales_net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    SUM(COALESCE(p.p_cost, 0)) AS total_promo_cost,
    COUNT(*) AS sales_cnt
  FROM store_sales ss
  JOIN item i2 ON ss.ss_item_sk = i2.i_item_sk
  JOIN customer_address ca_sales ON ss.ss_addr_sk = ca_sales.ca_address_sk
  JOIN household_demographics hd_sales ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk AND p.p_item_sk = i2.i_item_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
  GROUP BY ca_sales.ca_state, i2.i_category, hd_sales.hd_buy_potential
)
SELECT
  COALESCE(r.state, s.state) AS state,
  COALESCE(r.category, s.category) AS category,
  COALESCE(r.buy_potential, s.buy_potential) AS buy_potential,
  r.total_return_amount,
  r.total_return_tax,
  r.total_net_loss,
  r.return_cnt,
  s.total_sales_quantity,
  s.total_sales_net_paid,
  s.total_sales_net_profit,
  s.avg_discount,
  s.total_promo_cost,
  s.sales_cnt,
  ROW_NUMBER() OVER (ORDER BY COALESCE(r.total_net_loss, 0) DESC) AS loss_rank
FROM return_agg r
FULL OUTER JOIN sales_agg s
  ON r.state = s.state AND r.category = s.category AND r.buy_potential = s.buy_potential
WHERE COALESCE(r.total_net_loss, 0) > 0 OR s.total_sales_net_profit > 0
ORDER BY loss_rank
LIMIT 200
