WITH returns_summary AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month_seq,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        p.p_promo_name,
        p.p_cost,
        s.s_store_name,
        s.s_state,
        d_store.d_year AS store_closed_year,
        d_cust_ship.d_year AS cust_ship_year
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN promotion p ON p.p_start_date_sk = d_ret.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
    JOIN date_dim d_cust_ship ON c.c_first_shipto_date_sk = d_cust_ship.d_date_sk
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d_ret.d_year,
        d_ret.d_month_seq,
        p.p_promo_name,
        p.p_cost,
        s.s_store_name,
        s.s_state,
        d_store.d_year,
        d_cust_ship.d_year
)
SELECT
    rs.c_customer_id,
    rs.c_first_name,
    rs.c_last_name,
    rs.return_year,
    rs.return_month_seq,
    rs.total_return_amount,
    rs.total_net_loss,
    rs.distinct_orders,
    rs.p_promo_name,
    rs.p_cost,
    rs.s_store_name,
    rs.s_state,
    rs.store_closed_year,
    rs.cust_ship_year,
    ROW_NUMBER() OVER (ORDER BY rs.total_net_loss DESC) AS net_loss_rank
FROM returns_summary rs
ORDER BY rs.total_net_loss DESC
LIMIT 100
