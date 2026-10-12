SELECT
    hd.hd_buy_potential,
    hd.hd_income_band_sk,
    SUM(cs.cs_ext_sales_price) AS total_ext_sales,
    AVG(cs.cs_net_profit) AS avg_net_profit
FROM
    tpcds.catalog_sales cs
JOIN
    tpcds.household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE
    cs.cs_ship_date_sk = 2450846
    AND cs.cs_list_price > 120.00
    AND hd.hd_income_band_sk = 10
    AND hd.hd_buy_potential = '1001-5000'
GROUP BY
    hd.hd_buy_potential,
    hd.hd_income_band_sk
ORDER BY
    total_ext_sales DESC
LIMIT 10
