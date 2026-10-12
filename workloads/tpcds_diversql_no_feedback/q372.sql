WITH
  cs_agg AS (
    SELECT
      cs_bill_customer_sk,
      cs_bill_cdemo_sk,
      cs_sold_date_sk,
      cs_ship_mode_sk,
      SUM(cs_ext_sales_price) AS catalog_sales_amount,
      SUM(cs_net_profit) AS catalog_profit
    FROM catalog_sales
    WHERE cs_quantity > 1
      AND cs_ext_discount_amt > 0
      AND cs_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY
      cs_bill_customer_sk,
      cs_bill_cdemo_sk,
      cs_sold_date_sk,
      cs_ship_mode_sk
  ),
  ws_agg AS (
    SELECT
      ws_bill_customer_sk,
      ws_bill_cdemo_sk,
      ws_sold_date_sk,
      ws_ship_mode_sk,
      ws_web_page_sk,
      ws_web_site_sk,
      SUM(ws_ext_sales_price) AS web_sales_amount,
      SUM(ws_net_profit) AS web_profit
    FROM web_sales
    WHERE ws_quantity > 1
      AND ws_ext_discount_amt > 0
      AND ws_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY
      ws_bill_customer_sk,
      ws_bill_cdemo_sk,
      ws_sold_date_sk,
      ws_ship_mode_sk,
      ws_web_page_sk,
      ws_web_site_sk
  ),
  sr_agg AS (
    SELECT
      sr_returned_date_sk,
      sr_return_time_sk,
      sr_cdemo_sk,
      sr_reason_sk,
      SUM(sr_return_amt) AS return_amount,
      SUM(sr_net_loss) AS net_loss
    FROM store_returns
    WHERE sr_return_quantity > 0
      AND sr_return_amt > 0
      AND sr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY
      sr_returned_date_sk,
      sr_return_time_sk,
      sr_cdemo_sk,
      sr_reason_sk
  )
SELECT
  cs_agg.cs_bill_customer_sk AS customer_sk,
  d_cs.d_year,
  cd_cs.cd_gender,
  sm.sm_type,
  wp.wp_type,
  wsite.web_class,
  SUM(cs_agg.catalog_sales_amount) AS total_catalog_sales,
  SUM(ws_agg.web_sales_amount) AS total_web_sales,
  SUM(sr_agg.return_amount) AS total_returns,
  SUM(cs_agg.catalog_profit) + SUM(ws_agg.web_profit) - SUM(sr_agg.net_loss) AS net_margin,
  ROW_NUMBER() OVER (PARTITION BY d_cs.d_year ORDER BY SUM(cs_agg.catalog_sales_amount) DESC) AS sales_rank,
  (SELECT SUM(ws_ext_sales_price)
     FROM web_sales ws2
    WHERE ws2.ws_bill_customer_sk = cs_agg.cs_bill_customer_sk) AS customer_total_web_sales
FROM cs_agg
JOIN date_dim d_cs ON cs_agg.cs_sold_date_sk = d_cs.d_date_sk
JOIN customer_demographics cd_cs ON cs_agg.cs_bill_cdemo_sk = cd_cs.cd_demo_sk
JOIN ws_agg ON cs_agg.cs_bill_customer_sk = ws_agg.ws_bill_customer_sk
            AND cs_agg.cs_bill_cdemo_sk = ws_agg.ws_bill_cdemo_sk
JOIN date_dim d_ws ON ws_agg.ws_sold_date_sk = d_ws.d_date_sk
JOIN web_page wp ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite ON ws_agg.ws_web_site_sk = wsite.web_site_sk
JOIN ship_mode sm ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN sr_agg ON cs_agg.cs_sold_date_sk = sr_agg.sr_returned_date_sk
                    AND cs_agg.cs_bill_cdemo_sk = sr_agg.sr_cdemo_sk
JOIN date_dim d_sr ON sr_agg.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t ON sr_agg.sr_return_time_sk = t.t_time_sk
JOIN reason r ON sr_agg.sr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd_sr ON sr_agg.sr_cdemo_sk = cd_sr.cd_demo_sk
GROUP BY
  cs_agg.cs_bill_customer_sk,
  CUBE (d_cs.d_year, cd_cs.cd_gender, sm.sm_type, wp.wp_type, wsite.web_class)
HAVING
  SUM(cs_agg.catalog_sales_amount) > 1000
  AND SUM(ws_agg.web_sales_amount) > 500
  AND SUM(sr_agg.return_amount) IS NOT NULL
ORDER BY d_cs.d_year, cd_cs.cd_gender
