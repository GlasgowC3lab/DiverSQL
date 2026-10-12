WITH sales_data AS (
    SELECT
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_ship_mode_sk,
        sm.sm_type,
        sm.sm_carrier,
        sold.d_year AS sold_year,
        ship.d_year AS ship_year,
        wr.wr_net_loss,
        st.s_state,
        st.s_closed_date_sk,
        closed.d_year AS closed_year
    FROM catalog_sales cs
    JOIN date_dim sold ON cs.cs_sold_date_sk = sold.d_date_sk
    JOIN date_dim ship ON cs.cs_ship_date_sk = ship.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = sold.d_date_sk
    JOIN store st ON st.s_closed_date_sk = sold.d_date_sk
    JOIN date_dim closed ON st.s_closed_date_sk = closed.d_date_sk
    WHERE cs.cs_net_profit > 0
),
agg AS (
    SELECT
        sold_year,
        sm_type,
        s_state,
        SUM(cs_net_profit) AS total_profit,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_quantity) AS total_quantity,
        SUM(COALESCE(wr_net_loss, 0)) AS total_return_loss
    FROM sales_data
    GROUP BY sold_year, sm_type, s_state
    HAVING SUM(cs_net_profit) > 1000
)
SELECT
    sold_year,
    sm_type,
    s_state,
    total_profit,
    total_sales,
    total_quantity,
    total_return_loss,
    ROUND(total_return_loss / NULLIF(total_profit, 0) * 100, 2) AS loss_percent,
    ROW_NUMBER() OVER (PARTITION BY sold_year ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY sold_year DESC, total_profit DESC
LIMIT 100
