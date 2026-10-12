WITH total_inventory AS (
    SELECT SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
)
SELECT
    r_reason_desc,
    return_count,
    total_return_amount,
    total_net_loss,
    avg_return_amount,
    preferred_customer_returns,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank,
    total_inventory_quantity
FROM (
    SELECT
        r.r_reason_desc,
        COUNT(*) AS return_count,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt) AS avg_return_amount,
        SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_customer_returns,
        ti.total_qty AS total_inventory_quantity
    FROM web_returns wr
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    CROSS JOIN total_inventory ti
    WHERE c.c_birth_country = 'MEXICO' AND c.c_preferred_cust_flag = 'Y'
    GROUP BY r.r_reason_desc, ti.total_qty
    HAVING SUM(wr.wr_return_amt) > 1000
) sub
ORDER BY net_loss_rank
LIMIT 50
