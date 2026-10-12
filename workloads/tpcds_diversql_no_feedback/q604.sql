WITH returns_agg AS (
    SELECT
        ca.ca_state AS state,
        CAST('ReturnAmt' AS varchar) AS metric_type,
        CAST(SUM(sr.sr_return_amt) AS decimal(15,2)) AS total_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY ca.ca_state
    HAVING SUM(sr.sr_return_amt) > 1000
),
inventory_agg AS (
    SELECT
        ws.web_state AS state,
        CAST('InvQty' AS varchar) AS metric_type,
        CAST(SUM(i.inv_quantity_on_hand) AS decimal(15,2)) AS total_amount
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws.web_state
    HAVING SUM(i.inv_quantity_on_hand) > 2000
)
SELECT state, metric_type, total_amount
FROM returns_agg
UNION ALL
SELECT state, metric_type, total_amount
FROM inventory_agg
ORDER BY state, metric_type
LIMIT 100
