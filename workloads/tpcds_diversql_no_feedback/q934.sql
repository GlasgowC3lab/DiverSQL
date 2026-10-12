WITH catalog_profit AS (
    SELECT
        'catalog' AS source,
        td.t_hour AS hour,
        SUM(cs.cs_net_profit) AS total_amount
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
      AND td.t_am_pm = 'PM'
    GROUP BY td.t_hour
    HAVING SUM(cs.cs_net_profit) > 1000
),
store_loss AS (
    SELECT
        'store_return' AS source,
        td.t_hour AS hour,
        SUM(sr.sr_net_loss) AS total_amount
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_gmt_offset = -5.00
      AND td.t_am_pm = 'PM'
    GROUP BY td.t_hour
    HAVING SUM(sr.sr_net_loss) > 500
)
SELECT source, hour, total_amount
FROM catalog_profit
UNION ALL
SELECT source, hour, total_amount
FROM store_loss
ORDER BY source, hour DESC
LIMIT 100
