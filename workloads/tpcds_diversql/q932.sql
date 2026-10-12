WITH
  store_agg AS (
    SELECT d.d_date,
           SUM(ss.ss_ext_sales_price) AS store_sales_total,
           SUM(ss.ss_net_profit)      AS store_profit
    FROM store_sales ss
    JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i                    ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd  ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca       ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ss.ss_quantity > 1
      AND i.i_current_price > 10
      AND cd.cd_credit_rating = 'Good'
      AND hd.hd_vehicle_count < 3
      AND ib.ib_upper_bound > 100000
      AND d.d_year = 1998
    GROUP BY d.d_date
  ),
  catalog_agg AS (
    SELECT d.d_date,
           SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
           SUM(cs.cs_net_profit)      AS catalog_profit
    FROM catalog_sales cs
    JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i                    ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca       ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cs.cs_quantity > 1
      AND i.i_current_price > 15
      AND cd.cd_credit_rating = 'Good'
      AND hd.hd_vehicle_count < 3
      AND ib.ib_upper_bound > 100000
      AND d.d_year = 1998
    GROUP BY d.d_date
  ),
  web_agg AS (
    SELECT d.d_date,
           COUNT(DISTINCT ws.web_site_sk) AS open_site_cnt
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 1998
    GROUP BY d.d_date
  ),
  intersect_dates AS (
    SELECT d_date FROM store_agg WHERE store_sales_total > 50000
    INTERSECT
    SELECT d_date FROM catalog_agg WHERE catalog_sales_total > 50000
  ),
  except_dates AS (
    SELECT d_date FROM store_agg
    EXCEPT
    SELECT d_date FROM catalog_agg
  ),
  union_dates AS (
    SELECT d_date FROM intersect_dates
    UNION
    SELECT d_date FROM except_dates
  ),
  final_agg AS (
    SELECT i.d_date,
           sa.store_sales_total,
           ca.catalog_sales_total,
           wa.open_site_cnt,
           CASE WHEN sa.store_sales_total > ca.catalog_sales_total THEN 'STORE_HIGH' ELSE 'CATALOG_HIGH' END AS higher_source,
           SUM(sa.store_sales_total) OVER (ORDER BY i.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_store_sales
    FROM union_dates i
    LEFT JOIN store_agg   sa ON i.d_date = sa.d_date
    LEFT JOIN catalog_agg ca ON i.d_date = ca.d_date
    LEFT JOIN web_agg     wa ON i.d_date = wa.d_date
    WHERE i.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
  )
SELECT d_date,
       store_sales_total,
       catalog_sales_total,
       open_site_cnt,
       higher_source,
       running_store_sales
FROM final_agg
ORDER BY d_date DESC
LIMIT 100
