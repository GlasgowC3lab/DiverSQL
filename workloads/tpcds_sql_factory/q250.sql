SELECT
    i.i_manufact,
    i.i_item_id,
    i.i_product_name,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    CASE
        WHEN SUM(ss.ss_quantity) = 0 THEN NULL
        ELSE SUM(ss.ss_net_profit) / SUM(ss.ss_quantity)
    END AS profit_per_unit,
    RANK() OVER (PARTITION BY i.i_manufact ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank_within_manufact,
    SUM(SUM(ss.ss_net_profit)) OVER (
        PARTITION BY i.i_manufact
        ORDER BY i.i_item_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit_by_manufact
FROM store_sales ss
INNER JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
INNER JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
INNER JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
WHERE cd.cd_credit_rating = 'Excellent'
GROUP BY i.i_manufact, i.i_item_id, i.i_product_name
HAVING SUM(ss.ss_quantity) > 10
ORDER BY i.i_manufact, profit_rank_within_manufact
LIMIT 100
