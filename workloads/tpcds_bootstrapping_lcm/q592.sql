WITH returns_agg AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_order_number,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS num_return_rows,
        AVG(t_return.t_hour) AS avg_return_hour
    FROM web_returns wr
    JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN time_dim t_return ON wr.wr_returned_time_sk = t_return.t_time_sk
    GROUP BY wr.wr_item_sk, wr.wr_order_number
),
sales_agg AS (
    SELECT
        d_sold.d_year,
        d_sold.d_month_seq,
        st.s_store_id,
        st.s_store_name,
        st.s_city,
        st.s_state,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        COALESCE(SUM(ra.total_return_amount), 0) AS total_return_amount,
        COALESCE(SUM(ra.total_return_loss), 0) AS total_return_loss,
        COALESCE(SUM(ra.num_return_rows), 0) AS num_returns,
        AVG(t_sold.t_hour) AS avg_sale_hour,
        AVG(ra.avg_return_hour) AS avg_return_hour
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN store st ON st.s_closed_date_sk = d_ship.d_date_sk
    LEFT JOIN returns_agg ra
        ON ra.wr_item_sk = ws.ws_item_sk
        AND ra.wr_order_number = ws.ws_order_number
    GROUP BY
        d_sold.d_year,
        d_sold.d_month_seq,
        st.s_store_id,
        st.s_store_name,
        st.s_city,
        st.s_state
)
SELECT
    d_year,
    d_month_seq,
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    total_sales,
    total_net_profit,
    total_discount,
    num_orders,
    total_return_amount,
    total_return_loss,
    num_returns,
    avg_sale_hour,
    avg_return_hour,
    RANK() OVER (
        PARTITION BY d_year, d_month_seq
        ORDER BY (total_net_profit - total_return_loss) DESC
    ) AS profit_rank
FROM sales_agg
ORDER BY d_year DESC, d_month_seq DESC, profit_rank
LIMIT 100
