WITH sales_by_demo_date AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        d_sold.d_date_sk,
        d_sold.d_year,
        d_sold.d_month_seq,
        SUM(cs.cs_net_paid)      AS total_sales,
        SUM(cs.cs_net_profit)    AS total_profit,
        SUM(cs.cs_quantity)      AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        d_sold.d_date_sk,
        d_sold.d_year,
        d_sold.d_month_seq
),

returns_by_demo_date AS (
    SELECT
        cd.cd_demo_sk,
        d_ret.d_date_sk,
        d_ret.d_year,
        d_ret.d_month_seq,
        SUM(wr.wr_return_amt)    AS total_returns,
        SUM(wr.wr_net_loss)      AS total_net_loss,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_demo_sk,
        d_ret.d_date_sk,
        d_ret.d_year,
        d_ret.d_month_seq
),

store_closures_by_date AS (
    SELECT
        d_closure.d_date_sk,
        d_closure.d_year,
        d_closure.d_month_seq,
        COUNT(s.s_store_sk)    AS closed_store_count,
        SUM(s.s_floor_space)   AS total_floor_space
    FROM store s
    JOIN date_dim d_closure
        ON s.s_closed_date_sk = d_closure.d_date_sk
    GROUP BY
        d_closure.d_date_sk,
        d_closure.d_year,
        d_closure.d_month_seq
)

SELECT
    sbd.d_year,
    sbd.d_month_seq,
    sbd.cd_gender,
    sbd.cd_marital_status,
    sbd.total_sales,
    sbd.total_profit,
    sbd.total_quantity,
    COALESCE(rbd.total_returns, 0)     AS total_returns,
    COALESCE(rbd.total_net_loss, 0)   AS total_net_loss,
    COALESCE(rbd.total_return_qty, 0) AS total_return_qty,
    COALESCE(sc.closed_store_count, 0) AS closed_store_count,
    COALESCE(sc.total_floor_space, 0)  AS total_floor_space
FROM sales_by_demo_date sbd
LEFT JOIN returns_by_demo_date rbd
    ON sbd.cd_demo_sk = rbd.cd_demo_sk
   AND sbd.d_date_sk = rbd.d_date_sk
LEFT JOIN store_closures_by_date sc
    ON sbd.d_date_sk = sc.d_date_sk
WHERE sbd.d_year = 2020
ORDER BY sbd.total_sales DESC
LIMIT 100
