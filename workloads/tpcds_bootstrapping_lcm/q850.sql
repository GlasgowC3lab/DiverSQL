SELECT
    agg.s_store_id,
    agg.s_store_name,
    agg.d_year,
    agg.d_month_seq,
    agg.total_sales,
    agg.total_discount,
    agg.total_net_profit,
    agg.total_quantity,
    agg.avg_ship_lead_days,
    agg.distinct_orders,
    agg.total_store_return_loss,
    agg.total_web_return_loss,
    agg.distinct_store_returns,
    agg.distinct_web_returns,
    AVG(agg.total_sales) OVER (
        PARTITION BY agg.s_store_id
        ORDER BY agg.d_year, agg.d_month_seq
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_sales_3months
FROM (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_sold.d_year,
        d_sold.d_month_seq,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_ship_lead_days,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_store_return_loss,
        COALESCE(SUM(wr.wr_net_loss), 0) AS total_web_return_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_store_returns,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_web_returns
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d_sold.d_date_sk
        AND sr.sr_store_sk = s.s_store_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year BETWEEN 2020 AND 2022
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_sold.d_year,
        d_sold.d_month_seq
) agg
WHERE agg.total_sales > 1000
ORDER BY agg.total_sales DESC
LIMIT 100
