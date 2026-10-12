WITH store_closures AS (
    SELECT
        d_closed.d_date_sk,
        d_closed.d_date,
        d_closed.d_year,
        d_closed.d_moy,
        COUNT(*) AS num_stores_closed,
        SUM(s.s_floor_space) AS total_floor_space,
        AVG(s.s_number_employees) AS avg_employees
    FROM store s
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    GROUP BY d_closed.d_date_sk, d_closed.d_date, d_closed.d_year, d_closed.d_moy
),
returns_by_date AS (
    SELECT
        d_ret.d_date_sk,
        d_ret.d_date,
        d_ret.d_year,
        d_ret.d_moy,
        r.r_reason_desc,
        ca_ret.ca_state AS returning_state,
        ca_ref.ca_state AS refunded_state,
        COUNT(DISTINCT wr.wr_order_number) AS num_orders,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        AVG(wr.wr_return_quantity) AS avg_return_qty
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_ret ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN customer_address ca_ref ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    GROUP BY d_ret.d_date_sk, d_ret.d_date, d_ret.d_year, d_ret.d_moy, r.r_reason_desc, ca_ret.ca_state, ca_ref.ca_state
)
SELECT
    rbd.d_year,
    rbd.d_moy,
    rbd.r_reason_desc,
    rbd.returning_state,
    rbd.refunded_state,
    rbd.num_orders,
    rbd.total_return_amt,
    rbd.total_net_loss,
    rbd.total_return_qty,
    rbd.avg_return_qty,
    COALESCE(sc.num_stores_closed, 0) AS stores_closed_on_date,
    COALESCE(sc.total_floor_space, 0) AS total_floor_space_closed
FROM returns_by_date rbd
LEFT JOIN store_closures sc ON rbd.d_date_sk = sc.d_date_sk
WHERE rbd.total_return_amt > 500
ORDER BY rbd.total_return_amt DESC
LIMIT 200
