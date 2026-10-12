WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_sold.d_year,
        d_sold.d_month_seq,
        cd_bill.cd_gender AS bill_gender,
        cd_ship.cd_gender AS ship_gender,
        cd_refunded.cd_gender AS refunded_gender,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_return_loss,
        AVG(cs.cs_quantity) AS avg_quantity
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_sold.d_date_sk
    JOIN customer_demographics cd_refunded
        ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2022
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_sold.d_year,
        d_sold.d_month_seq,
        cd_bill.cd_gender,
        cd_ship.cd_gender,
        cd_refunded.cd_gender
)
SELECT
    s_store_id,
    s_store_name,
    d_year,
    d_month_seq,
    bill_gender,
    ship_gender,
    refunded_gender,
    total_orders,
    total_net_paid,
    total_net_profit,
    total_return_amount,
    total_return_loss,
    avg_quantity,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_net_paid DESC) AS sales_rank_by_store
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
