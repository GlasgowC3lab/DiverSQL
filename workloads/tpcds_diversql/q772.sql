WITH sampled_item AS (
    SELECT *
    FROM tpcds.item
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    s.s_store_name,
    i.i_item_id,
    i.i_category,
    i.i_brand,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(sr.sr_return_amt) AS total_store_returns,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(wr.wr_return_amt) AS total_web_returns,
    CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    (SELECT SUM(inv2.inv_quantity_on_hand)
       FROM tpcds.inventory inv2
      WHERE inv2.inv_item_sk = i.i_item_sk) AS total_inventory_qty,
    ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_net_paid) DESC) AS global_rn,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY SUM(ss.ss_net_paid) DESC) AS store_item_rn
FROM tpcds.store_sales ss
JOIN tpcds.store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN sampled_item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN tpcds.promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN tpcds.customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN tpcds.inventory inv
  ON inv.inv_item_sk = i.i_item_sk
LEFT JOIN tpcds.store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN tpcds.catalog_sales cs
  ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN tpcds.catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN tpcds.web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
LEFT JOIN tpcds.reason r
  ON r.r_reason_sk = COALESCE(sr.sr_reason_sk, cr.cr_reason_sk, wr.wr_reason_sk)
JOIN tpcds.call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE
    cc.cc_state = 'CA'
    AND i.i_brand = 'Brand#12'
    AND cd.cd_gender = 'M'
    AND hd.hd_vehicle_count >= 2
    AND ib.ib_upper_bound <= 100000
    AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2455195
    AND p.p_discount_active = 'Y'
    AND EXISTS (
        SELECT 1
        FROM tpcds.store_returns sr_exists
        WHERE sr_exists.sr_item_sk = i.i_item_sk
          AND sr_exists.sr_net_loss > 0
    )
GROUP BY
    s.s_store_name,
    i.i_item_id,
    i.i_category,
    i.i_brand,
    i.i_item_sk
HAVING
    SUM(ss.ss_net_paid) > 5000
ORDER BY
    total_store_sales DESC,
    s.s_store_name
LIMIT 100
