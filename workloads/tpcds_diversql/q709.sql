WITH
    cs_sample AS (
        SELECT *
        FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    ),
    order_diff AS (
        SELECT cs_order_number
        FROM catalog_sales
        EXCEPT
        SELECT sr_ticket_number
        FROM store_returns
    ),
    joined AS (
        SELECT
            wh.w_warehouse_name,
            dd_sold.d_year,
            hd_bill.hd_buy_potential,
            SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
            SUM(sr.sr_return_amt) AS total_returns,
            COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
            ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_net_paid_inc_ship_tax) DESC) AS rn
        FROM cs_sample cs
        -- first set of dimension joins for catalog_sales
        JOIN date_dim dd_sold
            ON cs.cs_sold_date_sk = dd_sold.d_date_sk
        JOIN date_dim dd_ship
            ON cs.cs_ship_date_sk = dd_ship.d_date_sk
        JOIN household_demographics hd_bill
            ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
        JOIN household_demographics hd_ship
            ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
        JOIN warehouse wh
            ON cs.cs_warehouse_sk = wh.w_warehouse_sk
        -- reuse date_dim and household_demographics for store_returns (different aliases)
        CROSS JOIN store_returns sr
        JOIN date_dim dd_ret
            ON sr.sr_returned_date_sk = dd_ret.d_date_sk
        JOIN household_demographics hd_ret
            ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
        -- two inventory aliases linked to different dates but same warehouse
        JOIN inventory inv1
            ON inv1.inv_date_sk = dd_sold.d_date_sk
           AND inv1.inv_warehouse_sk = wh.w_warehouse_sk
        JOIN inventory inv2
            ON inv2.inv_date_sk = dd_ret.d_date_sk
           AND inv2.inv_warehouse_sk = wh.w_warehouse_sk
        -- keep only orders that were not returned (EXCEPT result)
        WHERE cs.cs_order_number IN (SELECT cs_order_number FROM order_diff)
          -- compare to a scalar sub‑query returning the average net paid for the sold date
          AND cs.cs_net_paid_inc_ship_tax > (
                SELECT AVG(cs2.cs_net_paid_inc_ship_tax)
                FROM catalog_sales cs2
                WHERE cs2.cs_sold_date_sk = dd_sold.d_date_sk
            )
        GROUP BY
            wh.w_warehouse_name,
            dd_sold.d_year,
            hd_bill.hd_buy_potential
        HAVING (SUM(cs.cs_net_paid_inc_ship_tax) - SUM(sr.sr_return_amt)) > 1000
    )
SELECT *
FROM joined
ORDER BY total_sales DESC
LIMIT 100
