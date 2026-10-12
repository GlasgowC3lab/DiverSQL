WITH avg_wholesale AS (
    SELECT AVG(ss_ext_wholesale_cost) AS avg_cost
    FROM store_sales
)
SELECT
    p.p_promo_id,
    cp.cp_catalog_page_id,
    ss.ss_ticket_number,
    ws.ws_order_number,
    cr.cr_order_number,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_upper_bound,
    RANK() OVER (PARTITION BY p.p_promo_id ORDER BY ss.ss_net_profit DESC) AS profit_rank,
    CASE WHEN ss.ss_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign
FROM store_sales ss
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_returns cr
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
 AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN web_sales ws
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
 AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
 AND ws.ws_promo_sk = p.p_promo_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE ss.ss_ext_wholesale_cost > 1000
  AND hd.hd_buy_potential = '501-1000'
  AND ib.ib_upper_bound >= 150000
  AND p.p_discount_active = 'Y'
  AND wp.wp_rec_start_date > DATE '2022-01-01'
  AND ss.ss_quantity > 5
  AND NOT EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_order_number = ss.ss_ticket_number
      )
  AND ss.ss_ext_wholesale_cost > (SELECT avg_cost FROM avg_wholesale)
UNION DISTINCT
SELECT
    p.p_promo_id,
    cp.cp_catalog_page_id,
    ss.ss_ticket_number,
    ws.ws_order_number,
    cr.cr_order_number,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_upper_bound,
    RANK() OVER (PARTITION BY p.p_promo_id ORDER BY ss.ss_net_profit DESC) AS profit_rank,
    CASE WHEN ss.ss_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign
FROM store_sales ss
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_returns cr
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
 AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN web_sales ws
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
 AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
 AND ws.ws_promo_sk = p.p_promo_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE ws.ws_ext_sales_price > 3000
  AND hd.hd_buy_potential = '501-1000'
  AND ib.ib_upper_bound >= 150000
  AND p.p_discount_active = 'Y'
  AND wp.wp_rec_start_date > DATE '2022-01-01'
  AND ws.ws_quantity > 5
  AND NOT EXISTS (
        SELECT 1 FROM catalog_returns cr3
        WHERE cr3.cr_order_number = ws.ws_order_number
      )
  AND ss.ss_ext_wholesale_cost > (SELECT avg_cost FROM avg_wholesale)
LIMIT 100
