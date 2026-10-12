WITH item_stats AS (
    SELECT
        i.i_category,
        AVG(i.i_current_price) AS avg_price,
        SUM(i.i_wholesale_cost) AS total_wholesale_cost,
        COUNT(*) AS item_cnt
    FROM
        item i
    WHERE
        i.i_current_price > 5
    GROUP BY
        i.i_category
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    hd.hd_buy_potential,
    COUNT(*) AS num_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_est,
    SUM(cd.cd_purchase_estimate) AS total_purchase_est,
    item_stats.avg_price,
    item_stats.item_cnt,
    RANK() OVER (ORDER BY SUM(cd.cd_purchase_estimate) DESC) AS purchase_rank
FROM
    customer_demographics cd
JOIN
    household_demographics hd
        ON cd.cd_dep_count = hd.hd_dep_count
LEFT JOIN
    item_stats
        ON hd.hd_buy_potential = item_stats.i_category
WHERE
    cd.cd_credit_rating IN ('Good', 'Low Risk')
    AND cd.cd_education_status = 'College'
    AND hd.hd_vehicle_count >= 2
GROUP BY
    cd.cd_gender,
    cd.cd_marital_status,
    hd.hd_buy_potential,
    item_stats.avg_price,
    item_stats.item_cnt
HAVING
    COUNT(*) > 5
ORDER BY
    total_purchase_est DESC
LIMIT 100
