WITH aggregated AS (
    SELECT
        d.d_date,
        d.d_year,
        cc.cc_name,
        cc.cc_division_name,
        s.s_store_name,
        s.s_state,
        SUM(i.inv_quantity_on_hand) AS total_qty_on_hand,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers
    FROM
        date_dim d
        JOIN inventory i ON i.inv_date_sk = d.d_date_sk
        JOIN store s ON s.s_closed_date_sk = d.d_date_sk
        JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
        JOIN customer c ON c.c_first_shipto_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2000 AND 2022
    GROUP BY
        d.d_date,
        d.d_year,
        cc.cc_name,
        cc.cc_division_name,
        s.s_store_name,
        s.s_state
)
SELECT
    a.d_date,
    a.cc_name,
    a.cc_division_name,
    a.s_store_name,
    a.s_state,
    a.total_qty_on_hand,
    a.distinct_customers,
    ROW_NUMBER() OVER (ORDER BY a.total_qty_on_hand DESC) AS rank_by_qty
FROM
    aggregated a
ORDER BY
    rank_by_qty
LIMIT 10
