WITH sales_agg AS (
  SELECT
    d.d_year,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cd.cd_gender,
    SUM(cs.cs_net_profit) AS catalog_profit,
    SUM(ss.ss_net_profit) AS store_profit,
    SUM(ws.ws_net_profit) AS web_profit,
    SUM(wr.wr_net_loss) AS return_loss,
    SUM(cs.cs_ext_discount_amt + ss.ss_ext_discount_amt + ws.ws_ext_discount_amt) AS total_discount,
    CASE
      WHEN SUM(cs.cs_net_profit + ss.ss_net_profit + ws.ws_net_profit) > 0 THEN 'Positive'
      ELSE 'Negative'
    END AS profit_flag,
    SUM(cd_avg.avg_discount) AS total_avg_catalog_discount
  FROM date_dim d
  JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
    AND ss.ss_customer_sk = cust.c_customer_sk
    AND ws.ws_bill_customer_sk = cust.c_customer_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    AND ss.ss_addr_sk = ca.ca_address_sk
    AND ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    AND ss.ss_cdemo_sk = cd.cd_demo_sk
    AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    AND ss.ss_hdemo_sk = hd.hd_demo_sk
    AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
  LEFT JOIN LATERAL (
    SELECT AVG(cs2.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs2
    WHERE cs2.cs_bill_customer_sk = cust.c_customer_sk
  ) cd_avg ON TRUE
  WHERE d.d_year = 2001
    AND ib.ib_lower_bound >= 30000
    AND ca.ca_state = 'CA'
    AND ws.ws_sales_price > 100
  GROUP BY GROUPING SETS (
    (d.d_year, ib.ib_lower_bound, ib.ib_upper_bound),
    (d.d_year, cd.cd_gender),
    ()
  )
)
SELECT *
FROM sales_agg
ORDER BY d_year DESC, catalog_profit DESC
LIMIT 100
