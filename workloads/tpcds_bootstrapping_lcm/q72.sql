WITH returns_summary AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name AS call_center_name,
        cc.cc_city AS call_center_city,
        cc.cc_state AS call_center_state,
        dd_closed.d_year AS closed_year,
        dd_open.d_year AS open_year,
        s.s_store_id,
        s.s_store_name AS store_name,
        s.s_city AS store_city,
        s.s_state AS store_state,
        s.s_floor_space,
        COUNT(*) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT ra.ca_address_id) AS distinct_refunded_address,
        COUNT(DISTINCT rca.ca_address_id) AS distinct_returning_address
    FROM call_center cc
    JOIN date_dim dd_closed ON cc.cc_closed_date_sk = dd_closed.d_date_sk
    JOIN date_dim dd_open ON cc.cc_open_date_sk = dd_open.d_date_sk
    JOIN store s ON s.s_closed_date_sk = dd_closed.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = dd_closed.d_date_sk
    JOIN customer_address ra ON wr.wr_refunded_addr_sk = ra.ca_address_sk
    JOIN customer_address rca ON wr.wr_returning_addr_sk = rca.ca_address_sk
    WHERE dd_closed.d_year BETWEEN 2000 AND 2005
      AND s.s_state = 'CA'
      AND cc.cc_state = 'CA'
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        dd_closed.d_year,
        dd_open.d_year,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_floor_space
)
SELECT
    t.call_center_name,
    t.call_center_city,
    t.call_center_state,
    t.store_name,
    t.store_city,
    t.store_state,
    t.closed_year,
    t.open_year,
    t.s_floor_space,
    t.num_returns,
    t.total_return_amount,
    t.total_net_loss,
    t.avg_return_qty,
    t.distinct_refunded_address,
    t.distinct_returning_address,
    CASE WHEN t.total_return_amount = 0 THEN NULL
         ELSE ROUND(t.total_net_loss / t.total_return_amount, 4) END AS loss_to_return_ratio,
    t.rn
FROM (
    SELECT
        rs.*,
        ROW_NUMBER() OVER (PARTITION BY rs.cc_call_center_id ORDER BY rs.total_net_loss DESC) AS rn
    FROM returns_summary rs
) t
WHERE t.rn <= 5
ORDER BY t.call_center_name, t.total_net_loss DESC
LIMIT 100
