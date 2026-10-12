WITH inv_agg AS (
   SELECT inv_item_sk,
          SUM(inv_quantity_on_hand) AS total_on_hand
   FROM inventory
   GROUP BY inv_item_sk
),
base AS (
   SELECT
       cs.cs_order_number,
       cs.cs_item_sk,
       cs.cs_ext_sales_price,
       cs.cs_ship_mode_sk,
       sr.sr_return_amt,
       sr.sr_store_sk,
       wr.wr_return_amt,
       i.i_item_id,
       i.i_product_name,
       s.s_store_name,
       sm.sm_type,
       p.p_promo_name,
       hd_bill.hd_income_band_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       inv_agg.total_on_hand
   FROM catalog_sales cs
   RIGHT JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN item i
     ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
   LEFT JOIN household_demographics hd_bill
     ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
   LEFT JOIN income_band ib
     ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN customer_address ca_bill
     ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
   LEFT JOIN household_demographics hd_ship
     ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
   LEFT JOIN customer_address ca_ship
     ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
   LEFT JOIN store_returns sr
     ON sr.sr_item_sk = i.i_item_sk
   LEFT JOIN store s
     ON sr.sr_store_sk = s.s_store_sk
   LEFT JOIN customer_address ca_sr
     ON sr.sr_addr_sk = ca_sr.ca_address_sk
   LEFT JOIN household_demographics hd_sr
     ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
   LEFT JOIN web_returns wr
     ON wr.wr_item_sk = i.i_item_sk
   LEFT JOIN web_page wp
     ON wr.wr_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN customer_address ca_wr_refunded
     ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
   LEFT JOIN household_demographics hd_wr_refunded
     ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
   LEFT JOIN inv_agg
     ON inv_agg.inv_item_sk = i.i_item_sk
),
filtered AS (
   SELECT
       i_item_id,
       i_product_name,
       s_store_name,
       sm_type,
       p_promo_name,
       ib_lower_bound,
       ib_upper_bound,
       total_on_hand,
       cs_ext_sales_price        AS sales_amount,
       COALESCE(sr_return_amt, 0) AS return_amount,
       COALESCE(wr_return_amt, 0) AS web_return_amount,
       cs_order_number
   FROM base
   WHERE cs_order_number NOT IN (
       SELECT sr_ticket_number FROM store_returns
   )
),
agg AS (
   SELECT
       i_item_id,
       s_store_name,
       sm_type,
       MAX(p_promo_name)       AS p_promo_name,
       MAX(ib_lower_bound)     AS ib_lower_bound,
       MAX(ib_upper_bound)     AS ib_upper_bound,
       MAX(total_on_hand)      AS total_on_hand,
       SUM(sales_amount)       AS total_sales,
       SUM(return_amount)      AS total_returns,
       SUM(web_return_amount)  AS total_web_returns,
       COUNT(*)                AS trans_cnt
   FROM filtered
   GROUP BY ROLLUP (i_item_id, s_store_name, sm_type)
)
SELECT
   i_item_id,
   s_store_name,
   sm_type,
   p_promo_name,
   ib_lower_bound,
   ib_upper_bound,
   total_on_hand,
   total_sales,
   total_returns,
   total_web_returns,
   trans_cnt,
   RANK() OVER (PARTITION BY s_store_name ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
