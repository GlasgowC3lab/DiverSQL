WITH intersected_cd AS (
       SELECT cs_bill_cdemo_sk AS cd_demo_sk FROM catalog_sales
       INTERSECT
       SELECT wr_returning_cdemo_sk FROM web_returns
   )
SELECT
    ws.web_site_id,
    d.d_year,
    d.d_month_seq,
    cd.cd_gender,
    ib.ib_lower_bound,
    p.p_promo_name,
    COUNT(DISTINCT cs.cs_order_number)               AS distinct_orders,
    SUM(DISTINCT cs.cs_ext_sales_price)             AS distinct_sales_price,
    RANK() OVER (PARTITION BY d.d_year ORDER BY cs.cs_ext_sales_price DESC) AS price_rank,
    (SELECT SUM(wr2.wr_return_amt)
       FROM web_returns wr2
      WHERE wr2.wr_returned_date_sk = d.d_date_sk) AS total_return_amt_for_date
FROM catalog_sales cs
LEFT JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
LEFT JOIN customer_demographics cd  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN promotion p               ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN web_returns wr           ON wr.wr_returned_date_sk = d.d_date_sk
RIGHT JOIN web_site ws             ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1220
  AND cs.cs_quantity > 5
  AND cs.cs_net_profit > 0
  AND p.p_channel_tv = 'Y'
  AND cd.cd_demo_sk IN (SELECT cd_demo_sk FROM intersected_cd)
GROUP BY
    ws.web_site_id,
    d.d_year,
    d.d_month_seq,
    cd.cd_gender,
    ib.ib_lower_bound,
    p.p_promo_name,
    d.d_date_sk,
    cs.cs_ext_sales_price
ORDER BY ws.web_site_id, price_rank
LIMIT 100
