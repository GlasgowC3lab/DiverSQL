WITH sales_data AS (
   SELECT
       ss.ss_item_sk,
       i.i_category,
       i.i_brand,
       c.c_customer_id,
       ca.ca_state,
       hd.hd_income_band_sk,
       ib.ib_upper_bound,
       p.p_discount_active,
       sum(ss.ss_ext_sales_price) AS total_sales,
       sum(ss.ss_net_profit) AS total_profit,
       sum(ss.ss_quantity) AS total_quantity,
       row_number() OVER (ORDER BY sum(ss.ss_ext_sales_price) DESC) AS global_row_num
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
   JOIN web_sales ws ON ws.ws_item_sk = ss.ss_item_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE i.i_category = 'Sports'
     AND c.c_birth_year BETWEEN 1950 AND 1960
     AND ib.ib_upper_bound > 100000
     AND p.p_discount_active = 'Y'
     AND ca.ca_state = 'CA'
   GROUP BY
       ss.ss_item_sk,
       i.i_category,
       i.i_brand,
       c.c_customer_id,
       ca.ca_state,
       hd.hd_income_band_sk,
       ib.ib_upper_bound,
       p.p_discount_active
)
SELECT
    sd.i_category,
    sd.i_brand,
    sd.c_customer_id,
    sd.total_sales,
    sd.total_profit,
    sd.total_quantity,
    sd.global_row_num,
    DENSE_RANK() OVER (PARTITION BY sd.i_category ORDER BY sd.total_sales DESC) AS category_sales_rank,
    ROW_NUMBER() OVER (PARTITION BY sd.c_customer_id ORDER BY sd.total_sales DESC) AS customer_sales_rn
FROM sales_data sd
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr
    JOIN item i2 ON cr.cr_item_sk = i2.i_item_sk
    WHERE i2.i_item_sk = sd.ss_item_sk
      AND cr.cr_return_quantity > 0
)
ORDER BY sd.total_sales DESC
LIMIT 100
