SELECT
    bill_income_band,
    ship_income_band,
    orders_cnt,
    total_net_profit,
    avg_discount_amt,
    total_sales,
    total_net_profit / NULLIF(total_sales, 0) AS profit_margin,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM (
    SELECT
        hd_bill.hd_income_band_sk AS bill_income_band,
        hd_ship.hd_income_band_sk AS ship_income_band,
        COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount_amt,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE cs.cs_ship_hdemo_sk IN (4563, 6730, 6054)
      AND hd_bill.hd_vehicle_count >= 2
      AND cs.cs_ext_sales_price > 0
    GROUP BY hd_bill.hd_income_band_sk, hd_ship.hd_income_band_sk
    HAVING SUM(cs.cs_net_profit) > 0
) t
ORDER BY total_net_profit DESC
LIMIT 100
