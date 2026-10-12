WITH joined_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_ship_cost,
        cs.cs_net_paid,
        cs.cs_net_profit,
        sr.sr_returned_date_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        d_sold.d_year,
        d_sold.d_quarter_seq,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        ws.web_site_id,
        ws.web_class,
        ws.web_gmt_offset
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d_sold.d_date_sk
    JOIN household_demographics hd_ret
        ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001                                         -- predicate 1
      AND d_sold.d_quarter_seq = 2                                      -- predicate 2
      AND hd.hd_income_band_sk IN (1, 2, 10)                            -- predicate 3
      AND hd.hd_vehicle_count >= 1                                     -- predicate 4
      AND cs.cs_ext_ship_cost > 200.00                                 -- predicate 5
      AND cs.cs_quantity BETWEEN 1 AND 5                               -- predicate 6
      AND ws.web_class = 'E'                                            -- predicate 7
      AND ws.web_gmt_offset > 0                                         -- predicate 8
      AND sr.sr_return_amt > 0                                          -- predicate 9
),
agg_data AS (
    SELECT
        web_site_id,
        d_year,
        SUM(cs_net_paid)          AS total_sales,
        SUM(sr_return_amt)        AS total_returns,
        SUM(cs_net_profit)        AS total_profit,
        AVG(cs_ext_ship_cost)     AS avg_ship_cost,
        SUM(cs_quantity)          AS total_qty
    FROM joined_data
    GROUP BY web_site_id, d_year
)
SELECT
    web_site_id,
    d_year,
    total_sales,
    total_returns,
    total_profit,
    avg_ship_cost,
    total_qty,
    SUM(total_sales - total_returns) OVER (
        PARTITION BY web_site_id
        ORDER BY d_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_net
FROM agg_data
WHERE web_site_id NOT IN (
    SELECT web_site_id FROM web_site WHERE web_gmt_offset < 0
)
ORDER BY web_site_id, d_year DESC
