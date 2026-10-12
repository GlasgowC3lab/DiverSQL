SELECT
    cc.cc_name,
    cc.cc_state,
    COUNT(DISTINCT inv_sub.d_date) AS days_with_inventory,
    SUM(inv_sub.inv_quantity_on_hand) AS total_quantity,
    AVG(inv_sub.inv_quantity_on_hand) AS avg_daily_quantity,
    RANK() OVER (ORDER BY AVG(inv_sub.inv_quantity_on_hand) DESC) AS rank_by_avg_qty
FROM
    call_center cc
    JOIN date_dim od ON cc.cc_open_date_sk = od.d_date_sk
    JOIN (
        SELECT iv.inv_quantity_on_hand, id.d_date
        FROM inventory iv
        JOIN date_dim id ON iv.inv_date_sk = id.d_date_sk
    ) AS inv_sub
        ON inv_sub.d_date >= od.d_date
        AND inv_sub.d_date < od.d_date + INTERVAL '90' DAY
WHERE
    cc.cc_class = 'large'
    AND cc.cc_state IN ('TN', 'GA')
GROUP BY
    cc.cc_name,
    cc.cc_state
HAVING
    COUNT(DISTINCT inv_sub.d_date) >= 30
ORDER BY
    avg_daily_quantity DESC
LIMIT 5
