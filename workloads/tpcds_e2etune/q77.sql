WITH store_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_tax_percentage,
        s.s_geography_class,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_quantity) AS avg_return_qty,
        SUM(sr.sr_fee) AS total_fee,
        MAX(sr.sr_returned_date_sk) AS last_return_date_sk
    FROM store s
    JOIN store_returns sr ON s.s_store_sk = sr.sr_store_sk
    WHERE s.s_tax_percentage > 0.05
      AND s.s_closed_date_sk BETWEEN 2451044 AND 2451267
      AND sr.sr_return_quantity > 0
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_tax_percentage,
        s.s_geography_class
    HAVING COUNT(sr.sr_ticket_number) >= 10
)
SELECT
    s_store_sk,
    s_store_name,
    s_city,
    s_state,
    s_geography_class,
    s_tax_percentage,
    total_returns,
    total_return_amount,
    total_net_loss,
    avg_return_qty,
    total_fee,
    RANK() OVER (PARTITION BY s_geography_class ORDER BY total_net_loss DESC) AS rank_within_geo,
    NTILE(4) OVER (ORDER BY total_return_amount) AS return_amount_quartile,
    CASE
        WHEN total_net_loss > 10000 THEN 'High'
        WHEN total_net_loss > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS net_loss_category
FROM store_agg
WHERE total_return_amount > 0
ORDER BY total_net_loss DESC, s_store_sk
LIMIT 200
