WITH aggregated AS (
    SELECT
        d_sold.d_year,
        d_sold.d_quarter_name,
        s.s_store_name,
        hd_bill.hd_income_band_sk AS bill_income_band,
        hd_ship.hd_income_band_sk AS ship_income_band,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(wr.wr_net_loss) AS total_return_loss,
        SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_sold.d_date_sk
    JOIN household_demographics hd_refund
        ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN household_demographics hd_returning
        ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year BETWEEN 1995 AND 1998
    GROUP BY
        d_sold.d_year,
        d_sold.d_quarter_name,
        s.s_store_name,
        hd_bill.hd_income_band_sk,
        hd_ship.hd_income_band_sk
)
SELECT
    a.d_year,
    a.d_quarter_name,
    a.s_store_name,
    a.bill_income_band,
    a.ship_income_band,
    a.total_net_profit,
    a.total_return_loss,
    a.total_discount_amount,
    a.distinct_orders,
    a.total_return_qty,
    (a.total_net_profit - a.total_return_loss) AS net_contribution,
    RANK() OVER (PARTITION BY a.d_year ORDER BY (a.total_net_profit - a.total_return_loss) DESC) AS profit_rank_year
FROM aggregated a
ORDER BY net_contribution DESC
LIMIT 100
