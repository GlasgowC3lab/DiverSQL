WITH
  cs_agg AS (
    SELECT
      cs_item_sk,
      cs_sold_date_sk,
      cs_call_center_sk,
      cs_promo_sk,
      cs_order_number,
      SUM(cs_net_paid) AS cs_total_net_paid,
      COUNT(*)       AS cs_sales_cnt
    FROM catalog_sales
    WHERE cs_quantity > 0
      AND cs_sales_price > 0
    GROUP BY cs_item_sk, cs_sold_date_sk, cs_call_center_sk, cs_promo_sk, cs_order_number
  ),
  ss_agg AS (
    SELECT
      ss_item_sk,
      ss_sold_date_sk,
      ss_store_sk,
      ss_ticket_number,
      SUM(ss_net_paid) AS ss_total_net_paid,
      COUNT(*)       AS ss_sales_cnt
    FROM store_sales
    WHERE ss_quantity > 0
    GROUP BY ss_item_sk, ss_sold_date_sk, ss_store_sk, ss_ticket_number
  ),
  diff_items AS (
    SELECT cs_item_sk FROM catalog_sales
    EXCEPT
    SELECT sr_item_sk FROM store_returns
  )
SELECT
  d.d_year,
  cc.cc_company,
  p.p_promo_name,
  cs_agg.cs_total_net_paid,
  ss.ss_total_net_paid,
  CASE WHEN cs_agg.cs_total_net_paid > ss.ss_total_net_paid THEN 'CATALOG' ELSE 'STORE' END AS higher_source,
  (SELECT MAX(p2.p_cost) FROM promotion p2 WHERE p2.p_promo_sk = p.p_promo_sk) AS max_promo_cost,
  ROW_NUMBER() OVER (ORDER BY cs_agg.cs_total_net_paid DESC) AS rn
FROM cs_agg
JOIN date_dim d               ON cs_agg.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc          ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p             ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN inventory i             ON cs_agg.cs_item_sk = i.inv_item_sk
                               AND cs_agg.cs_sold_date_sk = i.inv_date_sk
JOIN diff_items di           ON cs_agg.cs_item_sk = di.cs_item_sk
LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs_agg.cs_order_number
LEFT JOIN customer c         ON cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
LEFT JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib      ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN reason r           ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN web_page wp        ON wp.wp_customer_sk = c.c_customer_sk
LEFT JOIN ss_agg ss          ON ss.ss_item_sk = cs_agg.cs_item_sk
                               AND ss.ss_sold_date_sk = cs_agg.cs_sold_date_sk
LEFT JOIN store_returns sr   ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk = ss.ss_item_sk
WHERE d.d_year = 2002
  AND cc.cc_company = 3
  AND p.p_discount_active = 'Y'
  AND i.inv_quantity_on_hand > 50
  AND r.r_reason_desc LIKE '%damage%'
  AND c.c_preferred_cust_flag = 'Y'
  AND ib.ib_upper_bound < 50000
  AND cs_agg.cs_item_sk NOT IN (
        SELECT sr_item_sk FROM store_returns WHERE sr_return_quantity > 0
      )
  AND EXISTS (
        SELECT 1 FROM promotion p2 WHERE p2.p_promo_sk = p.p_promo_sk AND p2.p_discount_active = 'Y'
      )
ORDER BY cs_agg.cs_total_net_paid DESC
OFFSET 0
LIMIT 100
