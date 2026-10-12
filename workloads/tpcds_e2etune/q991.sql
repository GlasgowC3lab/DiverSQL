SELECT
    ib_lower_bound,
    ib_upper_bound,
    hd_vehicle_count,
    distinct_customers,
    total_sales,
    total_discount,
    total_profit,
    profit_margin,
    RANK() OVER (PARTITION BY ib_lower_bound, ib_upper_bound ORDER BY total_profit DESC) AS profit_rank
FROM (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_vehicle_count,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE
            WHEN SUM(ss.ss_ext_sales_price) = 0 THEN NULL
            ELSE ROUND(SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price), 4)
        END AS profit_margin
    FROM
        store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        hd.hd_buy_potential = '>10000'
        AND ss.ss_quantity > 1
        AND ib.ib_lower_bound >= 20001
    GROUP BY
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_vehicle_count
) t
ORDER BY
    ib_lower_bound,
    profit_rank
