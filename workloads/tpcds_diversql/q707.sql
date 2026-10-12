WITH sr_sample AS (
    SELECT *
    FROM store_returns TABLESAMPLE BERNOULLI (10)
    WHERE sr_reason_sk IN (
        SELECT r_reason_sk
        FROM reason
        WHERE r_reason_desc LIKE 'Customer%'
    )
),
agg AS (
    SELECT
        d_ret.d_year,
        i.i_item_id,
        i.i_brand,
        w.w_warehouse_sq_ft,
        COUNT(DISTINCT sr_sample.sr_ticket_number) AS distinct_tickets,
        SUM(DISTINCT sr_sample.sr_return_amt) AS distinct_return_amount,
        SUM(sr_sample.sr_return_amt) AS total_return,
        CASE WHEN w.w_warehouse_sq_ft > 200000 THEN 'Large' ELSE 'Medium' END AS warehouse_size_category
    FROM sr_sample sr_sample
    JOIN date_dim d_ret ON sr_sample.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t ON sr_sample.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr_sample.sr_item_sk = i.i_item_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk AND d_ret.d_date_sk = inv.inv_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca ON sr_sample.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr_sample.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr_sample.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON sr_sample.sr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d_ret.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_ret.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_ret.d_date_sk
    WHERE
        d_ret.d_year = 2001
        AND i.i_units IN ('Gross', 'Bunch')
        AND w.w_warehouse_sq_ft > 100000
        AND t.t_hour BETWEEN 8 AND 17
    GROUP BY
        d_ret.d_year,
        i.i_item_id,
        i.i_brand,
        w.w_warehouse_sq_ft
)
SELECT
    d_year,
    i_item_id,
    i_brand,
    distinct_tickets,
    distinct_return_amount,
    total_return,
    warehouse_size_category,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return DESC) AS revenue_rank
FROM agg
ORDER BY total_return DESC
OFFSET 20 ROWS
LIMIT 100
