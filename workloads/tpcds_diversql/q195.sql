WITH catalog_part AS (
  SELECT
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    cp.cp_catalog_number,
    w.w_warehouse_name,
    td.t_hour,
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_upper_bound,
    wp.wp_url,
    ca.ca_address_id
  FROM catalog_sales cs
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
),
store_part AS (
  SELECT
    ss.ss_ticket_number,
    ss.ss_ext_sales_price,
    td2.t_hour,
    c2.c_customer_id,
    cd2.cd_gender,
    hd2.hd_buy_potential,
    ib2.ib_upper_bound,
    wp2.wp_url,
    ca2.ca_address_id,
    sr.sr_return_quantity,
    td_ret.t_hour AS return_hour
  FROM store_sales ss
  JOIN time_dim td2
    ON ss.ss_sold_time_sk = td2.t_time_sk
  JOIN customer c2
    ON ss.ss_customer_sk = c2.c_customer_sk
  JOIN customer_demographics cd2
    ON ss.ss_cdemo_sk = cd2.cd_demo_sk
  JOIN household_demographics hd2
    ON ss.ss_hdemo_sk = hd2.hd_demo_sk
  JOIN income_band ib2
    ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
  JOIN web_page wp2
    ON wp2.wp_customer_sk = c2.c_customer_sk
  JOIN customer_address ca2
    ON ss.ss_addr_sk = ca2.ca_address_sk
  JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
  JOIN time_dim td_ret
    ON sr.sr_return_time_sk = td_ret.t_time_sk
)
SELECT
  final.customer_id,
  final.gender,
  final.buy_potential,
  SUM(final.sales_amount) AS total_sales,
  MAX(final.upper_income_bound) AS max_income_bound
FROM (
  SELECT
    c_customer_id   AS customer_id,
    cd_gender       AS gender,
    hd_buy_potential AS buy_potential,
    cs_ext_sales_price AS sales_amount,
    ib_upper_bound AS upper_income_bound
  FROM catalog_part
  UNION DISTINCT
  SELECT
    c_customer_id   AS customer_id,
    cd_gender       AS gender,
    hd_buy_potential AS buy_potential,
    ss_ext_sales_price AS sales_amount,
    ib_upper_bound AS upper_income_bound
  FROM store_part
) final
WHERE final.sales_amount > (
  SELECT AVG(cs_ext_sales_price)
  FROM catalog_sales
  WHERE cs_catalog_page_sk = (
    SELECT cp_catalog_page_sk
    FROM catalog_page
    WHERE cp_catalog_number = 12
    LIMIT 1
  )
)
GROUP BY final.customer_id, final.gender, final.buy_potential
ORDER BY total_sales DESC
LIMIT 100
