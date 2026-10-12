WITH base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_call_center_sk,
    cs.cs_catalog_page_sk,
    cs.cs_promo_sk,
    cs.cs_item_sk,
    cc.cc_name,
    cc.cc_state,
    cp.cp_department,
    p.p_promo_name,
    p.p_discount_active,
    d.d_year,
    t.t_shift,
    r.r_reason_desc,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    inv.inv_quantity_on_hand,
    ws.web_name,
    ws.web_country,
    cd.cd_gender
  FROM catalog_sales cs
  FULL OUTER JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  LEFT JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN inventory inv
    ON cs.cs_item_sk = inv.inv_item_sk
    AND d.d_date_sk = inv.inv_date_sk
  LEFT JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
  LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
  LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  LEFT JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_year = 2001
    AND t.t_shift = 'first'
    AND cc.cc_state = 'CA'
    AND ws.web_country = 'United States'
    AND p.p_discount_active = 'Y'
),
agg AS (
  SELECT
    d_year,
    cp_department,
    SUM(cs_quantity) AS total_qty,
    SUM(cs_net_paid) AS total_paid,
    SUM(cs_net_profit) AS total_profit,
    SUM(CASE WHEN cr_return_quantity IS NULL THEN 0 ELSE cr_return_quantity END) AS total_return_qty,
    COUNT(DISTINCT cs_order_number) AS orders,
    ROW_NUMBER() OVER (ORDER BY SUM(cs_net_profit) DESC) AS profit_rank,
    CASE
      WHEN SUM(cs_net_profit) > (SELECT AVG(cs_net_profit) FROM catalog_sales) THEN 'ABOVE_AVG'
      ELSE 'BELOW_AVG'
    END AS profit_category
  FROM base
  GROUP BY d_year, cp_department
)
SELECT
  d_year,
  cp_department,
  total_qty,
  total_paid,
  total_profit,
  total_return_qty,
  orders,
  profit_rank,
  profit_category
FROM agg
WHERE total_profit > 0
  AND total_qty > 1000
  AND orders >= 50
  AND profit_category = 'ABOVE_AVG'
ORDER BY total_profit DESC
LIMIT 100
