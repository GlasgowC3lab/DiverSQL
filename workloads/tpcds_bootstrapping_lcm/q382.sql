SELECT 
    a.d_year,
    a.d_month_seq,
    a.s_state,
    a.i_brand,
    a.i_category,
    a.num_returns,
    a.total_return_amount,
    a.total_net_loss,
    a.avg_return_quantity,
    a.distinct_items_returned,
    a.avg_item_wholesale_cost,
    a.total_tax,
    a.avg_return_ship_cost,
    ROW_NUMBER() OVER (PARTITION BY a.d_year, a.s_state ORDER BY a.total_return_amount DESC) AS brand_state_year_rank,
    CASE 
        WHEN a.total_return_amount > 50000 THEN 'HIGH'
        WHEN a.total_return_amount > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_amount_category,
    SUM(a.total_return_amount) OVER (PARTITION BY a.d_year ORDER BY a.d_month_seq 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_year_return_amount
FROM (
    SELECT 
        d.d_year,
        d.d_month_seq,
        s.s_state,
        i.i_brand,
        i.i_category,
        COUNT(*) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_quantity,
        COUNT(DISTINCT i.i_item_id) AS distinct_items_returned,
        AVG(i.i_wholesale_cost) AS avg_item_wholesale_cost,
        SUM(wr.wr_return_tax) AS total_tax,
        AVG(wr.wr_return_ship_cost) AS avg_return_ship_cost
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year >= 2020
    GROUP BY 
        d.d_year,
        d.d_month_seq,
        s.s_state,
        i.i_brand,
        i.i_category
    HAVING COUNT(*) > 10
) a
ORDER BY a.total_return_amount DESC
LIMIT 200
